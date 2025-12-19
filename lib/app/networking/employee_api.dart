import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/networking/dio/base_api_service.dart';
import 'package:flutter_app/app/networking/dio/interceptors/bearer_auth_interceptor.dart';
import 'package:flutter_app/app/networking/logging_interceptor.dart';
import 'package:nylo_framework/nylo_framework.dart';

class EmployeeApiService extends BaseApiService {
  EmployeeApiService({BuildContext? buildContext}) : super(buildContext);

  @override
  String get baseUrl => getEnv('API_BASE_URL');

  @override
  final interceptors = {
    BearerAuthInterceptor: BearerAuthInterceptor(),
    LoggingInterceptor: LoggingInterceptor()
  };

  Future<dynamic> listEmployee(
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
          request.get("/employee", queryParameters: queryParameters),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        log(response.data.toString());
        return response.data;
      },
    );
  }

  Future createEmployee(dynamic data) async {
    return await network(
        request: (request) => request.post("/employee", data: data),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future updateEmployee(int id, dynamic data) async {
    return await network(
        request: (request) => request.put("/employee/$id", data: data),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future deleteEmployee(int id) async {
    return await network(
        request: (request) => request.delete("/employee/$id"),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future detailEmployee(int id) async {
    return await network(
        request: (request) => request.get("/employee/$id"),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }
}
