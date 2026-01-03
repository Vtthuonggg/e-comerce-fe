import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/user.dart';
import 'package:flutter_app/app/networking/logging_interceptor.dart';
import 'package:flutter_app/config/storage_keys.dart';
import '/app/networking/dio/base_api_service.dart';
import 'package:nylo_framework/nylo_framework.dart';

import 'dio/interceptors/bearer_auth_interceptor.dart';

class VoiceOrderApiService extends BaseApiService {
  VoiceOrderApiService({BuildContext? buildContext}) : super(buildContext);

  @override
  String get baseUrl => getEnv('VOICE_ORDER_URL');

  @override
  final interceptors = {
    BearerAuthInterceptor: BearerAuthInterceptor(),
    LoggingInterceptor: LoggingInterceptor()
  };
  Future<String> get token async {
    return await NyStorage.read(StorageKey.userToken) ?? '';
  }

  Future<Map<String, dynamic>> get queryParameters async {
    final t = await token;
    return {'apiKey': Auth.user<User>()?.apiKey ?? '', 'token': t};
  }

  Future createVoiceOrder(dynamic payload) async {
    final query = await queryParameters;
    return await network(
      request: (request) =>
          request.post("/order", data: payload, queryParameters: query),
      handleFailure: (error) {
        log('error creating voice order: $error');
        throw error;
      },
      handleSuccess: (response) async {
        return response.data;
      },
    );
  }

  Future createVoiceOrderService(dynamic payload) async {
    final query = await this.queryParameters;
    return await network(
      request: (request) =>
          request.post("/order-service", data: payload, queryParameters: query),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        return response.data["data"];
      },
    );
  }
}
