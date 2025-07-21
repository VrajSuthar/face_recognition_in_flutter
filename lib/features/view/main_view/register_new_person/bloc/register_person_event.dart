part of 'register_person_bloc.dart';

sealed class RegisterPersonEvent extends Equatable {
  const RegisterPersonEvent();

  @override
  List<Object?> get props => [];
}

// Upload profile photo
class UpdateProfileImage extends RegisterPersonEvent {
  final File file;
  const UpdateProfileImage(this.file);

  @override
  List<Object?> get props => [file];
}

// Set global button loading state
class SetButtonLoading extends RegisterPersonEvent {
  final bool isLoading;
  const SetButtonLoading({required this.isLoading});

  @override
  List<Object?> get props => [isLoading];
}

// Loading state for teacher list API
class SetTeacherListLoading extends RegisterPersonEvent {
  final bool isLoading;
  const SetTeacherListLoading({required this.isLoading});

  @override
  List<Object?> get props => [isLoading];
}

// Show/hide filtered teacher list container
class SetTeacherListVisible extends RegisterPersonEvent {
  final bool isVisible;
  const SetTeacherListVisible({required this.isVisible});

  @override
  List<Object?> get props => [isVisible];
}

// Set full teacher list and initial filtered list
class TeacherList extends RegisterPersonEvent {
  final List<Datum> teacherList;
  const TeacherList({required this.teacherList});

  @override
  List<Object?> get props => [teacherList];
}

// Filter teacher list based on user input
class FilterTeacherList extends RegisterPersonEvent {
  final String query;
  const FilterTeacherList({required this.query});

  @override
  List<Object?> get props => [query];
}

// Select type
class SelectedType extends RegisterPersonEvent {
  final String selectedType;
  SelectedType({required this.selectedType});

  @override
  List<Object?> get props => [selectedType];
}

// selected teacher id
class SelectedTeacherId extends RegisterPersonEvent {
  final int selectedTeacherId;
  SelectedTeacherId({required this.selectedTeacherId});

  @override
  List<Object?> get props => [selectedTeacherId];
}

class ClearProfileImage extends RegisterPersonEvent {}
