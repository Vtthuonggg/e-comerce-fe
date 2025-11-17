import 'package:flutter/material.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:nylo_framework/nylo_framework.dart';

class EditOrderPage extends NyStatefulWidget {
  static const path = '/edit-order';
  final controller = Controller();
  EditOrderPage({super.key});

  @override
  NyState<EditOrderPage> createState() => _EditOrderPageState();
}

class _EditOrderPageState extends NyState<EditOrderPage> {
  @override
  Widget build(BuildContext context) {
    return Placeholder();
  }
}
