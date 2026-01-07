import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/product.dart';
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

  Future<dynamic> listProduct(String? name, int page, int size,
      {int? categoryId}) async {
    var queryParameters = {
      "name": name,
      "page": page,
      "per_page": size,
    };
    if (categoryId != null) {
      queryParameters['category_id'] = categoryId;
    }
    return await network(
      request: (request) =>
          request.get("/product", queryParameters: queryParameters),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        log(response.data.toString());
        return response.data;
      },
    );
  }

  Future createProduct(dynamic data) async {
    return await network(
        request: (request) => request.post("/product", data: data),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future updateProduct(int id, dynamic data) async {
    return await network(
        request: (request) => request.put("/product/$id", data: data),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future deleteProduct(int id) async {
    return await network(
        request: (request) => request.delete("/product/$id"),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future detailProduct(int id) async {
    return await network(
        request: (request) => request.get("/product/$id"),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future<dynamic> listTopping(String? name, int page, int size) async {
    var queryParameters = {
      "name": name,
      "page": page,
      "per_page": size,
      "is_topping": true,
    };
    return await network(
      request: (request) =>
          request.get("/product", queryParameters: queryParameters),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        return response.data;
      },
    );
  }
}
