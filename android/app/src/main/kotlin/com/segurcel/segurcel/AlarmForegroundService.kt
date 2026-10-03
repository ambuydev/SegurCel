package com.segurcel.segurcel

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class AlarmForegroundService : Service() {
    companion object {
        const val CHANNEL_ID = "segurcel_alarm_service_channel"
        const val NOTIFICATION_ID = 9005

        fun startAlarmService(context: Context) {
            val intent = Intent(context, AlarmForegroundService::class.java)
            intent.action = "START_ALARM"
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stopAlarmService(context: Context) {
            val intent = Intent(context, AlarmForegroundService::class.java)
            intent.action = "STOP_ALARM"
            context.stopService(intent)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action

        if (action == "START_ALARM") {
            val notificationIntent = Intent(this, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                notificationIntent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )

            val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("🚨 ¡SIRENA ANTIRROBO ACTIVADA!")
                .setContentText("Reproduciendo sirena policial a máximo volumen")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .build()

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }

            SegurCelFirebaseMessagingService.acquireWakeLock(applicationContext)
            SirenFlashHelper.startAlarmAndFlash(applicationContext)
        } else if (action == "STOP_ALARM") {
            SirenFlashHelper.stopAlarmAndFlash(applicationContext)
            @Suppress("DEPRECATION")
            stopForeground(true)
            stopSelf()
        }

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "SegurCel Alarma Servicio",
                NotificationManager.IMPORTANCE_HIGH
            )
            channel.description = "Servicio de reproducción de sirena de alarma a máximo volumen"
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }
}
