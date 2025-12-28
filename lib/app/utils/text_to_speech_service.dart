import 'dart:async';
import 'dart:developer';
import 'package:flutter/services.dart';

class TextToSpeechService {
  static const MethodChannel _channel =
      MethodChannel('com.batecinema.app/textToSpeech');
  static const int MAX_RETRY = 3;

  static Future<void> speak(String text, {int retryCount = 0}) async {
    try {
      await _channel.invokeMethod('speak', {'text': text});
      log('✅ Speaking: $text');
    } on PlatformException catch (e) {
      if (e.code == 'TTS_NOT_READY' && retryCount < MAX_RETRY) {
        // TTS chưa sẵn sàng, đợi và thử lại
        log('⏳ TTS not ready, retrying... (${retryCount + 1}/$MAX_RETRY)');
        await Future.delayed(Duration(milliseconds: 500));
        return speak(text, retryCount: retryCount + 1);
      } else {
        log("❌ Failed to speak: '${e.code}': '${e.message}'");
      }
    } catch (e) {
      log("❌ Unexpected error: $e");
    }
  }

  /// Kiểm tra TTS có sẵn sàng không
  static Future<bool> isReady() async {
    try {
      // Thử speak một chuỗi rỗng để test
      await _channel.invokeMethod('speak', {'text': ''});
      return true;
    } catch (e) {
      return false;
    }
  }
}
