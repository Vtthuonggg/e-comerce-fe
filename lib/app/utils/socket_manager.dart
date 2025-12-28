import 'dart:async';
import 'dart:developer';

import 'package:nylo_framework/nylo_framework.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketManager {
  static final SocketManager _instance = SocketManager._internal();
  factory SocketManager() => _instance;
  SocketManager._internal();

  String get socketUrl => getEnv('SOCKET_IO_URL');
  late IO.Socket _socket;
  StreamController<Map<String, dynamic>>? _userEventController =
      StreamController.broadcast();
  bool _isConnected = false;

  Stream<Map<String, dynamic>> get userEventStream {
    if (_userEventController == null || _userEventController!.isClosed) {
      _userEventController = StreamController.broadcast();
    }
    return _userEventController!.stream;
  }

  void init() {
    if (_isConnected) return;

    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionAttempts': 5,
    });

    _socket.on('connect', (_) {
      log('Socket connected');
      _isConnected = true;
    });

    _socket.on('disconnect', (_) {
      log('Socket disconnected');
      _isConnected = false;
    });

    _socket.on('user', (data) {
      if (data is Map<String, dynamic>) {
        _userEventController?.add(data);
      }
    });

    _socket.on('order-web', (data) {
      _userEventController?.add({
        'type': 'order-web',
        ...data,
      });
    });

    _socket.on('order-bill', (data) {
      _userEventController?.add({
        'type': 'order-bill',
        ...data,
      });
    });
    _socket.on('order-created', (data) {
      log(data.toString());
      _userEventController?.add({
        'type': 'order-created',
        ...data,
      });
    });
    _socket.connect();
  }

  void sendEvent(String event, dynamic data) {
    if (_isConnected) {
      _socket.emit(event, data);
    }
  }

  void disconnect() {
    _socket.disconnect();
    _isConnected = false;
  }

  void dispose() {
    _socket.dispose();
    _userEventController?.close();
  }

  bool get isConnected => _isConnected;
}
