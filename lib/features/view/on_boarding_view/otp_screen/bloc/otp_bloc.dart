import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:eduwrx/features/view/on_boarding_view/otp_screen/bloc/otp_event.dart';
import 'package:eduwrx/features/view/on_boarding_view/otp_screen/bloc/otp_state.dart';
import 'package:equatable/equatable.dart';

class OtpVerifyBloc extends Bloc<OtpVerifyEvent, OtpVerifyState> {
  Timer? _timer;

  OtpVerifyBloc() : super(OtpVerifyState.initial()) {
    on<StartTimer>(_onStartTimer);
    on<Tick>(_onTick);
    on<OtpBtnSetLoading>((event, emit) {
      emit(state.copyWith(isLoading: event.isLoading));
    });
  }

  void _onStartTimer(StartTimer event, Emitter<OtpVerifyState> emit) {
    _timer?.cancel();
    emit(state.copyWith(countdown: 60, isResendEnabled: false));

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newCount = state.countdown - 1;

      if (newCount > 0) {
        add(Tick(newCount));
      } else {
        _timer?.cancel();
        add(Tick(0)); // Triggers final state update
      }
    });
  }

  void _onTick(Tick event, Emitter<OtpVerifyState> emit) {
    emit(state.copyWith(countdown: event.remainingSeconds, isResendEnabled: event.remainingSeconds == 0));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
