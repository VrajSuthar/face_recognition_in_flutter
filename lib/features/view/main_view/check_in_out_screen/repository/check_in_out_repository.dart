import 'package:eduwrx/core/constants/app_api.dart';
import 'package:eduwrx/core/network/api_client.dart';
import 'package:eduwrx/features/view/main_view/check_in_out_screen/bloc/check_in_out_bloc.dart';
import 'package:eduwrx/features/view/main_view/check_in_out_screen/model/teacher_attendance_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CheckInOutRepository {
  List<Datum> _removeDuplicates(List<Datum> data) {
    final seen = <int>{};
    return data.where((datum) {
      final id = datum.teacherId; // Replace with the actual unique field
      if (id == null || seen.contains(id)) return false;
      seen.add(id);
      return true;
    }).toList();
  }

  Future<void> fetchTeacherAttendance(BuildContext context) async {
    final bloc = context.read<CheckInOutBloc>();
    try {
      bloc.add(SetCheckInOutLoading(isLoading: true));
      final response = await ApiClient().get(AppApi.teacher_attendance, sendHeader: true);

      TeacherAttendanceModel model = TeacherAttendanceModel.fromJson(response);

      if (model.data != null) {
        final uniqueList = _removeDuplicates(model.data!);
        bloc.add(TeacherAttendanceList(teacher_attendance_list: uniqueList));
      }
    } catch (e) {
      print("Error fetching teacher attendance list ======> $e");
    } finally {
      bloc.add(SetCheckInOutLoading(isLoading: false));
    }
  }
}
