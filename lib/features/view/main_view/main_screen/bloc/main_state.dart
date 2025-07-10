
import 'package:eduwrx/core/constants/app_image.dart';
import 'package:eduwrx/features/view/main_view/check_in_out_screen/check_in_out_screen.dart';
import 'package:eduwrx/features/view/main_view/home_screen/home_screen.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';


class MainState extends Equatable {
  final List<String> labels;
  final List<String> selectedIcons;
  final List<String> unselectedIcons;
  final List<Widget> buildScreen;
  final int currentIndex;

  MainState({List<String>? labels, List<String>? selectedIcons, List<String>? unselectedIcons, int? currentIndex, List<Widget>? buildScreen})
    : labels = labels ?? ["Home" , "Check In"],
      selectedIcons = selectedIcons ?? [AppImages.clubHouseon, AppImages.scoreCardon, ],
      unselectedIcons = unselectedIcons ?? [AppImages.clubHouse, AppImages.scoreCard, ],
      buildScreen = buildScreen ?? [HomeScreen(), CheckInOutScreen(),],
      currentIndex = currentIndex ?? 0;

  MainState copyWith({List<String>? labels, List<String>? selectedIcons, List<String>? unselectedIcons, int? currentIndex, List<Widget>? buildScreen}) {
    return MainState(
      labels: labels ?? this.labels,
      selectedIcons: selectedIcons ?? this.selectedIcons,
      unselectedIcons: unselectedIcons ?? this.unselectedIcons,
      currentIndex: currentIndex ?? this.currentIndex,
      buildScreen: buildScreen ?? this.buildScreen,
    );
  }

  @override
  List<Object> get props => [labels, selectedIcons, unselectedIcons, currentIndex, buildScreen];
}

final class MainInitial extends MainState {
  MainInitial({List<String>? labels, List<String>? selectedIcons, List<String>? unselectedIcons, int? currentIndex, List<Widget>? buildScreen})
    : super(labels: labels, selectedIcons: selectedIcons, unselectedIcons: unselectedIcons, currentIndex: currentIndex ?? 0, buildScreen: buildScreen);
}
