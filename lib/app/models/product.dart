import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/app/models/Ingredient.dart';
import 'package:flutter_app/app/models/category.dart';
import 'package:nylo_framework/nylo_framework.dart';

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
  Product({
    this.name,
    this.retailCost,
    this.baseCost,
    this.stock,
    this.image,
  });

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
    log(ingredients!.length!.toString());
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
}
