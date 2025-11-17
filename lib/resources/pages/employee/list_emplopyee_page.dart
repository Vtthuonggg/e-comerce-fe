import 'package:flutter/material.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:nylo_framework/nylo_framework.dart';

class ListEmployeePage extends NyStatefulWidget {
  static const path = '/employees';
  final controller = Controller();

  ListEmployeePage({super.key});

  @override
  NyState<ListEmployeePage> createState() => _ListEmployeePageState();
}

class _ListEmployeePageState extends NyState<ListEmployeePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Danh sách nhân viên'),
      ),
      body: Center(
        child: Text('Danh sách nhân viên sẽ hiển thị ở đây'),
      ),
    );
  }
}
