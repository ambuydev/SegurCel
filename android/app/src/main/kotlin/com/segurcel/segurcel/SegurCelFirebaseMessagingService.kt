package com.segurcel.segurcel

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class SegurCelFirebaseMessagingService : FirebaseMessagingService() {
    companion object {
        private const val TAG = "SegurCelFCM"
        const val ALARM_CHANNEL_ID = "segurcel_alarm_channel"

        fun acquireWakeLock(context: Context) {
            try {
                val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                @Suppress("DEPRECATION")
                val wakeLock = pm.newWakeLock(
                    PowerManager.FULL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP or PowerManager.ON_AFTER_RELEASE,
                    "SegurCel:AlarmWakeLock"
                )
                wakeLock.acquire(10000)
            } catch (_: Exception) {}
        }
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        Log.i(TAG, "Mensaje Push FCM de Alta Prioridad recibido en Kotlin: ${remoteMessage.data}")

        val cmd = remoteMessage.data["command"] ?: remoteMessage.data["pendingCommand"]

        if (cmd == "start_alarm") {
            acquireWakeLock(applicationContext)
            SirenFlashHelper.startAlarmAndFlash(applicationContext)
            showFullScreenNotification(applicationContext)
        } else if (cmd == "stop_alarm") {
            SirenFlashHelper.stopAlarmAndFlash(applicationContext)
        }
    }

    private fun showFullScreenNotification(context: Context) {
        try {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    ALARM_CHANNEL_ID,
                    "SegurCel Alarma Remota",
                    NotificationManager.IMPORTANCE_HIGH
                )
                channel.description = "Canal de alta prioridad para disparo de sirena en pantalla de bloqueo"
                notificationManager.createNotificationChannel(channel)
            }

            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: Intent(context, MainActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)

            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )

            val notification = NotificationCompat.Builder(context, ALARM_CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("🚨 ¡SIRENA ANTIRROBO ACTIVADA!")
                .setContentText("Disparo remoto de alarma policial desde la Web SegurCel")
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setFullScreenIntent(pendingIntent, true)
                .setAutoCancel(true)
                .build()

            notificationManager.notify(9002, notification)
        } catch (e: Exception) {
            Log.e(TAG, "Error mostrando notificacion FullScreen: ${e.message}")
        }
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        val prefs = getSharedPreferences("segurcel_prefs", Context.MODE_PRIVATE)
        prefs.edit().putString("fcm_token", token).apply()
    }
}
