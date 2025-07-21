import 'package:bloc/bloc.dart';
import 'package:eduwrx/features/view/main_view/check_in_out_screen/bloc/check_in_out_state.dart';
import 'package:eduwrx/features/view/main_view/check_in_out_screen/model/teacher_attendance_model.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'check_in_out_event.dart';

class CheckInOutBloc extends Bloc<CheckInOutEvent, CheckInOutState> {
  CheckInOutBloc() : super(CheckInOutState()) {
    on<SetCheckInOutLoading>((event, emit) {
      emit(state.copyWith(isLoading: event.isLoading));
    });
    on<TeacherAttendanceList>((event, emit) {
      emit(state.copyWith(teacherAttendanceList: event.teacher_attendance_list));
    });
    on<SearchAttendance>((event, emit) {
      final query = event.searchQuery.toLowerCase();
      final allData = state.teacherAttendanceList ?? [];

      final filtered = allData.where((datum) {
        final name = datum.teacherName?.toLowerCase() ?? '';
        return name.contains(query);
      }).toList();

      emit(state.copyWith(filteredAttendanceList: filtered));
    });
  }
}
