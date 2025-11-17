import 'package:nylo_framework/nylo_framework.dart';

class Supplier extends Model {
  int? id;
  String? name;
  String? phone;
  String? address;

  Supplier({
    this.id,
    this.name,
    this.address,
  });

  Supplier.fromJson(dynamic data) {
    id = data['id'];
    name = data['name'];
    phone = data['phone'];
    address = data['address'];
  }
  @override
  toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
    };
  }
}
