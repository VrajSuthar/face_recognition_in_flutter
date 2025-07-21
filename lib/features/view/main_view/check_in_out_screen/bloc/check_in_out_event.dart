part of 'check_in_out_bloc.dart';

@immutable
sealed class CheckInOutEvent {}

class SetCheckInOutLoading extends CheckInOutEvent {
  bool? isLoading;
  SetCheckInOutLoading({this.isLoading});
}

class TeacherAttendanceList extends CheckInOutEvent {
  List<Datum>? teacher_attendance_list;
  TeacherAttendanceList({this.teacher_attendance_list});
}

class SearchAttendance extends CheckInOutEvent {
  final String searchQuery;

  SearchAttendance(this.searchQuery);
}
