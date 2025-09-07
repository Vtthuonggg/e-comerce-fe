import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';

class EditProductPage extends NyStatefulWidget {
  static const path = '/edit_product';
  EditProductPage({Key? key}) : super(path, key: key);

  @override
  NyState<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends NyState<EditProductPage> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
