import 'package:eduwrx/features/view/main_view/register_new_person/bloc/register_person_bloc.dart';
import 'package:eduwrx/features/view/main_view/register_new_person/widgets/register_person_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterPersonScreen extends StatelessWidget {
  RegisterPersonScreen({super.key});

  RegisterPersonWidget registerPersonWidget = RegisterPersonWidget();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
        context.read<RegisterPersonBloc>().add(SetTeacherListVisible(isVisible: false));
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        bottomNavigationBar: registerPersonWidget.bottomBtn(context),
        appBar: registerPersonWidget.appbar(context),
        body: registerPersonWidget.body(context),
      ),
    );
  }
}
