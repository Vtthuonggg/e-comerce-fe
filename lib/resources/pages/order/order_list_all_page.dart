import 'package:flutter/material.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:nylo_framework/nylo_framework.dart';

class OrderListAllPage extends NyStatefulWidget {
  static const path = '/order-list-all';
  OrderListAllPage({super.key});

  @override
  NyState<OrderListAllPage> createState() => _OrderListAllPageState();
}

class _OrderListAllPageState extends NyState<OrderListAllPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: Text('Danh sách đơn hàng',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Text('Danh sách tất cả đơn hàng'),
      ),
    );
  }
}
