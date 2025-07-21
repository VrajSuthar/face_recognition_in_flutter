// To parse this JSON data, do
//
//     final teachersListModel = teachersListModelFromJson(jsonString);

import 'dart:convert';

TeachersListModel teachersListModelFromJson(String str) => TeachersListModel.fromJson(json.decode(str));

String teachersListModelToJson(TeachersListModel data) => json.encode(data.toJson());

class TeachersListModel {
  int? statusCode;
  int? code;
  String? message;
  dynamic errorMessage;
  List<Datum>? data;

  TeachersListModel({this.statusCode, this.code, this.message, this.errorMessage, this.data});

  factory TeachersListModel.fromJson(Map<String, dynamic> json) => TeachersListModel(
    statusCode: json["status_code"],
    code: json["code"],
    message: json["message"],
    errorMessage: json["errorMessage"],
    data: json["data"] == null ? [] : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "code": code,
    "message": message,
    "errorMessage": errorMessage,
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
  };
}

class Datum {
  String? label;
  int? value;

  Datum({this.label, this.value});

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(label: json["label"], value: json["value"]);

  Map<String, dynamic> toJson() => {"label": label, "value": value};
}
