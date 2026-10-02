package com.segurcel.segurcel

import android.content.Context
import android.hardware.camera2.CameraManager
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Handler
import android.os.Looper
import android.util.Log

object SirenFlashHelper {
    private const val TAG = "SirenFlashHelper"
    private var mediaPlayer: MediaPlayer? = null
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

            // 2. Reproduce el archivo de audio nativo de Sirena Policial
            if (mediaPlayer == null) {
                mediaPlayer = MediaPlayer.create(context.applicationContext, R.raw.siren_police)
                mediaPlayer?.isLooping = true
                mediaPlayer?.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            }

            if (mediaPlayer?.isPlaying == false) {
                mediaPlayer?.start()
            }

            // 3. Inicia parpadeo estroboscópico de linterna LED
            startStrobeFlash(context)

            Log.i(TAG, "¡Sirena Policial y Flash LED activados a máximo volumen!")
        } catch (e: Exception) {
            Log.e(TAG, "Error activando sirena policial: ${e.message}")
        }
    }

    fun stopAlarmAndFlash(context: Context) {
        try {
            // 1. Detiene la sirena policial
            if (mediaPlayer?.isPlaying == true) {
                mediaPlayer?.stop()
            }
            mediaPlayer?.release()
            mediaPlayer = null

            // 2. Detiene el parpadeo de linterna LED
            stopStrobeFlash(context)

            Log.i(TAG, "Sirena Policial y Flash LED desactivados")
        } catch (e: Exception) {
            Log.e(TAG, "Error desactivando sirena policial: ${e.message}")
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
                flashHandler?.postDelayed(this, 200)
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
