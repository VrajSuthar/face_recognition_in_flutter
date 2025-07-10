import 'package:eduwrx/core/common_widgets/common_button.dart';
import 'package:eduwrx/core/common_widgets/common_pin_input.dart';
import 'package:eduwrx/core/common_widgets/common_text.dart';
import 'package:eduwrx/core/constants/app_image.dart';
import 'package:eduwrx/core/routes/route_name.dart';
import 'package:eduwrx/core/utils/toast_util.dart';
import 'package:eduwrx/features/view/on_boarding_view/otp_screen/bloc/otp_bloc.dart';
import 'package:eduwrx/features/view/on_boarding_view/otp_screen/bloc/otp_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class OtpVerifyWidgets {
  /*---------------------------- Variable ----------------------------*/
  TextEditingController pinController = TextEditingController();
  String? email;

  /*============================ load data for argument ============================*/

  void loadData() {
    final args = Get.arguments;
    if (args != null) {
      email = args['email'];
    }
  }

  Widget logoImg() {
    return SizedBox(
      height: 0.12.sh,
      child: Image.asset(AppImages.login_logo, fit: BoxFit.fill),
    );
  }

  Widget userPhoneNumber(BuildContext context) {
    return CommonText(
      "We have sent an OTP to $email. \n Please enter it to continue",
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).primaryColor),
      textAlign: TextAlign.center,
    );
  }

  Widget pinInputField(BuildContext context) {
    return BlocBuilder<OtpVerifyBloc, OtpVerifyState>(
      builder: (context, state) {
        return Column(
          children: [
            CommonPinInput(
              length: 6,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Otp is required";
                }
                return null;
              },
              controller: pinController,
              backgroundColor: Colors.white,
              borderColor: Colors.grey,
              textColor: Colors.black,
              focusedBorderColor: Theme.of(context).primaryColor,
              onCompleted: (pin) {
                pinController.text = pin;
                // OtpVerifyRepository().verifyPhoneNumber(context, this);
              },
            ),
            SizedBox(height: 24.h),

            InkWell(
              onTap: () {
                if (!state.isResendEnabled) {
                  ToastUtil.showToast(context, "Please wait before resending OTP", backgroundColor: Theme.of(context).primaryColor, textColor: Colors.white);
                  return;
                }
                // OtpVerifyRepository().resendOtp(context, this);
              },
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: CommonText(
                  key: ValueKey(state.countdown),
                  state.countdown > 0 ? "Resend OTP in ${state.countdown}s" : "Resend Otp",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: state.isResendEnabled ? Theme.of(context).primaryColor : Colors.grey),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget bottomBtn(BuildContext context) {   
    return BlocBuilder<OtpVerifyBloc, OtpVerifyState>(
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.only(left: 10.w, right: 10.w, bottom: 40.h),
          child: Commonbtn(
            text: "Verify",
            // isLoading: state.isLoading,
            onTap: () {
              Get.toNamed(RouteName.main_screen);
              // OtpVerifyRepository().verifyPhoneNumber(context, this);
            },
          ),
        );
      },
    );
  }

  bool validateForm(BuildContext context) {
    if (pinController.text.trim().isEmpty) {
      ToastUtil.showToast(context, "Otp Is Required", backgroundColor: Theme.of(context).primaryColor, textColor: Colors.white);
      return false;
    }
    return true;
  }
}
