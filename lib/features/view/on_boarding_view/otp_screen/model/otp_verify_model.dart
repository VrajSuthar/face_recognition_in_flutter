// To parse this JSON data, do
//
//     final verifyOtpModel = verifyOtpModelFromJson(jsonString);

import 'dart:convert';

VerifyOtpModel verifyOtpModelFromJson(String str) => VerifyOtpModel.fromJson(json.decode(str));

String verifyOtpModelToJson(VerifyOtpModel data) => json.encode(data.toJson());

class VerifyOtpModel {
  int? userId;
  String? username;
  String? email;
  String? apiToken;
  String? roleName;

  VerifyOtpModel({this.userId, this.username, this.email, this.apiToken, this.roleName});

  factory VerifyOtpModel.fromJson(Map<String, dynamic> json) =>
      VerifyOtpModel(userId: json["user_id"], username: json["username"], email: json["email"], apiToken: json["api_token"], roleName: json["role_name"]);

  Map<String, dynamic> toJson() => {"user_id": userId, "username": username, "email": email, "api_token": apiToken, "role_name": roleName};
}
