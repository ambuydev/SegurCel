package com.segurcel.segurcel

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log

class SmsReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "SegurCelSMS"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            try {
                val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
                for (sms in messages) {
                    val body = sms.messageBody ?: continue
                    Log.i(TAG, "SMS Recibido: $body")

                    if (body.contains("#SIRENA_SEGURCEL", ignoreCase = true) ||
                        body.contains("#ALARMA", ignoreCase = true) ||
                        body.contains("SIRENA_START", ignoreCase = true)) {

                        Log.i(TAG, "¡Código secreto de sirena detectado en SMS! Disparando alarma offline...")
                        SegurCelFirebaseMessagingService.acquireWakeLock(context)
                        SirenFlashHelper.startAlarmAndFlash(context)

                        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                        if (launchIntent != null) {
                            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                            context.startActivity(launchIntent)
                        }
                        break
                    } else if (body.contains("#DETENER_SIRENA", ignoreCase = true) ||
                               body.contains("#PARAR_ALARMA", ignoreCase = true) ||
                               body.contains("SIRENA_STOP", ignoreCase = true)) {

                        Log.i(TAG, "¡Código de detención de sirena detectado en SMS! Deteniendo alarma...")
                        SirenFlashHelper.stopAlarmAndFlash(context)
                        break
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error procesando SMS nativo: ${e.message}")
            }
        }
    }
}
