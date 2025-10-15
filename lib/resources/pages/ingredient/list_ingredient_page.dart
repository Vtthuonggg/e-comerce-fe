import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';

class ListIngredientPage extends NyStatefulWidget {
  static const path = '/list-ingredient';
  ListIngredientPage({super.key});

  @override
  NyState<ListIngredientPage> createState() => _ListIngredientPageState();
}

class _ListIngredientPageState extends NyState<ListIngredientPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Danh sách nguyên liệu'),
      ),
      body: Center(
        child: Text('Danh sách nguyên liệu sẽ được hiển thị ở đây.'),
      ),
    );
  }
}
