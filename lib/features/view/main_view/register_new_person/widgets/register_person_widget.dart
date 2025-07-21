import 'dart:io';

import 'package:eduwrx/core/common_widgets/common_button.dart';
import 'package:eduwrx/core/common_widgets/common_drop_down.dart';
import 'package:eduwrx/core/common_widgets/common_text.dart';
import 'package:eduwrx/core/common_widgets/common_text_form_field.dart';
import 'package:eduwrx/core/constants/app_image.dart';
import 'package:eduwrx/core/services/image_picker.dart';
import 'package:eduwrx/features/view/main_view/register_new_person/bloc/register_person_bloc.dart';
import 'package:eduwrx/features/view/main_view/register_new_person/model/teacher_list_model.dart';
import 'package:eduwrx/features/view/main_view/register_new_person/repository/register_person_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class RegisterPersonWidget {
  /*============================ Variable ============================*/

  TextEditingController teacher_ref_id_controller = TextEditingController();

  AppBar appbar(BuildContext context) {
    return AppBar(
      title: const Text(
        "Register",
        style: TextStyle(
          color: Colors.white, // ensure contrast
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 2,
    );
  }

  Widget body(BuildContext context) {
    return BlocBuilder<RegisterPersonBloc, RegisterPersonState>(
      builder: (context, state) {
        Widget imageWidget;

        if (state.filePath != null) {
          imageWidget = ClipOval(
            child: Image.file(state.filePath!, height: 100.h, width: 100.w, fit: BoxFit.cover),
          );
        } else {
          imageWidget = GestureDetector(
            onTap: () {
              profileBottomSheet(context);
            },
            child: Container(
              height: 100.h,
              width: 100.w,
              decoration: BoxDecoration(color: Colors.grey.shade800, shape: BoxShape.circle),
              child: Center(child: Icon(Icons.camera_alt_rounded, size: 32.sp)),
            ),
          );
        }

        return SingleChildScrollView(
          child: Container(
            height: 1.sh,
            width: 1.sw,
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image
                imageWidget,
                SizedBox(height: 16.h),

                // Register Form
                registerForm(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget registerForm(BuildContext context) {
    return BlocBuilder<RegisterPersonBloc, RegisterPersonState>(
      builder: (context, state) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CommonText("Type : ", style: Theme.of(context).textTheme.bodyLarge),
                CustomDropdown(
                  hintText: "Type",
                  // controller: createGameController.lookForController,
                  selectedValue: (value) {
                    if (value == "Teacher") {
                      RegisterPersonRepository().fetchTeacherList(context);
                      context.read<RegisterPersonBloc>().add(SelectedType(selectedType: value ?? 'Teacher'));
                    }
                  },
                  items: [
                    DropdownMenuEntry(
                      labelWidget: Text("Teacher", style: Theme.of(context).textTheme.bodyMedium),
                      value: "Teacher",
                      label: "Teacher",
                    ),
                    DropdownMenuEntry(
                      labelWidget: Text("Student", style: Theme.of(context).textTheme.bodyMedium),
                      value: "Student",
                      label: "Student",
                    ),
                  ],

                  onChanged: (value) {
                    print("Selected: $value");
                  },
                ),
              ],
            ),
            SizedBox(height: 16.h),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 70,
                  alignment: Alignment.topLeft,
                  child: CommonText("ID :", style: Theme.of(context).textTheme.bodyLarge),
                ),

                SizedBox(width: 16.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonTextFormField(
                        controller: teacher_ref_id_controller,
                        hintText: "Teacher's ID",
                        onChanged: (value) {
                          print("onChanged: $value");

                          context.read<RegisterPersonBloc>().add(SetTeacherListVisible(isVisible: true));

                          context.read<RegisterPersonBloc>().add(FilterTeacherList(query: value));
                        },
                      ),
                      SizedBox(height: 8),
                      state.teacherListVisible
                          ? Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white),
                              ),
                              child: state.teacherListLoading
                                  ? Center(child: CircularProgressIndicator())
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      padding: EdgeInsets.all(8),
                                      itemCount: state.filteredTeacherList?.length ?? 0,
                                      itemBuilder: (context, index) {
                                        final Datum data = state.filteredTeacherList![index];
                                        return Column(
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                teacher_ref_id_controller.text = data.label ?? '';
                                                context.read<RegisterPersonBloc>().add(SetTeacherListVisible(isVisible: false));
                                                context.read<RegisterPersonBloc>().add(SelectedTeacherId(selectedTeacherId: data.value ?? 0));
                                                print("teacher ref id selected. ${data.value}");
                                              },
                                              child: CommonText(data.label ?? '', style: Theme.of(context).textTheme.bodySmall),
                                            ),
                                            Divider(color: Theme.of(context).dividerColor),
                                          ],
                                        );
                                      },
                                    ),
                            )
                          : SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget bottomBtn(BuildContext context) {
    return BlocBuilder<RegisterPersonBloc, RegisterPersonState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 40),
          child: Commonbtn(
            text: "Register",
            isLoading: state.isLoading,
            onTap: () {
              RegisterPersonRepository().register(context: context, userType: 'teacher', referenceId: state.selectedTeacherId ?? 0, classId: 1, division: '', imageFile: state.filePath!);
            },
          ),
        );
      },
    );
  }

  void profileBottomSheet(BuildContext context) {
    Get.bottomSheet(
      BottomSheet(
        onClosing: () {},
        builder: (context) {
          return Container(
            height: 0.25.sh,
            width: 1.sw,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16.r), topRight: Radius.circular(16.r)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // CAMERA
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        ImagePickerHelper helper = ImagePickerHelper();
                        File? image = await helper.pickImageFromCamera(context);

                        if (image != null) {
                          context.read<RegisterPersonBloc>().add(UpdateProfileImage(image));
                          Get.back(); 
                        }
                      },
                      child: Container(
                        height: 100.h,
                        width: 100.w,
                        decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
                        child: Center(child: Icon(Icons.camera_alt_rounded, size: 40, color: Theme.of(context).primaryColor)),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    CommonText("Camera", style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),

                // GALLERY
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        ImagePickerHelper helper = ImagePickerHelper();
                        File? image = await helper.pickImageFromGallery(context);

                        if (image != null) {
                          context.read<RegisterPersonBloc>().add(UpdateProfileImage(image));
                          Get.back(); // close bottom sheet
                        }
                      },
                      child: Container(
                        height: 100.h,
                        width: 100.w,
                        decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
                        child: Center(child: Icon(Icons.photo, size: 40, color: Theme.of(context).primaryColor)),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    CommonText("Gallery", style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
