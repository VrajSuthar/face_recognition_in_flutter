

sealed class OtpVerifyEvent {}

class StartTimer extends OtpVerifyEvent {}

class Tick extends OtpVerifyEvent {
  final int remainingSeconds;
  Tick(this.remainingSeconds);
}

class SetLoading extends OtpVerifyEvent {
  final bool isLoading;

  SetLoading(this.isLoading);
}
