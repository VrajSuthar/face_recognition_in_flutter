part of 'login_bloc.dart';

class LoginState extends Equatable {
  final bool isloading;

  const LoginState({this.isloading = false});

  LoginState copyWith({bool? isloading}) {
    return LoginState(
      isloading: isloading ?? this.isloading
    );
  }

  @override
  List<Object> get props => [isloading];
}
