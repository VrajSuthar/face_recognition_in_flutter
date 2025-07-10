part of 'register_person_bloc.dart';

sealed class RegisterPersonState extends Equatable {
  const RegisterPersonState();
  
  @override
  List<Object> get props => [];
}

final class RegisterPersonInitial extends RegisterPersonState {}
