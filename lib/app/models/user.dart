import 'dart:developer';

import 'package:nylo_framework/nylo_framework.dart';

class User extends Model {
  int? id;
  String? name;
  String? email;
  String? address;
  String? phone;
  String? storeName;
  String? image;
  int? type;
  String? apiKey;

  User();

  User.fromJson(dynamic data) {
    id = data['id'];
    name = data['name'];
    email = data['email'];
    phone = data['phone'];
    storeName = data['store_name'];
    address = data['address'];
    image = data['image'];
    type = data['user_type'] ?? 2;
    apiKey = data['api_key'];
  }

  @override
  toJson() => {
        "id": id,
        "email": email,
        "name": name,
        "phone": phone,
        "store_name": storeName,
        "address": address,
        "image": image,
        "user_type": type,
        "api_key": apiKey,
      };
}
