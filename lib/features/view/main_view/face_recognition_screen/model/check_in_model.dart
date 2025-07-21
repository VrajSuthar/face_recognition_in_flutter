// To parse this JSON data, do
//
//     final checkInModel = checkInModelFromJson(jsonString);

import 'dart:convert';

CheckInModel checkInModelFromJson(String str) => CheckInModel.fromJson(json.decode(str));

String checkInModelToJson(CheckInModel data) => json.encode(data.toJson());

class CheckInModel {
  bool? success;
  dynamic errors;
  Data? data;

  CheckInModel({this.success, this.errors, this.data});

  factory CheckInModel.fromJson(Map<String, dynamic> json) => CheckInModel(success: json["success"], errors: json["errors"], data: json["data"] == null ? null : Data.fromJson(json["data"]));

  Map<String, dynamic> toJson() => {"success": success, "errors": errors, "data": data?.toJson()};
}

class Data {
  int? attendanceId;
  int? teacherId;
  DateTime? attendanceDate;
  String? checkInTime;
  dynamic checkOutTime;
  String? expectedCheckIn;
  String? expectedCheckOut;
  bool? isLate;
  dynamic isEarlyCheckout;
  dynamic workingHours;
  String? remarks;
  String? status;
  String? locationCheckIn;
  dynamic locationCheckOut;
  DateTime? createdAt;
  DateTime? updatedAt;

  Data({
    this.attendanceId,
    this.teacherId,
    this.attendanceDate,
    this.checkInTime,
    this.checkOutTime,
    this.expectedCheckIn,
    this.expectedCheckOut,
    this.isLate,
    this.isEarlyCheckout,
    this.workingHours,
    this.remarks,
    this.status,
    this.locationCheckIn,
    this.locationCheckOut,
    this.createdAt,
    this.updatedAt,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    attendanceId: json["attendance_id"],
    teacherId: json["teacher_id"],
    attendanceDate: json["attendance_date"] == null ? null : DateTime.parse(json["attendance_date"]),
    checkInTime: json["check_in_time"],
    checkOutTime: json["check_out_time"],
    expectedCheckIn: json["expected_check_in"],
    expectedCheckOut: json["expected_check_out"],
    isLate: json["is_late"],
    isEarlyCheckout: json["is_early_checkout"],
    workingHours: json["working_hours"],
    remarks: json["remarks"],
    status: json["status"],
    locationCheckIn: json["location_check_in"],
    locationCheckOut: json["location_check_out"],
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "attendance_id": attendanceId,
    "teacher_id": teacherId,
    "attendance_date": "${attendanceDate!.year.toString().padLeft(4, '0')}-${attendanceDate!.month.toString().padLeft(2, '0')}-${attendanceDate!.day.toString().padLeft(2, '0')}",
    "check_in_time": checkInTime,
    "check_out_time": checkOutTime,
    "expected_check_in": expectedCheckIn,
    "expected_check_out": expectedCheckOut,
    "is_late": isLate,
    "is_early_checkout": isEarlyCheckout,
    "working_hours": workingHours,
    "remarks": remarks,
    "status": status,
    "location_check_in": locationCheckIn,
    "location_check_out": locationCheckOut,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}
