import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/networking/dio/base_api_service.dart';
import 'package:flutter_app/app/networking/dio/interceptors/bearer_auth_interceptor.dart';
import 'package:flutter_app/app/networking/logging_interceptor.dart';
import 'package:nylo_framework/nylo_framework.dart';

class OrderApiService extends BaseApiService {
  OrderApiService({BuildContext? buildContext}) : super(buildContext);

  @override
  String get baseUrl => getEnv('API_BASE_URL');

  @override
  final interceptors = {
    BearerAuthInterceptor: BearerAuthInterceptor(),
    LoggingInterceptor: LoggingInterceptor()
  };

  Future<dynamic> listOrder(String? name, int page, int size,
      {int? type}) async {
    var queryParameters = {
      "name": name,
      "page": page,
      "per_page": size,
    };
    if (type != null) {
      queryParameters["type"] = type;
    }
    return await network(
      request: (request) =>
          request.get("/order", queryParameters: queryParameters),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        return response.data;
      },
    );
  }

  Future createOrder(dynamic data) async {
    return await network(
        request: (request) => request.post("/order", data: data),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future updateOrder(int id, dynamic data) async {
    log(data.toString());
    log("Updating order with id: $id");
    return await network(
        request: (request) => request.put("/order/$id", data: data),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future deleteOrder(int id) async {
    return await network(
        request: (request) => request.delete("/order/$id"),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future detailOrder(int id) async {
    return await network(
        request: (request) => request.get("/order/$id"),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          log("Detail Order Response: ${response.data}");
          return response.data;
        });
  }
}
