

import 'package:equatable/equatable.dart';

class OtpVerifyState extends Equatable {
  final int countdown;
  final bool isResendEnabled;
  final bool isLoading;

  const OtpVerifyState({required this.countdown, required this.isResendEnabled, required this.isLoading});

  factory OtpVerifyState.initial() {
    return OtpVerifyState(countdown: 60, isResendEnabled: false, isLoading: false);
  }

  OtpVerifyState copyWith({int? countdown, bool? isResendEnabled, bool? isLoading}) {
    return OtpVerifyState(countdown: countdown ?? this.countdown, isResendEnabled: isResendEnabled ?? this.isResendEnabled, isLoading: isLoading ?? this.isLoading);
  }

  @override
  List<Object?> get props => [countdown, isResendEnabled, isLoading];
}
