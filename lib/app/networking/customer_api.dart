import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/networking/dio/base_api_service.dart';
import 'package:flutter_app/app/networking/dio/interceptors/bearer_auth_interceptor.dart';
import 'package:flutter_app/app/networking/logging_interceptor.dart';
import 'package:nylo_framework/nylo_framework.dart';

class CustomerApiService extends BaseApiService {
  CustomerApiService({BuildContext? buildContext}) : super(buildContext);

  @override
  String get baseUrl => getEnv('API_BASE_URL');

  @override
  final interceptors = {
    BearerAuthInterceptor: BearerAuthInterceptor(),
    LoggingInterceptor: LoggingInterceptor()
  };

  Future<dynamic> listCustomer(String? name, int page, int size,
      {int? storeId}) async {
    var queryParameters = {
      "name": name,
      "page": page,
      "per_page": size,
    };
    if (storeId != null) {
      queryParameters['store_id'] = storeId;
    }
    return await network(
      request: (request) =>
          request.get("/customer", queryParameters: queryParameters),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        log(response.data.toString());
        return response.data;
      },
    );
  }

  Future createCustomer(dynamic data) async {
    return await network(
        request: (request) => request.post("/customer", data: data),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future updateCustomer(int id, dynamic data) async {
    return await network(
        request: (request) => request.put("/customer/$id", data: data),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future deleteCustomer(int id) async {
    return await network(
        request: (request) => request.delete("/customer/$id"),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future detailCustomer(int id) async {
    return await network(
        request: (request) => request.get("/customer/$id"),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }
}
