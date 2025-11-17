import 'package:nylo_framework/nylo_framework.dart';

class Ingredient extends Model {
  int? id;
  String? name;
  int? baseCost;
  int? retailCost;
  num? inStock;
  String? unit;
  String? image;
  num? quantity;
  bool isSelected = false;
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
    retailCost = json['retail_cost'] ?? 0;
    inStock = json['in_stock'] ?? 0;
    unit = json['unit'] ?? '';
    image = json['image'] ?? '';
    quantity = json['quantity'] ?? 0;
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
    };
  }
}
