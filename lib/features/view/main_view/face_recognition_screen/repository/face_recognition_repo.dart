import 'dart:io';
import 'package:dio/dio.dart';
import 'package:eduwrx/core/constants/app_api.dart';
import 'package:eduwrx/core/network/api_client.dart';
import 'package:eduwrx/core/utils/toast_util.dart';
import 'package:eduwrx/features/view/main_view/face_recognition_screen/face_recognition_controller.dart';
import 'package:eduwrx/features/view/main_view/face_recognition_screen/model/check_in_model.dart';
import 'package:eduwrx/features/view/main_view/face_recognition_screen/model/search_model.dart';
import 'package:eduwrx/features/view/main_view/face_recognition_screen/model/teacher_model.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class FaceRecognitionRepo {
  /*============================ feacher FaceSearch ============================*/

  Future<void> fetchFaceSearch(BuildContext context) async {
    final controller = Get.find<FaceRecognitionController>();

    try {
      controller.isLoading.value = true;

      final response = await ApiClient().get(AppApi.search, sendHeader: true);
      SearchModel model = SearchModel.fromJson(response);

      if (model.data != null) {
        controller.listOfTeacherAndStudent
          ..clear()
          ..addAll(model.data!);
      }

      await controller.initAll();
    } catch (e) {
      print("❌ Error in fetchTeachers: $e");
      ToastUtil.showToast(context, "Error while processing attendance", backgroundColor: Colors.red, textColor: Colors.white);
      controller.isLoading.value = false;
      Get.back();
    }
  }
  /*============================ feacher teacher ============================*/

  // Future<void> fetchTeacher(int? teacher_id) async {
  //   final controller = Get.find<FaceRecognitionController>();
  //   try {
  //     final response = await ApiClient().get("${AppApi.teacher_detail_api}/$teacher_id", sendHeader: true);

  //     TeacherModel model = TeacherModel.fromJson(response);

  //     if (model.teacher != null) {
  //       controller.teacher_detail = model;
  //     }
  //   } catch (e) {
  //     print("Error fetching teacher deatisl");
  //   }
  // }

  /*============================ Check in ============================*/

  static Future<void> checkIn({required int teacherId, required String teacherName}) async {
    final controller = Get.find<FaceRecognitionController>();

    final now = DateTime.now();

    try {
      // ✅ Get location
      Position position = await Geolocator.getCurrentPosition(locationSettings: LocationSettings(accuracy: LocationAccuracy.high));

      // ✅ Prepare data with location
      final data = {
        'teacher_id': teacherId,
        'attendance_date': DateFormat('yyyy-MM-dd').format(now),
        'check_in_time': DateFormat('HH:mm:ss').format(now),
        'location_check_in': "${position.latitude.toStringAsFixed(6)}  ${position.longitude.toStringAsFixed(6)}",
      };

      final response = await ApiClient().post(AppApi.check_in, data, sendHeader: true);
      final res = response;

      if (res['success'] == true) {
        controller.recognizedName.value = "$teacherName has Checked In";
        Get.snackbar("Success", controller.recognizedName.value, backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.TOP);
      } else {
        final errors = res['errors'];
        String message = "Check-in failed.";

        if (errors is List && errors.isNotEmpty && errors[0]['error'] != null) {
          message = errors[0]['error'];
        }

        controller.recognizedName.value = "";

        // Get.snackbar(
        //   message.contains("already checked in") ? "Already Checked In" : "Error",
        //   message,
        //   backgroundColor: message.contains("already checked in") ? Colors.orange : Colors.red,
        //   colorText: Colors.white,
        //   snackPosition: SnackPosition.TOP,
        // );
      }
    } catch (e) {
      controller.recognizedName.value = "";
    }
  }

  /*============================ Check out ============================*/

  static Future<void> checkOut({required int teacherId, required String teacherName}) async {
    final controller = Get.find<FaceRecognitionController>();
    Position position = await Geolocator.getCurrentPosition(locationSettings: LocationSettings(accuracy: LocationAccuracy.high));
    final now = DateTime.now();
    final data = {
      'teacher_id': teacherId,
      'attendance_date': DateFormat('yyyy-MM-dd').format(now),
      'check_out_time': DateFormat('HH:mm:ss').format(now),
      'location_check_in': "${position.latitude.toStringAsFixed(6)}  ${position.longitude.toStringAsFixed(6)}",
    };

    try {
      final response = await ApiClient().post(AppApi.check_out, data, sendHeader: true);
      final res = response;

      if (res['success'] == true) {
        controller.recognizedName.value = "$teacherName has Checked Out";
        Get.snackbar("Success", controller.recognizedName.value, backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.TOP);
      } else {
        final errors = res['errors'];
        String message = "Check-out failed.";

        if (errors is List && errors.isNotEmpty && errors[0]['error'] != null) {
          message = errors[0]['error'];
        }

        controller.recognizedName.value = "";

        // Get.snackbar(
        //   message.contains("already checked out") ? "Already Checked Out" : "Error",
        //   message,
        //   backgroundColor: message.contains("already checked out") ? Colors.orange : Colors.red,
        //   colorText: Colors.white,
        //   snackPosition: SnackPosition.TOP,
        // );
      }
    } catch (e) {
      controller.recognizedName.value = "";
    }
  }
}
