import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/networking/dio/base_api_service.dart';
import 'package:flutter_app/app/networking/dio/interceptors/bearer_auth_interceptor.dart';
import 'package:flutter_app/app/networking/logging_interceptor.dart';
import 'package:nylo_framework/nylo_framework.dart';

class SupplierApiService extends BaseApiService {
  SupplierApiService({BuildContext? buildContext}) : super(buildContext);

  @override
  String get baseUrl => getEnv('API_BASE_URL');

  @override
  final interceptors = {
    BearerAuthInterceptor: BearerAuthInterceptor(),
    LoggingInterceptor: LoggingInterceptor()
  };

  Future<dynamic> listSupplier(
    String? name,
    int page,
    int size,
  ) async {
    var queryParameters = {
      "name": name,
      "page": page,
      "per_page": size,
    };

    return await network(
      request: (request) =>
          request.get("/supplier", queryParameters: queryParameters),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        log(response.data.toString());
        return response.data;
      },
    );
  }

  Future createSupplier(dynamic data) async {
    return await network(
        request: (request) => request.post("/supplier", data: data),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future updateSupplier(int id, dynamic data) async {
    return await network(
        request: (request) => request.put("/supplier/$id", data: data),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future deleteSupplier(int id) async {
    return await network(
        request: (request) => request.delete("/supplier/$id"),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future detailSupplier(int id) async {
    return await network(
        request: (request) => request.get("/supplier/$id"),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }
}
