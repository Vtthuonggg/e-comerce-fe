import 'dart:io';

import 'package:flutter_app/app/networking/cloudinary_api.dart';
import 'package:flutter_app/bootstrap/helpers.dart';

Future<String?> getImageCloudinaryUrl(File imageFile) async {
  final response = await api<CloudinaryApiService>(
      (request) => request.uploadImage(imageFile));
  return response;
}
