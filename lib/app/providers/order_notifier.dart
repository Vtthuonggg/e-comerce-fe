import 'dart:developer';

import 'package:flutter/foundation.dart';

class OrderNotifier extends ChangeNotifier {
  static final OrderNotifier _instance = OrderNotifier._internal();
  factory OrderNotifier() => _instance;
  OrderNotifier._internal();
  String? _targetRoomId;
  String? _targetRoomIdPos;
  bool _shouldTableRefresh = false;
  bool _shouldOrderRefresh = false;
  bool _shouldOrderPosRefresh = false;
  int? _targetOrderId;
  int? _targetOrderIdPos;
  bool _shouldEditOrderRefresh = false;
  int? _targetEditOrderId;
  bool get shouldTableRefresh => _shouldTableRefresh;
  bool get shouldOrderRefresh => _shouldOrderRefresh;
  bool get shouldOrderPosRefresh => _shouldOrderPosRefresh;
  bool get shouldEditOrderRefresh => _shouldEditOrderRefresh;
  String? get targetRoomId => _targetRoomId;
  String? get targetRoomIdPos => _targetRoomIdPos;
  int? get targetOrderId => _targetOrderId;
  int? get targetOrderIdPos => _targetOrderIdPos;
  int? get targetEditOrderId => _targetEditOrderId;

  //manage table refresh
  void requestRefreshManageTable({int? roomId}) {
    _shouldTableRefresh = true;
    notifyListeners();
  }

  //manage table refresh
  void refreshTableCompleted() {
    _shouldTableRefresh = false;
    notifyListeners();
  }

//update table
  void notifyOrderUpdate(String roomId, int orderId) {
    _shouldOrderRefresh = true;
    _targetRoomId = roomId;
    _targetOrderId = orderId;
    notifyListeners();
  }

//update table
  void refreshOrderCompleted() {
    _shouldOrderRefresh = false;
    _targetRoomId = null;
    notifyListeners();
  }

  //update table pos
  void notifyOrderPosUpdate(String roomId, int orderId) {
    _shouldOrderPosRefresh = true;
    _targetRoomIdPos = roomId;
    _targetOrderIdPos = orderId;
    notifyListeners();
  }

//update table pos
  void refreshOrderPosCompleted() {
    _shouldOrderPosRefresh = false;
    _targetRoomIdPos = null;
    notifyListeners();
  }

  void notifyEditOrder(int orderId) {
    _shouldEditOrderRefresh = true;
    _targetEditOrderId = orderId;
    notifyListeners();
  }
}
