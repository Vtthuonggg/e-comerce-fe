import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/utils/global_socket_service.dart';
import '../config/providers.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:flutter_app/app/utils/socket_manager.dart';

/// Boot methods for Nylo.
class Boot {
  static Future<Nylo> nylo() async {
    final nylo = await bootApplication(providers);

    await _initializeSocket();

    return nylo;
  }

  static Future<void> finished(Nylo nylo) async {
    await bootFinished(nylo, providers);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      GlobalSocketService().startListening();
      log('Global Socket Service started after UI ready');
    });
  }

  static Future<void> _initializeSocket() async {
    try {
      SocketManager().init();
      log('Socket Manager initialized in boot');
    } catch (e) {
      log('Error initializing socket: $e');
    }
  }
}
