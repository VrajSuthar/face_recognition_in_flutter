import 'package:eduwrx/features/view/on_boarding_view/login/widgets/login_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  LoginWidgets loginWidgets = LoginWidgets();

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
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                loginWidgets.logoImg(),
                SizedBox(height: 0.1.sh),
                loginWidgets.signUpForm(context),
                SizedBox(height: 0.1.sh),
                loginWidgets.bottomBtn(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
