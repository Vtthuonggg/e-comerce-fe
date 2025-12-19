import 'package:nylo_framework/nylo_framework.dart';

class Employee extends Model {
  int? id;
  String? name;
  String? phone;
  String? address;

  Employee({
    this.id,
    this.name,
    this.address,
  });

  Employee.fromJson(dynamic data) {
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
