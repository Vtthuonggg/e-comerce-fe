package com.nylo.android

import android.speech.tts.TextToSpeech
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.batecinema.app/textToSpeech"
    private var textToSpeech: TextToSpeech? = null
    private var isTtsReady = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Khởi tạo TTS
        textToSpeech =
                TextToSpeech(this) { status ->
                    if (status == TextToSpeech.SUCCESS) {
                        val result = textToSpeech?.setLanguage(Locale("vi", "VN"))
                        if (result == TextToSpeech.LANG_MISSING_DATA ||
                                        result == TextToSpeech.LANG_NOT_SUPPORTED
                        ) {
                            Log.e("TTS", "Vietnamese language not supported, using default")
                            textToSpeech?.language = Locale.getDefault()
                        }
                        isTtsReady = true
                        Log.d("TTS", "TextToSpeech initialized successfully")
                    } else {
                        Log.e("TTS", "TextToSpeech initialization failed")
                    }
                }

        // Setup MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            when (call.method) {
                "speak" -> {
                    val text = call.argument<String>("text")
                    if (text != null) {
                        if (isTtsReady) {
                            speak(text)
                            result.success(null)
                        } else {
                            result.error("TTS_NOT_READY", "TextToSpeech not initialized", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Text is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun speak(text: String) {
        if (text.isEmpty()) return

        textToSpeech?.let { tts ->
            // Dừng nếu đang nói
            if (tts.isSpeaking) {
                tts.stop()
            }

            // Bắt đầu nói
            tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, text.hashCode().toString())
            Log.d("TTS", "Speaking: $text")
        }
    }

    override fun onDestroy() {
        textToSpeech?.let { tts ->
            tts.stop()
            tts.shutdown()
        }
        super.onDestroy()
    }
}
