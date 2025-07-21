import 'package:eduwrx/features/view/main_view/check_in_out_screen/model/teacher_attendance_model.dart';
import 'package:equatable/equatable.dart';

class CheckInOutState extends Equatable {
  final bool? isLoading;
  final List<Datum>? teacherAttendanceList;
  final List<Datum>? filteredAttendanceList;

  const CheckInOutState({this.teacherAttendanceList, this.filteredAttendanceList, this.isLoading});

  CheckInOutState copyWith({List<Datum>? teacherAttendanceList, List<Datum>? filteredAttendanceList, bool? isLoading}) {
    return CheckInOutState(
      teacherAttendanceList: teacherAttendanceList ?? this.teacherAttendanceList,
      filteredAttendanceList: filteredAttendanceList ?? this.filteredAttendanceList,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [teacherAttendanceList, filteredAttendanceList, isLoading];
}
