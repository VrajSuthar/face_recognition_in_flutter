import 'package:eduwrx/core/common_widgets/common_bottom_nav_bar.dart';
import 'package:eduwrx/features/view/main_view/main_screen/bloc/main_bloc.dart';
import 'package:eduwrx/features/view/main_view/main_screen/bloc/main_event.dart';
import 'package:eduwrx/features/view/main_view/main_screen/bloc/main_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';


class MainWidgets {
  Widget mainBody() {
    return BlocBuilder<MainBloc, MainState>(
      builder: (context, state) {
        return state.buildScreen[state.currentIndex];
      },
    );
  }

  Widget bottomNavBar() {
    return BlocBuilder<MainBloc, MainState>(
      builder: (context, state) {
        return CustomBottomNavBar(
          currentIndex: state.currentIndex,
          onTap: (index) {
            context.read<MainBloc>().add(OnIndexChange(index));
          },
          labels: state.labels,
          selectedIcons: state.selectedIcons,
          unselectedIcons: state.unselectedIcons,
        );
      },
    );
  }
}
