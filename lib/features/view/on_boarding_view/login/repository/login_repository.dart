import 'package:eduwrx/core/constants/app_api.dart';
import 'package:eduwrx/core/network/api_client.dart';
import 'package:eduwrx/core/routes/route_name.dart';
import 'package:eduwrx/core/utils/toast_util.dart';
import 'package:eduwrx/features/view/on_boarding_view/login/bloc/login_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class LoginRepository {
  Future<void> login(BuildContext context, String email) async {
    final bloc = context.read<LoginBloc>();
    try {
      bloc.add(LoginBtnSetLoading(isloading: true));
      Map<String, String> data = {"email": email};
      final response = await ApiClient().post(AppApi.send_login_otp, data);
      ToastUtil.showToast(context, response['message'], backgroundColor: Theme.of(context).primaryColor, textColor: Colors.white);
      Get.toNamed(RouteName.otp_verify_screen, arguments: {"useremail": email});
      bloc.add(LoginBtnSetLoading(isloading: false));
    } catch (e) {
    } finally {
      bloc.add(LoginBtnSetLoading(isloading: false));
    }
  }
}
