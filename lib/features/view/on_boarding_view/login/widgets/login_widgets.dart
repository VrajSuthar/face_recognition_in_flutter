import 'package:eduwrx/core/common_widgets/common_button.dart';
import 'package:eduwrx/core/common_widgets/common_text_form_field.dart';
import 'package:eduwrx/core/constants/app_image.dart';
import 'package:eduwrx/core/routes/route_name.dart';
import 'package:eduwrx/core/utils/toast_util.dart';
import 'package:eduwrx/features/view/on_boarding_view/login/bloc/login_bloc.dart';
import 'package:eduwrx/features/view/on_boarding_view/login/repository/login_repository.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class LoginWidgets {
  /*============================ Variable ============================*/
  GlobalKey<FormState> signinFormKey = GlobalKey<FormState>();
  var autoValidate = AutovalidateMode.disabled;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Widget logoImg() {
    return SizedBox(
      height: 0.2.sh,
      child: Image.asset(AppImages.login_logo, fit: BoxFit.fill),
    );
  }

  Widget signUpForm(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Form(
            key: signinFormKey,
            autovalidateMode: autoValidate,
            child: Column(
              children: [
                CommonTextFormField(
                  prefixIcon: Icon(Icons.email, color: Theme.of(context).iconTheme.color),
                  onChanged: (value) {
                    final cursorPos = emailController.selection.baseOffset;
                    emailController.text = value;
                    emailController.selection = TextSelection.fromPosition(TextPosition(offset: cursorPos));
                  },
                  validator: (value) {
                    value = emailController.text;
                    if (value.isEmpty || value == null) {
                      return "Email is required";
                    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                      return "Please enter a valid email address";
                    }
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                  controller: emailController,
                  hintText: "Email Address",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14.sp, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget bottomBtn(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Commonbtn(
                text: "Login",
                isLoading: state.isloading,
                onTap: () {
                  if (!validateForm(context)) return;
                  LoginRepository().login(context, emailController.text);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  bool validateForm(BuildContext context) {
    if (!signinFormKey.currentState!.validate()) {
      autoValidate = AutovalidateMode.onUserInteraction;

      if (emailController.text.isEmpty) {
        ToastUtil.showToast(context, "Email Address Is Required", backgroundColor: Theme.of(context).primaryColor, textColor: Colors.white);
      } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(emailController.text)) {
        ToastUtil.showToast(context, "Please Enter A Valid Email Address", backgroundColor: Theme.of(context).primaryColor, textColor: Colors.white);
      } else if (passwordController.text.isEmpty) {
        ToastUtil.showToast(context, "Password Is Required", backgroundColor: Theme.of(context).primaryColor, textColor: Colors.white);
      }

      return false;
    }

    return true;
  }
}
