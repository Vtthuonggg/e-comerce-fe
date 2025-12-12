import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/networking/dio/interceptors/bearer_auth_interceptor.dart';
import 'package:flutter_app/resources/pages/table/table_item.dart';
import '/app/networking/dio/base_api_service.dart';
import 'package:nylo_framework/nylo_framework.dart';

class RoomApiService extends BaseApiService {
  RoomApiService({BuildContext? buildContext}) : super(buildContext);

  @override
  String get baseUrl => getEnv('API_BASE_URL');

  @override
  final interceptors = {
    BearerAuthInterceptor: BearerAuthInterceptor(),
    // LoggingInterceptor: LoggingInterceptor()
  };

  Future<dynamic> fetchAreas() async {
    return await network(
      request: (request) => request.get("/area"),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        return response.data;
      },
    );
  }

  fetchRooms({String? search}) {
    Map<String, dynamic> params = {
      "per_page": 100,
    };

    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }

    return network(
      request: (request) => request.get("/room", queryParameters: params),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        return response.data;
      },
    );
  }

  createArea(dynamic data) {
    return network(
      request: (request) => request.post(
        "/area",
        data: data,
      ),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        return response.data;
      },
    );
  }

  deleteArea({required int id}) {
    return network(
      request: (request) => request.delete("/area/$id"),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        return response.data;
      },
    );
  }

  createRoom(Map<String, dynamic> value) {
    return network(
      request: (request) => request.post(
        "/room",
        data: value,
      ),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        return response.data;
      },
    );
  }

  updateArea(int id, dynamic value) {
    return network(
      request: (request) => request.put(
        "/area/$id",
        data: value,
      ),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        return response.data;
      },
    );
  }

  addTableBulk(List listTable) {
    return network(
      request: (request) => request.post(
        "/room/list",
        data: {
          "data": listTable,
        },
      ),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        return response.data;
      },
    );
  }

  updateRoom(int id, Map<String, dynamic> value) {
    return network(
      request: (request) => request.put(
        "/room/${id}",
        data: value,
      ),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        return response.data;
      },
    );
  }

  completeTable(int orderId, int roomId, num serviceFee, {String? note}) {
    Map<String, dynamic> data = {
      "status_order": 4,
      "room_type": TableStatus.free.toValue(),
      "room_id": roomId,
      'service_fee': serviceFee
    };

    if (note != null) {
      data['note'] = note;
    }

    return network(
      request: (request) => request.put(
        "/order/${orderId}",
        data: data,
      ),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        return response.data;
      },
    );
  }

  cancelTable(int orderId, {String? note}) {
    Map<String, dynamic> data = {
      "status_order": 5,
    };

    if (note != null) {
      data['note'] = note;
    }

    return network(
      request: (request) => request.put(
        "/order/${orderId}",
        data: data,
      ),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        return response.data;
      },
    );
  }

  deleteRoom(int id) {
    return network(
      request: (request) => request.delete("/room/${id}"),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        return response.data;
      },
    );
  }

  fetchRoom(int id) {
    return network(
      request: (request) => request.get("/room/${id}"),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        return response.data['data'];
      },
    );
  }

  moveTableOrder(data, id) {
    return network(
      request: (request) => request.post(
        "/order/move/$id",
        data: data,
      ),
      handleFailure: (error) {
        throw error;
      },
      handleSuccess: (response) async {
        return response.data;
      },
    );
  }
}
