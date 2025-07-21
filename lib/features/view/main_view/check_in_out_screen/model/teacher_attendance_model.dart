// To parse this JSON data, do
//
//     final teacherAttendanceModel = teacherAttendanceModelFromJson(jsonString);

import 'dart:convert';

TeacherAttendanceModel teacherAttendanceModelFromJson(String str) => TeacherAttendanceModel.fromJson(json.decode(str));

String teacherAttendanceModelToJson(TeacherAttendanceModel data) => json.encode(data.toJson());

class TeacherAttendanceModel {
  List<Datum>? data;
  Payload? payload;

  TeacherAttendanceModel({this.data, this.payload});

  factory TeacherAttendanceModel.fromJson(Map<String, dynamic> json) => TeacherAttendanceModel(
    data: json["data"] == null ? [] : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
    payload: json["payload"] == null ? null : Payload.fromJson(json["payload"]),
  );

  Map<String, dynamic> toJson() => {"data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())), "payload": payload?.toJson()};
}

class Datum {
  int? attendanceId;
  int? teacherId;
  String? teacherName;
  DateTime? attendanceDate;
  String? checkInTime;
  String? checkOutTime;
  String? expectedCheckIn;
  String? expectedCheckOut;
  bool? isLate;
  bool? isEarlyCheckout;
  String? workingHours;
  String? remarks;
  String? status;
  String? locationCheckIn;
  dynamic locationCheckOut;
  DateTime? createdAt;
  DateTime? updatedAt;

  Datum({
    this.attendanceId,
    this.teacherId,
    this.teacherName,
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

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    attendanceId: json["attendance_id"],
    teacherId: json["teacher_id"],
    teacherName: json["teacher_name"],
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
    "teacher_name": teacherName,
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

class Payload {
  Pagination? pagination;

  Payload({this.pagination});

  factory Payload.fromJson(Map<String, dynamic> json) => Payload(pagination: json["pagination"] == null ? null : Pagination.fromJson(json["pagination"]));

  Map<String, dynamic> toJson() => {"pagination": pagination?.toJson()};
}

class Pagination {
  int? page;
  String? firstPageUrl;
  int? from;
  int? lastPage;
  List<Link>? links;
  String? nextPageUrl;
  int? itemsPerPage;
  dynamic prevPageUrl;
  int? to;
  int? total;

  Pagination({this.page, this.firstPageUrl, this.from, this.lastPage, this.links, this.nextPageUrl, this.itemsPerPage, this.prevPageUrl, this.to, this.total});

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
    page: json["page"],
    firstPageUrl: json["first_page_url"],
    from: json["from_"],
    lastPage: json["last_page"],
    links: json["links"] == null ? [] : List<Link>.from(json["links"]!.map((x) => Link.fromJson(x))),
    nextPageUrl: json["next_page_url"],
    itemsPerPage: json["items_per_page"],
    prevPageUrl: json["prev_page_url"],
    to: json["to"],
    total: json["total"],
  );

  Map<String, dynamic> toJson() => {
    "page": page,
    "first_page_url": firstPageUrl,
    "from_": from,
    "last_page": lastPage,
    "links": links == null ? [] : List<dynamic>.from(links!.map((x) => x.toJson())),
    "next_page_url": nextPageUrl,
    "items_per_page": itemsPerPage,
    "prev_page_url": prevPageUrl,
    "to": to,
    "total": total,
  };
}

class Link {
  String? url;
  dynamic label;
  bool? active;
  int? page;

  Link({this.url, this.label, this.active, this.page});

  factory Link.fromJson(Map<String, dynamic> json) => Link(url: json["url"], label: json["label"], active: json["active"], page: json["page"]);

  Map<String, dynamic> toJson() => {"url": url, "label": label, "active": active, "page": page};
}
