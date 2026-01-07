import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/product.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:nylo_framework/nylo_framework.dart';

class Ingredient extends Model {
  int? id;
  String? name;
  int? baseCost;
  int? copyBaseCost;
  int? retailCost;
  int? copyRetailCost;
  num? inStock;
  String? unit;
  String? image;
  num quantity = 0;
  bool isSelected = false;
  TextEditingController txtPrice = TextEditingController();
  TextEditingController txtVAT = TextEditingController();
  UniqueKey? quantityKey = UniqueKey();
  UniqueKey? priceKey = UniqueKey();
  UniqueKey? discountKey = UniqueKey();
  UniqueKey? vatKey = UniqueKey();
  num? discount;
  num? coppyDiscount;
  DiscountType? discountType;
  String productNote = '';
  int? categoryId;
  num? vat;
  Ingredient({
    this.id,
    this.name,
    this.baseCost,
    this.retailCost,
    this.inStock,
    this.unit,
  });
  Ingredient.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'] ?? '';
    baseCost = json['base_cost'] ?? 0;
    copyBaseCost = json['base_cost'] ?? 0;
    retailCost = json['retail_cost'] ?? 0;
    copyRetailCost = json['retail_cost'] ?? 0;

    inStock = json['in_stock'] ?? 0;
    unit = json['unit'] ?? '';
    image = json['image'] ?? '';
    quantity = json['quantity'] ?? 0;
    discount = json['discount'] ?? 0;
    coppyDiscount = json['discount'] ?? 0;
    if (json['discount_type'] != null) {
      discountType = DiscountType.fromValueRequest(json['discount_type']);
    }
    productNote = json['note'] ?? '';
    categoryId = json['category_id'] ?? 0;
    vat = json['vat'] ?? 0;
    txtPrice.text = vnd.format(json['base_cost'] ?? 0);
    txtVAT.text = '${json['vat'] ?? 0} %';
  }
  @override
  toJson() {
    return {
      'id': id,
      'name': name,
      'base_cost': baseCost,
      'retail_cost': retailCost,
      'in_stock': inStock,
      'unit': unit,
      'image': image,
      'is_selected': isSelected,
      'quantity': quantity,
    };
  }
}
