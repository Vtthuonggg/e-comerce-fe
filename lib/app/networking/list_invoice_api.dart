import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/networking/dio/base_api_service.dart';
import 'package:flutter_app/app/networking/dio/interceptors/bearer_auth_interceptor.dart';
import 'package:nylo_framework/nylo_framework.dart';

class ListInvoiceApi extends BaseApiService {
  ListInvoiceApi({BuildContext? buildContext}) : super(buildContext);

  @override
  String get baseUrl => getEnv('API_BASE_URL');

  @override
  final interceptors = {
    BearerAuthInterceptor: BearerAuthInterceptor(),
    // LoggingInterceptor: LoggingInterceptor()
  };
  Future getListInvoice() async {
    return await network(
      request: (request) => request.get("/bill"),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        return response.data;
      },
    );
  }

  Future getInvoiceDetailConfig() async {
    return await network(
      request: (request) => request.get("/config/status"),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        return response.data['data'];
      },
    );
  }

  Future updateInvoiceDetailConfig(data) async {
    return await network(
      request: (request) => request.put("/config/status", data: data),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        return response.data;
      },
    );
  }
}
