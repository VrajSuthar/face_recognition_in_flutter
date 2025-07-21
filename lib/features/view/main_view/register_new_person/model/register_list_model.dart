// To parse this JSON data, do
//
//     final registerListModel = registerListModelFromJson(jsonString);

import 'dart:convert';

RegisterListModel registerListModelFromJson(String str) => RegisterListModel.fromJson(json.decode(str));

String registerListModelToJson(RegisterListModel data) => json.encode(data.toJson());

class RegisterListModel {
  bool? success;
  dynamic errors;
  Data? data;

  RegisterListModel({this.success, this.errors, this.data});

  factory RegisterListModel.fromJson(Map<String, dynamic> json) => RegisterListModel(success: json["success"], errors: json["errors"], data: json["data"] == null ? null : Data.fromJson(json["data"]));

  Map<String, dynamic> toJson() => {"success": success, "errors": errors, "data": data?.toJson()};
}

class Data {
  int? id;
  String? userType;
  int? referenceId;
  String? status;
  dynamic classId;
  dynamic division;

  Data({this.id, this.userType, this.referenceId, this.status, this.classId, this.division});

  factory Data.fromJson(Map<String, dynamic> json) =>
      Data(id: json["id"], userType: json["user_type"], referenceId: json["reference_id"], status: json["status"], classId: json["class_id"], division: json["division"]);

  Map<String, dynamic> toJson() => {"id": id, "user_type": userType, "reference_id": referenceId, "status": status, "class_id": classId, "division": division};
}
