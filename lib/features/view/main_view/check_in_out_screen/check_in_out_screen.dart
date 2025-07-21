import 'package:eduwrx/features/view/main_view/check_in_out_screen/repository/check_in_out_repository.dart';
import 'package:eduwrx/features/view/main_view/check_in_out_screen/widgets/check_in_out_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CheckInOutScreen extends StatefulWidget {
  CheckInOutScreen({super.key});

  @override
  State<CheckInOutScreen> createState() => _CheckInOutScreenState();
}

class _CheckInOutScreenState extends State<CheckInOutScreen> {
  CheckInOutWidgets checkInOutWidgets = CheckInOutWidgets();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CheckInOutRepository().fetchTeacherAttendance(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
      },
      child: Scaffold(body: checkInOutWidgets.body(context)),
    );
  }
}
