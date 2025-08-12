import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:eduwrx/features/view/main_view/register_new_person/model/teacher_list_model.dart';
import 'package:eduwrx/features/view/main_view/register_new_person/repository/register_person_repository.dart';
import 'package:equatable/equatable.dart';

part 'register_person_event.dart';
part 'register_person_state.dart';

class RegisterPersonBloc extends Bloc<RegisterPersonEvent, RegisterPersonState> {
  RegisterPersonBloc() : super(RegisterPersonState()) {
    /*============================ Upload profile photo ============================*/

    on<UpdateProfileImage>((event, emit) async {
      emit(state.copyWith(filePath: event.file, filePathHasChanged: true, isLoading: true));

      final newUrl = await RegisterPersonRepository().uploadPhoto(event.file);

      if (newUrl != null) {
        emit(state.copyWith(profileImageUrl: newUrl.toString(), isLoading: false));
      } else {
        emit(state.copyWith(isLoading: false));
      }
    });

    /*============================ button loading ============================*/

    on<SetButtonLoading>((event, emit) {
      emit(state.copyWith(isLoading: event.isLoading));
    });

    /*============================ set teacher list loading ============================*/

    on<SetTeacherListLoading>((event, emit) {
      emit(state.copyWith(teacherListLoading: event.isLoading));
    });

    /*============================ set visible teacher list ============================*/
    on<SetTeacherListVisible>((event, emit) {
      emit(state.copyWith(teacherListVisible: event.isVisible));
    });

    /*============================ load teacher list ============================*/
    on<TeacherList>((event, emit) {
      emit(state.copyWith(teacherList: event.teacherList, filteredTeacherList: event.teacherList));
    });

    /*============================ filter teacher list  ============================*/
    on<FilterTeacherList>((event, emit) {
      final filtered = state.teacherList?.where((teacher) => teacher.label?.toLowerCase().contains(event.query.toLowerCase()) ?? false).toList() ?? [];
      emit(state.copyWith(filteredTeacherList: filtered));
    });

    /*============================ selcted type ============================*/
    on<SelectedType>((event, emit) {
      emit(state.copyWith(selectedType: event.selectedType));
    });

    /*============================ teacher selcted id ============================*/
    on<SelectedTeacherId>((event, emit) {
      emit(state.copyWith(selectedTeacherId: event.selectedTeacherId));
    });

    on<ClearProfileImage>((event, emit) {
      emit(state.copyWith(filePath: null, filePathHasChanged: true));
    });
  }
}
