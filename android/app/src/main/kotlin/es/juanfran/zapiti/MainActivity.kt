package es.juanfran.zapiti

import android.media.MediaPlayer
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "zapiti/music"
    private var mediaPlayer: MediaPlayer? = null
    private var currentAsset: String? = null
    private var currentVolume: Float = 0.65f

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "play" -> {
                            val asset = call.argument<String>("asset")
                            val volume = call.argument<Double>("volume") ?: 0.65
                            if (asset != null) {
                                play(asset, volume.toFloat())
                            }
                            result.success(null)
                        }
                        "setVolume" -> {
                            val volume = call.argument<Double>("volume") ?: 0.65
                            setVolume(volume.toFloat())
                            result.success(null)
                        }
                        "stop" -> {
                            stop()
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("audio_error", error.message, null)
                }
            }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        stop()
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun play(asset: String, volume: Float) {
        val clampedVolume = volume.coerceIn(0f, 1f)
        currentVolume = clampedVolume

        if (currentAsset == asset && mediaPlayer != null) {
            setVolume(clampedVolume)
            mediaPlayer?.start()
            return
        }

        stop()

        val assetFile = cachedAudioFile(asset)
        mediaPlayer = MediaPlayer().apply {
            setDataSource(assetFile.absolutePath)
            isLooping = true
            setVolume(clampedVolume, clampedVolume)
            prepare()
            start()
        }
        currentAsset = asset
    }

    private fun cachedAudioFile(asset: String): File {
        val assetKey =
            FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(asset)
        val fileName = asset.substringAfterLast('/')
        val cacheFile = File(cacheDir, "zapiti_$fileName")
        if (cacheFile.exists() && cacheFile.length() > 0) {
            return cacheFile
        }

        assets.open(assetKey).use { input ->
            FileOutputStream(cacheFile).use { output ->
                input.copyTo(output)
            }
        }
        return cacheFile
    }

    private fun setVolume(volume: Float) {
        currentVolume = volume.coerceIn(0f, 1f)
        mediaPlayer?.setVolume(currentVolume, currentVolume)
    }

    private fun stop() {
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
        currentAsset = null
    }
}
