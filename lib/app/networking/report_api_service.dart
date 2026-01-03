import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/product.dart';
import 'package:flutter_app/app/networking/dio/base_api_service.dart';
import 'package:flutter_app/app/networking/dio/interceptors/bearer_auth_interceptor.dart';
import 'package:flutter_app/app/networking/logging_interceptor.dart';
import 'package:nylo_framework/nylo_framework.dart';

class ReportApiService extends BaseApiService {
  ReportApiService({BuildContext? buildContext}) : super(buildContext);

  @override
  String get baseUrl => getEnv('API_BASE_URL');

  @override
  final interceptors = {
    BearerAuthInterceptor: BearerAuthInterceptor(),
    LoggingInterceptor: LoggingInterceptor()
  };

  Future<dynamic> dailyReport() async {
    return await network(
      request: (request) => request.get("/report/quick-stats"),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        log(response.data.toString());
        return response.data;
      },
    );
  }
}
