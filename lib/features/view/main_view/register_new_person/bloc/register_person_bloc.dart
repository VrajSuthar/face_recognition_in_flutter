import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'register_person_event.dart';
part 'register_person_state.dart';

class RegisterPersonBloc extends Bloc<RegisterPersonEvent, RegisterPersonState> {
  RegisterPersonBloc() : super(RegisterPersonInitial()) {
    on<RegisterPersonEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
