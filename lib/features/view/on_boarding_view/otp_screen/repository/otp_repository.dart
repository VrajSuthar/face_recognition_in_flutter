import 'package:eduwrx/core/constants/app_api.dart';
import 'package:eduwrx/core/constants/global_variable.dart';
import 'package:eduwrx/core/network/api_client.dart';
import 'package:eduwrx/core/routes/route_name.dart';
import 'package:eduwrx/core/utils/toast_util.dart';
import 'package:eduwrx/features/view/on_boarding_view/otp_screen/bloc/otp_bloc.dart';
import 'package:eduwrx/features/view/on_boarding_view/otp_screen/bloc/otp_event.dart';
import 'package:eduwrx/features/view/on_boarding_view/otp_screen/model/otp_verify_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpRepository {
  Future<void> verify_otp(BuildContext context, String email, String otp) async {
    final bloc = context.read<OtpVerifyBloc>();
    try {
      bloc.add(OtpBtnSetLoading(isLoading: true));
      Map<String, String> data = {"email": email, "otp": otp.trim()};
      final response = await ApiClient().post(AppApi.verify_login_otp, data);

      if (response.containsKey('api_token') && response['api_token'] != null) {
        VerifyOtpModel model = VerifyOtpModel.fromJson(response);

        ToastUtil.showToast(context, "Welcome ${model.username}!", backgroundColor: Theme.of(context).primaryColor, textColor: Colors.white);

        Get.offAllNamed(RouteName.main_screen);

        SharedPreferences pref = await SharedPreferences.getInstance();
        pref.setInt(GlobalVariable.user_id_key, model.userId ?? 0);
        pref.setString(GlobalVariable.username_key, model.username ?? '');
        pref.setString(GlobalVariable.email_key, model.email ?? '');
        pref.setString(GlobalVariable.token_key, model.apiToken ?? '');
        pref.setString(GlobalVariable.role_name_key, model.roleName ?? '');
      } else {
        ToastUtil.showToast(context, "Invalid OTP. Please try again.", backgroundColor: Colors.red, textColor: Colors.white);
      }
    } catch (e) {
      ToastUtil.showToast(context, "Something went wrong. Please try again.", backgroundColor: Colors.red, textColor: Colors.white);
    } finally {
      bloc.add(OtpBtnSetLoading(isLoading: false));
    }
  }
}
