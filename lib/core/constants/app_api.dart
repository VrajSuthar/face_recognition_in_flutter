class AppApi {
  /*============================ Base URL ============================*/

  /*============================ Live Url ============================*/

  static const String base_url = "http://35.154.203.71:8001/api";
  /*============================ Local hoast ============================*/

  // static const String base_url = "http://192.168.1.47:8000/api";
  static const String image_user = "$base_url/face/image/teacher/";
  /*============================ App api ============================*/

  static const String send_login_otp = "$base_url/users/send-login-otp";
  static const String verify_login_otp = "$base_url/users/verify-login-otp";
  static const String teachers_list = "$base_url/teachers/list/options";
  static const String register = "$base_url/face/register";
  static const String search = "$base_url/face/search";
  static const String teacher_detail_api = "$base_url/teachers";
  static const String check_in = "$base_url/teacher-attendance/check-in";
  static const String check_out = "$base_url/teacher-attendance/check-out";
  static const String teacher_attendance = "$base_url/teacher-attendance";
}
