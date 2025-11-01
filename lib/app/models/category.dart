import 'package:nylo_framework/nylo_framework.dart';

class CategoryModel extends Model {
  int? id;
  String? name;
  String? description;

  CategoryModel({
    this.id,
    this.name,
    this.description,
  });

  CategoryModel.fromJson(dynamic data) {
    id = data['id'];
    name = data['name'];
    description = data['description'];
  }
  @override
  toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}
