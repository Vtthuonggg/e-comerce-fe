import 'package:nylo_framework/nylo_framework.dart';

class Product extends Model {
  int? id;
  String? name;
  int? retailCost;
  int? baseCost;
  num? stock;
  int? categoryId;

  Product({
    this.name,
    this.retailCost,
    this.baseCost,
    this.stock,
    required this.categoryId,
  });

  Product.fromJson(dynamic data) {
    name = data['name'];
    retailCost = data['retail_cost'];
    baseCost = data['base_cost'];
    stock = data['stock'];
    categoryId = data['category_id'];
  }

  @override
  toJson() => {
        "name": name,
        "retail_cost": retailCost,
        "base_cost": baseCost,
        "stock": stock,
        "category_id": categoryId,
      };
}
