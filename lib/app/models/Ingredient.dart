import 'package:nylo_framework/nylo_framework.dart';

class Ingredient extends Model {
  int? id;
  String? name;
  int? baseCost;
  int? retailCost;
  num? inStock;
  String? unit;
  String? image;
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
    name = json['name'];
    baseCost = json['base_cost'];
    retailCost = json['retail_cost'];
    inStock = json['in_stock'];
    unit = json['unit'];
    image = json['image'];
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
    };
  }
}
