package com.segurcel.segurcel

import android.content.Context
import android.os.PowerManager
import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class SegurCelFirebaseMessagingService : FirebaseMessagingService() {
    companion object {
        private const val TAG = "SegurCelFCM"

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
        } else if (cmd == "stop_alarm") {
            SirenFlashHelper.stopAlarmAndFlash(applicationContext)
        }
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        val prefs = getSharedPreferences("segurcel_prefs", Context.MODE_PRIVATE)
        prefs.edit().putString("fcm_token", token).apply()
    }
}
