import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/networking/dio/base_api_service.dart';
import 'package:flutter_app/app/networking/dio/interceptors/bearer_auth_interceptor.dart';
import 'package:flutter_app/app/networking/logging_interceptor.dart';
import 'package:nylo_framework/nylo_framework.dart';

class IngredientApiService extends BaseApiService {
  IngredientApiService({BuildContext? buildContext}) : super(buildContext);

  @override
  String get baseUrl => getEnv('API_BASE_URL');

  @override
  final interceptors = {
    BearerAuthInterceptor: BearerAuthInterceptor(),
    LoggingInterceptor: LoggingInterceptor()
  };

  Future<dynamic> listIngredient(String? name, int page, int size, int type,
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
          request.get("/ingredient", queryParameters: queryParameters),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        log(response.data.toString());
        return response.data;
      },
    );
  }

  Future createIngredient(dynamic data) async {
    return await network(
        request: (request) => request.post("/ingredient", data: data),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future updateIngredient(int id, dynamic data) async {
    return await network(
        request: (request) => request.put("/ingredient/$id", data: data),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future deleteIngredient(int id) async {
    return await network(
        request: (request) => request.delete("/ingredient/$id"),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future detailIngredient(int id) async {
    return await network(
        request: (request) => request.get("/ingredient/$id"),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }
}
