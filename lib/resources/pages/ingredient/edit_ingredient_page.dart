import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';

class EditIngredientPage extends NyStatefulWidget {
  static const path = '/edit_ingredient';
   EditIngredientPage({Key? key}) : super(key: key);

  @override
  NyState<EditIngredientPage> createState() => _EditIngredientPageState();
}

class _EditIngredientPageState extends NyState<EditIngredientPage> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}