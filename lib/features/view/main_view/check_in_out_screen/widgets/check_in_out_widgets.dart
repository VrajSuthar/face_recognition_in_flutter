import 'package:eduwrx/core/common_widgets/common_app_bar_for_main.dart';
import 'package:eduwrx/core/common_widgets/common_text.dart';
import 'package:eduwrx/core/common_widgets/common_text_form_field.dart';
import 'package:eduwrx/features/view/main_view/check_in_out_screen/bloc/check_in_out_bloc.dart';
import 'package:eduwrx/features/view/main_view/check_in_out_screen/bloc/check_in_out_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CheckInOutWidgets {
  TextEditingController textSearchController = TextEditingController();

  /*============================ App Bar ============================*/

  Widget appBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: CommonAppBarForMain(),
    );
  }

  /*============================ body ============================*/

  Widget body(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [appBar(), SizedBox(height: 16), list_of_attendance(context)]);
  }

  Widget list_of_attendance(BuildContext context) {
    return SingleChildScrollView(
      child: BlocBuilder<CheckInOutBloc, CheckInOutState>(
        builder: (context, state) {
          if (state.isLoading == true) {
            return Center(child: CircularProgressIndicator());
          }

          final list = state.filteredAttendanceList ?? state.teacherAttendanceList ?? [];

          if (list.isEmpty) {
            return Center(child: Text("No attendance records found."));
          }

          return Column(
            children: [
              Text("Teacher", style: Theme.of(context).textTheme.bodyLarge),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.only(left: 16.w, right: 16.w),
                child: CommonTextFormField(
                  hintStyle: Theme.of(context).textTheme.bodyMedium,
                  hintText: "Search Teacher",
                  controller: textSearchController,
                  onChanged: (value) {
                    context.read<CheckInOutBloc>().add(SearchAttendance(value));
                  },
                ),
              ),
              SizedBox(height: 16.h),
              ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.all(0),
                physics: NeverScrollableScrollPhysics(),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final data = list[index];
                  return Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 10), child: commonBox(context, data.teacherName ?? '', data.checkInTime ?? 'N/A', data.checkOutTime ?? 'N/A'));
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget commonBox(BuildContext context, String teacherName, String checkInTime, String checkOutTime) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(10.r)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CommonText(teacherName, style: Theme.of(context).textTheme.bodyMedium),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CommonText("In : $checkInTime", style: Theme.of(context).textTheme.bodyMedium),
              CommonText("Out : $checkOutTime", style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}
