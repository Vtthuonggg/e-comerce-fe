import 'package:flutter_app/app/networking/category_api.dart';
import 'package:flutter_app/app/networking/cloudinary_api.dart';
import 'package:flutter_app/app/networking/customer_api.dart';
import 'package:flutter_app/app/networking/dio/base_api_service.dart';
import 'package:flutter_app/app/networking/account_api.dart';
import 'package:flutter_app/app/networking/ingredient_api.dart';
import 'package:flutter_app/app/networking/product_api.dart';
import '/app/models/user.dart';
import '/app/networking/api_service.dart';

/* Model Decoders
|--------------------------------------------------------------------------
| Model decoders are used in 'app/networking/' for morphing json payloads
| into Models.
|
| Learn more https://nylo.dev/docs/5.20.0/decoders#model-decoders
|-------------------------------------------------------------------------- */

final Map<Type, dynamic> modelDecoders = {
  List<User>: (data) =>
      List.from(data).map((json) => User.fromJson(json)).toList(),
  //
  User: (data) => User.fromJson(data),

  // User: (data) => User.fromJson(data),
};

/* API Decoders
| -------------------------------------------------------------------------
| API decoders are used when you need to access an API service using the
| 'api' helper. E.g. api<MyApiService>((request) => request.fetchData());
|
| Learn more https://nylo.dev/docs/5.20.0/decoders#api-decoders
|-------------------------------------------------------------------------- */

final Map<Type, BaseApiService> apiDecoders = {
  ApiService: ApiService(),
  AccountApi: AccountApi(),
  ProductApiService: ProductApiService(),
  CloudinaryApiService: CloudinaryApiService(),
  CategoryApiService: CategoryApiService(),
  IngredientApiService: IngredientApiService(),
  CustomerApiService: CustomerApiService(),

  // ...
};


/* Controller Decoders
| -------------------------------------------------------------------------
| Controller are used in pages.
|
| Learn more https://nylo.dev/docs/5.20.0/controllers
|-------------------------------------------------------------------------- */


