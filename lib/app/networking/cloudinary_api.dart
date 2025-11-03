import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/networking/dio/base_api_service.dart';
import 'package:nylo_framework/nylo_framework.dart';

class CloudinaryApiService extends BaseApiService {
  CloudinaryApiService({BuildContext? buildContext}) : super(buildContext);

  @override
  String get baseUrl => getEnv('CLOUDINARY_URL');
  String get uploadPreset => getEnv('CLOUDINARY_UPLOAD_PRESET');

  Future uploadImage(File imageFile) async {
    FormData formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path),
      'upload_preset': uploadPreset,
    });
    return await network(
        request: (request) => request.post("/image/upload", data: formData),
        handleFailure: (error) => throw error,
        handleSuccess: (response) async {
          return response.data['url'];
        });
  }
}
