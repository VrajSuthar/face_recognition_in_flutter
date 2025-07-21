import 'dart:convert';
import 'dart:io';
import 'package:eduwrx/core/utils/toast_util.dart';
import 'package:eduwrx/features/view/main_view/register_new_person/model/register_list_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http_parser/http_parser.dart';
import 'package:dio/dio.dart' as dio;
import 'package:eduwrx/core/constants/app_api.dart';
import 'package:eduwrx/core/constants/global_variable.dart';
import 'package:eduwrx/core/network/api_client.dart';
import 'package:eduwrx/features/view/main_view/register_new_person/bloc/register_person_bloc.dart';
import 'package:eduwrx/features/view/main_view/register_new_person/model/teacher_list_model.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class RegisterPersonRepository {
  /// Fetch list of teachers from API and update Bloc
  Future<void> fetchTeacherList(BuildContext context) async {
    final bloc = context.read<RegisterPersonBloc>();
    try {
      bloc.add(SetTeacherListLoading(isLoading: true));

      final response = await ApiClient().get(AppApi.teachers_list, sendHeader: true);
      final model = TeachersListModel.fromJson(response);

      if (model.statusCode == 200) {
        bloc
          ..add(TeacherList(teacherList: model.data ?? []))
          ..add(SetTeacherListLoading(isLoading: false));
      } else {
        print("❌ Teacher list API error: ${model.message}");
        bloc.add(SetTeacherListLoading(isLoading: false));
      }
    } catch (e) {
      print("🚨 Exception in fetchTeacherList: $e");
      bloc.add(SetTeacherListLoading(isLoading: false));
    }
  }

  Future<String?> uploadPhoto(File? file) async {
    if (file == null) {
      print("❌ uploadPhoto received a null file.");
      return null;
    }

    try {
      print("📤 Uploading original file without compression: ${file.path}");
      return file.path;
    } catch (e) {
      print("❌ Upload error: $e");
      return null;
    }
  }

  Future<void> register({required BuildContext context, required String userType, required int referenceId, required int classId, required String division, required File imageFile}) async {
    final bloc = context.read<RegisterPersonBloc>();
    bloc.add(SetButtonLoading(isLoading: true));

    try {
      final filePath = imageFile.path;
      final fileName = path.basename(filePath);

      print("📸 Registering with image: $filePath");

      final imagePart = await dio.MultipartFile.fromFile(filePath, filename: fileName, contentType: MediaType('image', 'jpeg'));

      final formData = dio.FormData.fromMap({'user_type': userType, 'reference_id': referenceId, 'class_id': classId, 'division': division.isNotEmpty ? division : '', 'image': imagePart});

      final response = await ApiClient().post(AppApi.register, formData, sendHeader: true);
      final model = RegisterListModel.fromJson(response);

      if (model.success == true) {
        ToastUtil.showToast(context, "Successfully Registered", backgroundColor: Colors.green, textColor: Colors.white);

        context.read<RegisterPersonBloc>().add(ClearProfileImage());
        Get.back();
      } else {
        ToastUtil.showToast(context, "Something went wrong", backgroundColor: Colors.red);
      }
    } catch (e) {
      print("🚨 Face registration error: $e");
      ToastUtil.showToast(context, "Registration failed", backgroundColor: Colors.red);
    } finally {
      bloc.add(SetButtonLoading(isLoading: false));
    }
  }
}
