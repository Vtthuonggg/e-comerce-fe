import 'package:flutter/material.dart';
import 'package:flutter_app/app/networking/dio/base_api_service.dart';
import 'package:flutter_app/app/networking/dio/interceptors/bearer_auth_interceptor.dart';
import 'package:flutter_app/app/networking/logging_interceptor.dart';
import 'package:nylo_framework/nylo_framework.dart';

class CategoryApiService extends BaseApiService {
  CategoryApiService({BuildContext? buildContext}) : super(buildContext);

  @override
  String get baseUrl => getEnv('API_BASE_URL');

  @override
  final interceptors = {
    BearerAuthInterceptor: BearerAuthInterceptor(),
    LoggingInterceptor: LoggingInterceptor()
  };

  Future<dynamic> listCategory(
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
          request.get("/category", queryParameters: queryParameters),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        return response.data;
      },
    );
  }

  Future createCategory(dynamic data) async {
    return await network(
        request: (request) => request.post("/category", data: data),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future updateCategory(int id, dynamic data) async {
    return await network(
        request: (request) => request.put("/category/$id", data: data),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future deleteCategory(int id) async {
    return await network(
        request: (request) => request.delete("/category/$id"),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future detailCategory(int id) async {
    return await network(
        request: (request) => request.get("/category/$id"),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }
}
