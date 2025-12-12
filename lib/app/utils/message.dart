import 'dart:developer';
import 'dart:io';

import 'package:nylo_framework/nylo_framework.dart';

String getResponseError(dynamic e) {
  if (e is DioException) {
    if (e.error is SocketException) {
      return "Vui lòng kiểm tra kết nối internet";
    }
  }

  try {
    dynamic message = e.response?.data['message'] ?? e.response.data['error'];

    if (message is String) {
      log(message);
      if (message.length > 50) {
        message = message.substring(0, 50) + "...";
      }
      return message;
    } else if (message is List) {
      return message[0];
    } else if (message is Map) {
      return message.values.first;
    }
    return "Có lỗi xảy ra";
  } catch (e) {
    return "Có lỗi xảy ra";
  }
}
