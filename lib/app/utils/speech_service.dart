import 'dart:async';
import 'dart:developer';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  SpeechToText? _speechToText;
  bool _speechEnabled = false;
  String _lastWords = '';
  bool _isDisposed = false;

  StreamController<String>? _transcriptController;
  StreamController<bool>? _listeningController;
  StreamController<String>? _errorController;

  Stream<String> get transcriptStream {
    _transcriptController ??= StreamController<String>.broadcast();
    return _transcriptController!.stream;
  }

  Stream<bool> get listeningStream {
    _listeningController ??= StreamController<bool>.broadcast();
    return _listeningController!.stream;
  }

  Stream<String> get errorStream {
    _errorController ??= StreamController<String>.broadcast();
    return _errorController!.stream;
  }

  bool get isListening => _speechToText?.isListening ?? false;

  Future<bool> initialize() async {
    if (_isDisposed) return false;

    try {
      _speechToText = SpeechToText();

      // Tạo controllers nếu chưa có
      _transcriptController ??= StreamController<String>.broadcast();
      _listeningController ??= StreamController<bool>.broadcast();
      _errorController ??= StreamController<String>.broadcast();

      // final microphoneStatus = await Permission.microphone.request();
      // if (microphoneStatus != PermissionStatus.granted) {
      //   return false;
      // }

      _speechEnabled = await _speechToText!.initialize(
        onError: (error) {
          log('Speech error: ${error.errorMsg}');
          _addToErrorStream(error.errorMsg);
          _addToListeningStream(false);
        },
        onStatus: (status) {
          log('Speech status: $status');
          if (_speechToText != null) {
            _addToListeningStream(_speechToText!.isListening);
          }
        },
      );

      log('Speech initialized: $_speechEnabled');
      return _speechEnabled;
    } catch (e) {
      log('Error initializing speech: $e');
      return false;
    }
  }

  void _addToErrorStream(String error) {
    if (_isDisposed || _errorController == null || _errorController!.isClosed)
      return;
    try {
      _errorController!.add(error);
      log('✅ Error added to stream: $error');
    } catch (e) {
      log('❌ Exception adding error: $e');
    }
  }

  void _addToListeningStream(bool isListening) {
    if (_isDisposed ||
        _listeningController == null ||
        _listeningController!.isClosed) return;
    try {
      _listeningController!.add(isListening);
      log('✅ Listening state added: $isListening');
    } catch (e) {
      log('❌ Exception adding listening state: $e');
    }
  }

  void _addToTranscriptStream(String transcript) {
    if (_isDisposed ||
        _transcriptController == null ||
        _transcriptController!.isClosed) return;
    try {
      _transcriptController!.add(transcript);
      log('✅ Transcript added: $transcript');
    } catch (e) {
      log('❌ Exception adding transcript: $e');
    }
  }

  Future<bool> startListening() async {
    if (_isDisposed || _speechToText == null || !_speechEnabled) return false;

    try {
      _lastWords = '';

      final options = SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
        sampleRate: 16000,
        onDevice: false,
        autoPunctuation: true,
      );

      await _speechToText!.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          _addToTranscriptStream(_lastWords);
          log('Speech result: $_lastWords');
        },
        listenFor: Duration(minutes: 5),
        pauseFor: Duration(seconds: 10),
        localeId: 'vi-VN',
        listenOptions: options,
      );
      return true;
    } catch (e) {
      log('Error starting listening: $e');
      return false;
    }
  }

  Future<void> stopListening() async {
    if (_isDisposed || _speechToText == null) return;
    try {
      await _speechToText!.stop();
      log('Speech listening stopped');
    } catch (e) {
      log('Error stopping: $e');
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) return;

    _isDisposed = true;
    log('🗑️ Disposing SpeechService...');

    try {
      if (_speechToText?.isListening == true) {
        await _speechToText!.stop();
      }
    } catch (e) {
      log('Error stopping speech: $e');
    }

    try {
      await _transcriptController?.close();
      await _listeningController?.close();
      await _errorController?.close();
    } catch (e) {
      log('Error closing controllers: $e');
    }

    _transcriptController = null;
    _listeningController = null;
    _errorController = null;
    _speechToText = null;

    log('✅ SpeechService disposed');
  }
}
