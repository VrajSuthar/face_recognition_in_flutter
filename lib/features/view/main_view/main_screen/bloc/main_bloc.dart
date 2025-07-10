import 'package:eduwrx/features/view/main_view/main_screen/bloc/main_event.dart';
import 'package:eduwrx/features/view/main_view/main_screen/bloc/main_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainBloc extends Bloc<MainEvent, MainState> {
  MainBloc() : super(MainState()) {
    on<OnIndexChange>((event, emit) {
      emit(state.copyWith(currentIndex: event.index));
    });
  }
}
