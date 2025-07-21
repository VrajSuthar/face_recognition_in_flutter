import 'package:bloc/bloc.dart';
import 'package:eduwrx/core/constants/global_variable.dart';
import 'package:eduwrx/core/routes/route_name.dart';
import 'package:eduwrx/features/view/on_boarding_view/splash_screen/bloc/splash_event.dart';
import 'package:eduwrx/features/view/on_boarding_view/splash_screen/bloc/splash_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:shared_preferences/shared_preferences.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  /*============================ Inital ============================*/

  SplashBloc() : super(SplashInitialState()) {
    on<StartSplashTimer>(_startTime);
  }

  Future<void> _startTime(StartSplashTimer event, Emitter<SplashState> emit) async {
    Future.delayed(const Duration(seconds: 2), () async {
      SharedPreferences pref = await SharedPreferences.getInstance();

      final token = pref.getString(GlobalVariable.token_key);

      if (token == null) {
        Get.offNamed(RouteName.login_screen);
      } else {
        Get.offNamed(RouteName.main_screen);
      }
    });
  }
}
