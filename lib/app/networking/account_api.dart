import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/events/login_event.dart';
import 'package:flutter_app/app/models/user.dart';
import 'package:flutter_app/app/networking/dio/base_api_service.dart';
import 'package:flutter_app/app/networking/logging_interceptor.dart';
import 'package:flutter_app/config/storage_keys.dart';
import 'package:nylo_framework/nylo_framework.dart';

class AccountApi extends BaseApiService {
  AccountApi({BuildContext? buildContext}) : super(buildContext);
  @override
  final interceptors = {LoggingInterceptor: LoggingInterceptor()};
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
              "/user",
              options: Options(
                headers: {
                  'Authorization': 'Bearer $userToken',
                },
              ),
            ),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          log(response.data.toString());
          User user = User.fromJson(response.data);
          return user;
        });
  }

  Future<dynamic> updateInfoAccount(dynamic data) async {
    log(data.toString());
    String? userToken = await NyStorage.read(StorageKey.userToken);
    if (userToken == null) {
      throw Exception("User token not found");
    }
    return await network(
        request: (request) => request.put(
              "/user/update",
              data: data,
              options: Options(
                headers: {
                  'Authorization': 'Bearer $userToken',
                },
              ),
            ),
        handleFailure: (error) => throw error.message!,
        handleSuccess: (response) async {
          return response.data;
        });
  }

  Future<String> uploadImage(
    File image,
  ) async {
    log(image.path);
    String? userToken = await NyStorage.read(StorageKey.userToken);
    if (userToken == null) {
      throw Exception("User token not found");
    }

    FormData formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(image.path,
          filename: image.path.split('/').last),
    });

    return await network(
        request: (request) => request.post('/upload-image',
            data: formData,
            options: Options(
              headers: {
                'Authorization': 'Bearer $userToken',
                'Content-Type': 'multipart/form-data',
              },
            )),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          log(response.data.toString());
          return response.data['url'];
        });
  }
}
