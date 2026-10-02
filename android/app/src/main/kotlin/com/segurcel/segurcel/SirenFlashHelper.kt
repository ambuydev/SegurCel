package com.segurcel.segurcel

import android.content.Context
import android.hardware.camera2.CameraManager
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log

object SirenFlashHelper {
    private const val TAG = "SirenFlashHelper"
    private var alarmRingtone: Ringtone? = null
    private var isFlashing = false
    private var flashHandler: Handler? = null
    private var flashRunnable: Runnable? = null
    private var flashState = false

    fun startAlarmAndFlash(context: Context) {
        try {
            // 1. Eleva el volumen multimedia al 100% MÁXIMO
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, maxVolume, 0)

            // 2. Reproduce sonido de sirena de alarma
            val alarmUri: Uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)

            if (alarmRingtone == null) {
                alarmRingtone = RingtoneManager.getRingtone(context.applicationContext, alarmUri)
                alarmRingtone?.audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            }

            if (alarmRingtone?.isPlaying == false) {
                alarmRingtone?.play()
            }

            // 3. Inicia parpadeo estroboscópico de linterna LED
            startStrobeFlash(context)

            Log.i(TAG, "¡Sirena de Alarma y Flash LED activados a máximo volumen!")
        } catch (e: Exception) {
            Log.e(TAG, "Error activando sirena y flash: ${e.message}")
        }
    }

    fun stopAlarmAndFlash(context: Context) {
        try {
            // 1. Detiene la sirena de alarma
            if (alarmRingtone?.isPlaying == true) {
                alarmRingtone?.stop()
            }

            // 2. Detiene el parpadeo de linterna LED
            stopStrobeFlash(context)

            Log.i(TAG, "Sirena de Alarma y Flash LED desactivados")
        } catch (e: Exception) {
            Log.e(TAG, "Error desactivando sirena y flash: ${e.message}")
        }
    }

    private fun startStrobeFlash(context: Context) {
        if (isFlashing) return
        isFlashing = true

        val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as? CameraManager
        val cameraId = cameraManager?.cameraIdList?.getOrNull(0) ?: return

        flashHandler = Handler(Looper.getMainLooper())
        flashRunnable = object : Runnable {
            override fun run() {
                if (!isFlashing) return
                try {
                    flashState = !flashState
                    cameraManager.setTorchMode(cameraId, flashState)
                } catch (_: Exception) {}
                flashHandler?.postDelayed(this, 200) // Parpadeo cada 200 milisegundos
            }
        }
        flashHandler?.post(flashRunnable as Runnable)
    }

    private fun stopStrobeFlash(context: Context) {
        isFlashing = false
        flashHandler?.removeCallbacksAndMessages(null)

        try {
            val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as? CameraManager
            val cameraId = cameraManager?.cameraIdList?.getOrNull(0) ?: return
            cameraManager.setTorchMode(cameraId, false)
        } catch (_: Exception) {}
    }
}
