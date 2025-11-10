import 'package:nylo_framework/nylo_framework.dart';

class Product extends Model {
  int? id;
  String? name;
  int? retailCost;
  int? baseCost;
  num? stock;
  List<int>? categoryIds;
  String? image;
  String? unit;
  Product({
    this.name,
    this.retailCost,
    this.baseCost,
    this.stock,
    required this.categoryIds,
    this.image,
  });

  Product.fromJson(dynamic data) {
    id = data['id'];
    name = data['name'];
    retailCost = data['retail_cost'];
    baseCost = data['base_cost'];
    stock = data['stock'];
    categoryIds = (data['category_ids'] as List<dynamic>?)
        ?.map((e) => int.tryParse(e.toString()) ?? (e is int ? e : 0))
        .where((e) => e != 0)
        .toList();
    image = data['image'];
    unit = data['unit'];
  }

  @override
  toJson() => {
        "id": id,
        "name": name,
        "retail_cost": retailCost,
        "base_cost": baseCost,
        "stock": stock,
        "category_ids": categoryIds,
        "image": image,
        "unit": unit,
      };
}
