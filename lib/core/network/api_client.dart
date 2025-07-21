import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eduwrx/core/constants/global_variable.dart';
import 'package:eduwrx/core/routes/route_name.dart';
import 'package:eduwrx/core/services/connectivity_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' as getx;

import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final String baseUrl;
  final Duration timeout;
  late final Dio _dio;
  ConnectivityService connection = getx.Get.find<ConnectivityService>();

  ApiClient({this.baseUrl = '', this.timeout = const Duration(seconds: 20)}) {
    _dio = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: timeout, receiveTimeout: timeout, contentType: 'application/json', responseType: ResponseType.json));
  }

  /*============================ Get Api ============================*/
  Future<dynamic> get(String path, {Map<String, String>? headers, Map<String, dynamic>? queryParameters, String contentType = 'application/json', bool? sendHeader = false}) async {
    try {
      connection.checkConnectivity();
      if (!connection.isConnected.value) return;

      SharedPreferences pref = await SharedPreferences.getInstance();
      var token = pref.getString(GlobalVariable.token_key);

      if (kDebugMode) {
        print("GET api url >>> $path");
        print("Token: $token");
      }

      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(
          headers: sendHeader == true ? {"Authorization": "Bearer $token"} : null,
          contentType: contentType,
          responseType: ResponseType.json,
          validateStatus: (status) => status! < 500, // Optional: Handle 401 manually
        ),
      );

      return _processResponse(response);
    } catch (e) {
      print("Error calling api ======> $path");
      print("Exception: $e");
    }
  }

  /*============================ Post api ============================*/

  Future<dynamic> post(String path, dynamic body, {Map<String, String>? headers, Map<String, dynamic>? queryParameters, String contentType = 'application/json', bool? sendHeader = false}) async {
    try {
      connection.checkConnectivity();
      if (!connection.isConnected.value) return;
      SharedPreferences pref = await SharedPreferences.getInstance();
      var token = pref.getString(GlobalVariable.token_key);
      await Future.delayed(const Duration(milliseconds: 100));

      if (kDebugMode) {
        print("POST api url >>> $path");
        if (body != null) {
          if (body is FormData) {
            print("📦 FormData Fields:");
            body.fields.forEach((f) => print("🔸 ${f.key}: ${f.value}"));
            print("📎 FormData Files:");
            body.files.forEach((f) => print("🖼️ ${f.key}: ${f.value.filename} (${f.value.length} bytes)"));
          } else {
            print("📦 JSON Body: $body");
          }
        }
        if (queryParameters != null) {
          print("📍 Query Parameters: $queryParameters");
        }
      }

      final response = await _dio.post(
        path,
        data: body,
        queryParameters: queryParameters,
        options: Options(
          headers: sendHeader == true ? {"Authorization": "Bearer $token"} : null,
          contentType: body is FormData ? null : contentType, // Let Dio auto-set for FormData
          responseType: ResponseType.json,
        ),
      );

      return _processResponse(response);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("❌ Exception in POST request to $path");
        print("📌 Error: $e");
        print("🧵 Stacktrace: $stackTrace");
      }
      rethrow;
    }
  }

  /*============================ Process response ============================*/

  dynamic _processResponse(Response response) {
    final statusCode = response.statusCode;
    final data = response.data;
    final encoder = JsonEncoder.withIndent('  ');
    print('Response status: $statusCode, data: ${encoder.convert(data)}');

    switch (statusCode) {
      case 200:
        return data;
      case 201:
        return data;
      // case 400:
      //   throw BadRequestException(_getErrorMessage(data));
      // case 401:
      //   throw UnAuthorizedException(_getErrorMessage(data), "", statusCode!);
      // case 403:
      //   throw UnAuthorizedException(_getErrorMessage(data));
      // case 404:
      //   throw NotFoundException(_getErrorMessage(data));
      // case 500:
      // default:
      //   throw FetchDataException('Server error: $statusCode');
    }
  }
}
