import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/user.dart';
import 'package:flutter_app/app/networking/dio/base_api_service.dart';
import 'package:flutter_app/app/networking/dio/interceptors/bearer_auth_interceptor.dart';
import 'package:flutter_app/app/networking/logging_interceptor.dart';
import 'package:flutter_app/config/storage_keys.dart';
import 'package:nylo_framework/nylo_framework.dart';

class AccountApi extends BaseApiService {
  AccountApi({BuildContext? buildContext}) : super(buildContext);
  @override
  final interceptors = {
    LoggingInterceptor: LoggingInterceptor(),
    BearerAuthInterceptor: BearerAuthInterceptor(),
  };

  @override
  String get baseUrl => getEnv('API_BASE_URL');

  Future<User?> login(dynamic data) async {
    return await network(
        request: (request) => request.post("/login", data: data),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          User user = User.fromJson(response.data["data"]["user"]);
          await NyStorage.store(
              StorageKey.userToken, response.data["data"]["access_token"],
              inBackpack: true);
          return user;
        });
  }

  Future<dynamic> register(dynamic data) async {
    return await network(
        request: (request) => request.post("/register", data: data),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          User user = User.fromJson(response.data["data"]["user"]);

          await NyStorage.store(
              StorageKey.userToken, response.data["data"]["access_token"],
              inBackpack: true);
          return user;
        });
  }

  Future<User> infoAccount() async {
    String? userToken = await NyStorage.read(StorageKey.userToken);
    if (userToken == null) {
      throw Exception("User token not found");
    }

    return await network(
        request: (request) => request.get(
              "/me",
            ),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          User user = User.fromJson(response.data['data']['user']);
          return user;
        });
  }

  Future<dynamic> updateInfoAccount(dynamic data) async {
    return await network(
        request: (request) => request.put(
              "/user",
              data: data,
            ),
        handleFailure: (error) => throw error.message!,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future<dynamic> sendOtp(String email) async {
    return await network(
        request: (request) => request.post("/otp/send", data: {"email": email}),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future<dynamic> resendOtp(String email) async {
    return await network(
        request: (request) =>
            request.post("/otp/resend", data: {"email": email}),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future<dynamic> verifyOtp(String email, String otp) async {
    return await network(
        request: (request) => request.post("/otp/verify", data: {
              "email": email,
              "otp": otp,
            }),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future<dynamic> registerWithOtp(dynamic data) async {
    return await network(
        request: (request) => request.post("/otp/register", data: data),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          User user = User.fromJson(response.data["data"]["user"]);
          await NyStorage.store(
              StorageKey.userToken, response.data["data"]["access_token"],
              inBackpack: true);
          return user;
        });
  }
}
