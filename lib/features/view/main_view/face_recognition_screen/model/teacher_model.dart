// To parse this JSON data, do
//
//     final teacherModel = teacherModelFromJson(jsonString);

import 'dart:convert';

TeacherModel teacherModelFromJson(String str) => TeacherModel.fromJson(json.decode(str));

String teacherModelToJson(TeacherModel data) => json.encode(data.toJson());

class TeacherModel {
  Teacher? teacher;
  UserLogin? userLogin;
  dynamic address;

  TeacherModel({this.teacher, this.userLogin, this.address});

  factory TeacherModel.fromJson(Map<String, dynamic> json) => TeacherModel(
    teacher: json["teacher"] == null ? null : Teacher.fromJson(json["teacher"]),
    userLogin: json["user_login"] == null ? null : UserLogin.fromJson(json["user_login"]),
    address: json["address"],
  );

  Map<String, dynamic> toJson() => {"teacher": teacher?.toJson(), "user_login": userLogin?.toJson(), "address": address};
}

class Teacher {
  int? teacherId;
  String? employeeId;
  int? organizationId;
  int? userId;
  String? firstName;
  String? middleName;
  String? lastName;
  DateTime? dateOfBirth;
  String? gender;
  String? email;
  String? phoneNumber;
  dynamic addressId;
  String? aadhaarNumber;
  DateTime? joinDate;
  String? status;
  int? reportedTo;
  DateTime? createdAt;
  DateTime? updatedAt;

  Teacher({
    this.teacherId,
    this.employeeId,
    this.organizationId,
    this.userId,
    this.firstName,
    this.middleName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
    this.email,
    this.phoneNumber,
    this.addressId,
    this.aadhaarNumber,
    this.joinDate,
    this.status,
    this.reportedTo,
    this.createdAt,
    this.updatedAt,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) => Teacher(
    teacherId: json["teacher_id"],
    employeeId: json["employee_id"],
    organizationId: json["organization_id"],
    userId: json["user_id"],
    firstName: json["first_name"],
    middleName: json["middle_name"],
    lastName: json["last_name"],
    dateOfBirth: json["date_of_birth"] == null ? null : DateTime.parse(json["date_of_birth"]),
    gender: json["gender"],
    email: json["email"],
    phoneNumber: json["phone_number"],
    addressId: json["address_id"],
    aadhaarNumber: json["aadhaar_number"],
    joinDate: json["join_date"] == null ? null : DateTime.parse(json["join_date"]),
    status: json["status"],
    reportedTo: json["reported_to"],
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "teacher_id": teacherId,
    "employee_id": employeeId,
    "organization_id": organizationId,
    "user_id": userId,
    "first_name": firstName,
    "middle_name": middleName,
    "last_name": lastName,
    "date_of_birth": dateOfBirth?.toIso8601String(),
    "gender": gender,
    "email": email,
    "phone_number": phoneNumber,
    "address_id": addressId,
    "aadhaar_number": aadhaarNumber,
    "join_date": joinDate?.toIso8601String(),
    "status": status,
    "reported_to": reportedTo,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}

class UserLogin {
  int? userId;
  String? username;
  String? passwordHash;
  String? salt;
  String? email;
  int? roleId;
  DateTime? lastLogin;
  String? status;
  DateTime? createdAt;
  DateTime? updatedAt;

  UserLogin({this.userId, this.username, this.passwordHash, this.salt, this.email, this.roleId, this.lastLogin, this.status, this.createdAt, this.updatedAt});

  factory UserLogin.fromJson(Map<String, dynamic> json) => UserLogin(
    userId: json["user_id"],
    username: json["username"],
    passwordHash: json["password_hash"],
    salt: json["salt"],
    email: json["email"],
    roleId: json["role_id"],
    lastLogin: json["last_login"] == null ? null : DateTime.parse(json["last_login"]),
    status: json["status"],
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "user_id": userId,
    "username": username,
    "password_hash": passwordHash,
    "salt": salt,
    "email": email,
    "role_id": roleId,
    "last_login": lastLogin?.toIso8601String(),
    "status": status,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}
