import 'package:eduwrx/features/view/main_view/main_screen/widgets/main_widgets.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  MainScreen({super.key});
  MainWidgets mainWidgets = MainWidgets();

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: mainWidgets.mainBody(), bottomNavigationBar: mainWidgets.bottomNavBar());
  }
}
