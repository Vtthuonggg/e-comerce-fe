import 'dart:async';
import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/user.dart';
import 'package:flutter_app/app/networking/list_invoice_api.dart';
import 'package:flutter_app/app/networking/order_api_service.dart';
import 'package:flutter_app/app/providers/order_notifier.dart';
import 'package:flutter_app/app/utils/getters.dart';
import 'package:flutter_app/app/utils/socket_manager.dart';
import 'package:flutter_app/app/utils/text_to_speech_service.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/order/edit_order_page.dart';
import 'package:flutter_app/resources/widgets/order_notify_dialog.dart';

import 'package:nylo_framework/nylo_framework.dart';

class GlobalSocketService {
  static final GlobalSocketService _instance = GlobalSocketService._internal();
  factory GlobalSocketService() => _instance;
  GlobalSocketService._internal();
  StreamSubscription? _socketSubscription;
  bool _isListening = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  List<String> listPathOrderPages = [
    '/edit-order',
    '/beverage-reservation',
    '/reservation-pos',
    '/table-reservation-with-time'
  ];
  void startListening() {
    if (_isListening) {
      log('GlobalSocketService: Already listening, skipping start');
      return;
    }
    _configureAudioPlayer();

    log('GlobalSocketService: Starting to listen for socket events');
    _socketSubscription = SocketManager().userEventStream.listen((data) {
      _handleSocketEvent(data);
    });

    _isListening = true;
  }

  void stopListening() {
    log('GlobalSocketService: Stopping socket listener');
    _socketSubscription?.cancel();
    _isListening = false;
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.stop();

      await _audioPlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: [
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.duckOthers,
            ],
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.notification,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );

      await _audioPlayer.play(AssetSource('sounds/notify_table.mp3'));
    } catch (e) {}
  }

  Future<void> _speakVietnamese(String roomName) async {
    String text = 'Yêu cầu gọi món từ $roomName';

    try {
      await TextToSpeechService.speak(text);
    } catch (e) {
      log('Error speaking text: $e');
    }
  }

  void _configureAudioPlayer() {
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
  }

  void _handleSocketEvent(Map<String, dynamic> eventData) {
    final context = NyNavigator.instance.router.navigatorKey?.currentContext;
    if (context == null) {
      return;
    }
    final eventType = eventData['type'];
    final data = eventData;
    if (eventType == 'order-web') {
      _handleOrderWebEvent(context, data);
    }
  }

  Future<Map<String, dynamic>> getDetailInvoiceConfig() async {
    try {
      var res = await api<ListInvoiceApi>(
          (request) => request.getInvoiceDetailConfig());
      return res;
    } catch (e) {
      return {};
    }
  }

  void _handleOrderWebEvent(
      BuildContext context, Map<String, dynamic> orderWebData) async {
    final currentUserApiKey = Auth.user<User>()?.apiKey;
    final receivedApiKey = orderWebData['apiKey'];
    if (currentUserApiKey != null && currentUserApiKey == receivedApiKey) {
      var featuresStatus = await getDetailInvoiceConfig();
      if (featuresStatus['is_noti_sound'] == true) {
        _playNotificationSound();
        await Future.delayed(Duration(milliseconds: 800));
        final description = orderWebData['description']?.toString() ??
            'Đơn hàng đã được cập nhật';
        final headerInfo = extractHeaderFromDescription(description);
        final title = headerInfo['title'] ?? description;
        final roomName = _extractRoomNameFromTitle(title);
        _speakVietnamese(roomName);
      }

      final currentRoute = _getCurrentRouteFromNyRouter();
      if (currentRoute == '/beverage-reservation' ||
          currentRoute == '/reservation-pos') {
        _updateOrderTable(orderWebData['roomId'], orderWebData['order_id']);
      }

      _refreshManageTablePage();
      _showOrderUpdateToastWithActions(
          context, orderWebData['description'], orderWebData);
    }
  }

  String _extractRoomNameFromTitle(String? title) {
    if (title == null) return '';
    // Match substring after colon (supports ':' and fullwidth '：')
    final reg = RegExp(r'[:：]\s*(.+)$');
    final m = reg.firstMatch(title);
    if (m != null) {
      var candidate = m.group(1)!.trim();
      // Stop at common separators (comma, parenthesis, dash)
      candidate = candidate.split(RegExp(r'[,(-]'))[0].trim();
      return candidate;
    }
    // Fallback: attempt to remove known prefix
    return title
        .replaceFirst(
            RegExp(r'^(Đặt món từ bàn[:：]\s*)', caseSensitive: false), '')
        .trim();
  }

  String? _getCurrentRouteFromNyRouter() {
    try {
      final router = NyNavigator.instance.router;

      final navigatorState = router.navigatorKey?.currentState;
      if (navigatorState != null) {
        String? currentRouteName;

        try {
          navigatorState.popUntil((route) {
            currentRouteName = route.settings.name;
            return true;
          });

          if (currentRouteName != null && currentRouteName!.isNotEmpty) {
            return currentRouteName;
          }
        } catch (e) {}
      }

      final context = router.navigatorKey?.currentContext;
      if (context != null) {
        try {
          final modalRoute = ModalRoute.of(context);
          if (modalRoute?.settings.name != null) {
            return modalRoute?.settings.name;
          }
        } catch (e) {}
      }

      try {
        final currentRouteProperty = router.toString();

        if (currentRouteProperty.contains('ManageTablePage')) {
          return 'ManageTablePage';
        }
      } catch (e) {}

      return null;
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }

  void _refreshManageTablePage() {
    try {
      OrderNotifier().requestRefreshManageTable();
    } catch (e) {}
  }

  void _updateOrderTable(String roomId, int orderId) {
    try {
      OrderNotifier().notifyOrderUpdate(roomId, orderId);
      OrderNotifier().notifyOrderPosUpdate(roomId, orderId);
    } catch (e) {}
  }

  void _updateOrder(int orderId) {
    try {
      OrderNotifier().notifyEditOrder(orderId);
    } catch (e) {}
  }

  void _showOrderUpdateToastWithActions(
    BuildContext context,
    String description,
    Map<String, dynamic> orderData,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return OrderNotificationDialog(
          description: description,
          orderData: orderData,
          onTap: () => _onToastTapped(context, orderData),
        );
      },
    );
  }

  Future _fetchOrderDetail(int id) async {
    return api<OrderApiService>((request) => request.detailOrder(id));
  }

  void _onToastTapped(
      BuildContext context, Map<String, dynamic> orderData) async {
    final roomId = orderData['roomId'];
    final orderId = orderData['order_id'];
    final areaName = orderData['area_name'] ?? '';
    dynamic data = await _fetchOrderDetail(orderId);

    routeTo(EditOrderPage.path, data: {
      'room_id': roomId,
      'order_id': orderId,
      'edit_data': data,
      'current_room_type': 'using',
      'area_name': areaName
    });
  }

  bool get isListening => _isListening;
}
