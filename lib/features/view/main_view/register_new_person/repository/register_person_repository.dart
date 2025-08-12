import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:image/image.dart' as img;
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



  Future<File> uploadPhoto(File? imageFile) async {
    if (imageFile == null) {
      throw Exception("Image file is null");
    }

    // Read and decode
    final bytes = await imageFile.readAsBytes();
    final original = img.decodeImage(bytes);
    if (original == null) {
      throw Exception("Failed to decode image");
    }

    // Target size
    const targetW = 800;
    const targetH = 600;

    // Scale factor to fit within target size
    final scale = (original.width / targetW > original.height / targetH) ? targetW / original.width : targetH / original.height;

    final newWidth = (original.width * scale).round();
    final newHeight = (original.height * scale).round();

    // Resize (maintain aspect ratio)
    final resized = img.copyResize(original, width: newWidth, height: newHeight, interpolation: img.Interpolation.cubic);

    // Create a black canvas
    img.Image canvas = img.Image(width: targetW, height: targetH);
    canvas = img.fill(canvas, color: img.ColorRgb8(0, 0, 0)); // black background

    // Place the resized image in the center manually
    final x = (canvas.width - resized.width) ~/ 2;
    final y = (canvas.height - resized.height) ~/ 2;

    for (int yy = 0; yy < resized.height; yy++) {
      for (int xx = 0; xx < resized.width; xx++) {
        final pixel = resized.getPixel(xx, yy);
        canvas.setPixel(x + xx, y + yy, pixel);
      }
    }

    // Encode and save
    final encoded = Uint8List.fromList(img.encodeJpg(canvas, quality: 90));
    final tempFile = File('${imageFile.parent.path}/resized_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(encoded);

    return tempFile;
  }

  Future<void> register({required BuildContext context, required String userType, required int referenceId, required int classId, required String division, required File imageFile}) async {
    final bloc = context.read<RegisterPersonBloc>();
    bloc.add(SetButtonLoading(isLoading: true));

    try {
      // 1️⃣ Resize & pad image before upload
      final resizedFile = await uploadPhoto(imageFile);

      final filePath = resizedFile.path;
      final fileName = path.basename(filePath);

      print("📸 Registering with resized image: $filePath");

      // 2️⃣ Create MultipartFile from resized file
      final imagePart = await dio.MultipartFile.fromFile(filePath, filename: fileName, contentType: MediaType('image', 'jpeg'));

      // 3️⃣ Create FormData
      final formData = dio.FormData.fromMap({'user_type': userType, 'reference_id': referenceId, 'class_id': classId, 'division': division.isNotEmpty ? division : '', 'image': imagePart});

      // 4️⃣ Send request
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
