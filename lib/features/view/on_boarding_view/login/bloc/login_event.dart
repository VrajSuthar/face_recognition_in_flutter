part of 'login_bloc.dart';

class LoginEvent {}

class LoginBtnSetLoading extends LoginEvent {
  final bool? isloading;
  LoginBtnSetLoading({this.isloading});
}
