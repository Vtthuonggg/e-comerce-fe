import 'package:nylo_framework/nylo_framework.dart';

class User extends Model {
  String? name;
  String? email;
  String? note;
  String? phone;
  String? storeName;
  String? avatar;
  int? type;
  String? apiKey;

  User();

  User.fromJson(dynamic data) {
    name = data['name'];
    email = data['email'];
    phone = data['phone_number'];
    storeName = data['store_name'];
    note = data['notes'];
    avatar = data['avatar'];
    type = data['user_type'];
    apiKey = data['api_key'];
  }

  @override
  toJson() => {
        "name": name,
        "phone_number": phone,
        "store_name": storeName,
        "notes": note,
        "avatar": avatar,
        "user_type": type,
        "api_key": apiKey,
      };
}
