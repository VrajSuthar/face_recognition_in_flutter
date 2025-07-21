part of 'register_person_bloc.dart';

class RegisterPersonState extends Equatable {
  final File? filePath;
  final String profileImageUrl;
  final bool isLoading;
  final bool teacherListLoading;
  final bool teacherListVisible;
  final List<Datum>? teacherList;
  final List<Datum>? filteredTeacherList;
  final String? selectedType;
  final int? selectedTeacherId;
  final bool filePathHasChanged; 

  const RegisterPersonState({
    this.filePath,
    this.profileImageUrl = '',
    this.isLoading = false,
    this.teacherListLoading = false,
    this.teacherListVisible = false,
    this.teacherList,
    this.filteredTeacherList,
    this.selectedType,
    this.selectedTeacherId,
    this.filePathHasChanged = false, 
  });

  RegisterPersonState copyWith({
    File? filePath,
    String? profileImageUrl,
    bool? isLoading,
    bool? teacherListLoading,
    bool? teacherListVisible,
    List<Datum>? teacherList,
    List<Datum>? filteredTeacherList,
    String? selectedType,
    int? selectedTeacherId,
    bool? filePathHasChanged,
  }) {
    return RegisterPersonState(
      filePath: filePathHasChanged == true ? filePath : this.filePath,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isLoading: isLoading ?? this.isLoading,
      teacherListLoading: teacherListLoading ?? this.teacherListLoading,
      teacherListVisible: teacherListVisible ?? this.teacherListVisible,
      teacherList: teacherList ?? this.teacherList,
      filteredTeacherList: filteredTeacherList ?? this.filteredTeacherList,
      selectedType: selectedType ?? this.selectedType,
      selectedTeacherId: selectedTeacherId ?? this.selectedTeacherId,
      filePathHasChanged: filePathHasChanged ?? this.filePathHasChanged, 
    );
  }

  @override
  List<Object?> get props => [
    filePath,
    profileImageUrl,
    isLoading,
    teacherListLoading,
    teacherListVisible,
    teacherList,
    filteredTeacherList,
    selectedType,
    selectedTeacherId,
    filePathHasChanged, 
  ];
}
