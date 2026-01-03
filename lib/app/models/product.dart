import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/Ingredient.dart';
import 'package:flutter_app/app/models/category.dart';
import 'package:nylo_framework/nylo_framework.dart';

enum DiscountType { percent, price }

extension DiscountTypeExtension on DiscountType {
  int getValueRequest() {
    switch (this) {
      case DiscountType.percent:
        return 2;
      case DiscountType.price:
        return 1;
    }
  }
}

class Product extends Model {
  int? id;
  String? name;
  int? retailCost;
  int? baseCost;
  num? stock;
  List<CategoryModel>? categories;
  String? image;
  String? unit;
  List<Ingredient>? ingredients;
  num quantity = 1;
  bool isSelected = false;
  num? discount;
  DiscountType discountType = DiscountType.percent;
  String? note;
  bool isManuallyEdited = false;
  num? overriddenPrice;

  // Text controllers
  final TextEditingController txtQuantity = TextEditingController();
  final TextEditingController txtPrice = TextEditingController();
  final TextEditingController txtDiscount = TextEditingController();
  final TextEditingController txtNote = TextEditingController();

  Product({
    this.name,
    this.retailCost,
    this.baseCost,
    this.stock,
    this.image,
  }) {
    txtQuantity.text = '1';
  }

  Product.fromJson(dynamic data) {
    id = data['id'];
    name = data['name'] ?? "";
    retailCost = data['retail_cost'] ?? 0;
    baseCost = data['base_cost'] ?? 0;
    stock = data['stock'] ?? 0;
    categories = (data['categories'] as List<dynamic>?)
        ?.map((e) => CategoryModel.fromJson(e))
        .toList();
    image = data['image'];
    unit = data['unit'];
    ingredients = (data['ingredients'] as List<dynamic>?)
        ?.map((e) => Ingredient.fromJson(e))
        .toList();
    txtQuantity.text = '1';
  }

  @override
  toJson() => {
        "id": id,
        "name": name,
        "retail_cost": retailCost,
        "base_cost": baseCost,
        "stock": stock,
        "categories": categories?.map((e) => e.toJson()).toList(),
        "image": image,
        "unit": unit,
      };
  void dispose() {
    txtQuantity.dispose();
    txtPrice.dispose();
    txtDiscount.dispose();
    txtNote.dispose();
  }
}
