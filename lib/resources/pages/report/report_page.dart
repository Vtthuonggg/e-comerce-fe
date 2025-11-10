import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';

class ReportPage extends NyStatefulWidget {
  static const path = '/report';
  ReportPage({super.key});

  @override
  NyState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends NyState<ReportPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
