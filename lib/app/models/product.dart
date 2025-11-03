import 'package:nylo_framework/nylo_framework.dart';

class Product extends Model {
  int? id;
  String? name;
  int? retailCost;
  int? baseCost;
  num? stock;
  int? categoryId;
  String? image;

  Product({
    this.name,
    this.retailCost,
    this.baseCost,
    this.stock,
    required this.categoryId,
    this.image,
  });

  Product.fromJson(dynamic data) {
    id = data['id'];
    name = data['name'];
    retailCost = data['retail_cost'];
    baseCost = data['base_cost'];
    stock = data['stock'];
    categoryId = data['category_id'];
    image = data['image'];
  }

  @override
  toJson() => {
        "id": id,
        "name": name,
        "retail_cost": retailCost,
        "base_cost": baseCost,
        "stock": stock,
        "category_id": categoryId,
        "image": image,
      };
}
