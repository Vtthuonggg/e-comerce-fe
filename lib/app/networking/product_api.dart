import 'package:flutter/material.dart';
import 'package:flutter_app/app/networking/dio/base_api_service.dart';
import 'package:flutter_app/app/networking/dio/interceptors/bearer_auth_interceptor.dart';
import 'package:flutter_app/app/networking/logging_interceptor.dart';
import 'package:nylo_framework/nylo_framework.dart';

class ProductApiService extends BaseApiService {
  ProductApiService({BuildContext? buildContext}) : super(buildContext);

  @override
  String get baseUrl => getEnv('API_BASE_URL');

  @override
  final interceptors = {
    BearerAuthInterceptor: BearerAuthInterceptor(),
    LoggingInterceptor: LoggingInterceptor()
  };

  Future<dynamic> listProduct(String? name, int page, int size, int type,
      {int? storeId}) async {
    var queryParameters = {
      "name": name,
      "page": page,
      "type": type,
      "per_page": size,
    };
    if (storeId != null) {
      queryParameters['store_id'] = storeId;
    }
    return await network(
      request: (request) =>
          request.get("/product", queryParameters: queryParameters),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        // List<Product> products = [];
        // response.data["data"].forEach((category) {
        //   products.add(Product.fromJson(category));
        // });
        return response.data;
      },
    );
  }
}
