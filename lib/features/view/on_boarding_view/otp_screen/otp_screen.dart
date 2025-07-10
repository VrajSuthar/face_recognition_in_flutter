import 'package:eduwrx/features/view/on_boarding_view/otp_screen/bloc/otp_bloc.dart';
import 'package:eduwrx/features/view/on_boarding_view/otp_screen/bloc/otp_event.dart';
import 'package:eduwrx/features/view/on_boarding_view/otp_screen/widgets/otp_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class OtpVerifyScreen extends StatefulWidget {
  OtpVerifyScreen({super.key});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  OtpVerifyWidgets otpVerifyWidget = OtpVerifyWidgets();

  @override
  void initState() {
    super.initState();
    otpVerifyWidget.loadData();
    context.read<OtpVerifyBloc>().add(StartTimer());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SingleChildScrollView(
          child: SizedBox(
            height: 1.sh,
            width: 1.sw,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 0.2.sh),
                otpVerifyWidget.logoImg(),
                SizedBox(height: 16.h),
                otpVerifyWidget.userPhoneNumber(context),
                SizedBox(height: 60.h),
                otpVerifyWidget.pinInputField(context),
                Spacer(),
                otpVerifyWidget.bottomBtn(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
