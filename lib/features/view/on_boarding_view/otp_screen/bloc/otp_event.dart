sealed class OtpVerifyEvent {}

class StartTimer extends OtpVerifyEvent {}

class Tick extends OtpVerifyEvent {
  final int remainingSeconds;
  Tick(this.remainingSeconds);
}

class OtpBtnSetLoading extends OtpVerifyEvent {
  bool isLoading = false;

  OtpBtnSetLoading({required this.isLoading});
}
