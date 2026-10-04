import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/profile_repository_impl.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadProfileEvent extends ProfileEvent {}

class RefreshProfileEvent extends ProfileEvent {}

class UpdateProfileEvent extends ProfileEvent {
  final Map<String, dynamic> data;
  const UpdateProfileEvent(this.data);
  @override
  List<Object?> get props => [data];
}

class UpdateBusinessProfileEvent extends ProfileEvent {
  final Map<String, dynamic> data;
  const UpdateBusinessProfileEvent(this.data);
  @override
  List<Object?> get props => [data];
}

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileUpdating extends ProfileState {
  final ProfileModel currentProfile;
  const ProfileUpdating(this.currentProfile);
  @override
  List<Object?> get props => [currentProfile];
}

class ProfileLoaded extends ProfileState {
  final ProfileModel profile;
  final String? successMessage;
  const ProfileLoaded(this.profile, {this.successMessage});
  @override
  List<Object?> get props => [profile, successMessage];
}

class ProfileError extends ProfileState {
  final String message;
  final ProfileModel? cachedProfile;
  const ProfileError(this.message, {this.cachedProfile});
  @override
  List<Object?> get props => [message, cachedProfile];
}

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;
  ProfileModel? _cachedProfile;

  ProfileBloc({required this.repository}) : super(ProfileInitial()) {
    on<LoadProfileEvent>((event, emit) async {
      emit(ProfileLoading());
      final result = await repository.getProfile();
      result.fold(
        (failure) => emit(ProfileError(failure.message, cachedProfile: _cachedProfile)),
        (profile) {
          _cachedProfile = profile;
          emit(ProfileLoaded(profile));
        },
      );
    });

    on<RefreshProfileEvent>((event, emit) async {
      final result = await repository.getProfile();
      result.fold(
        (failure) => emit(ProfileError(failure.message, cachedProfile: _cachedProfile)),
        (profile) {
          _cachedProfile = profile;
          emit(ProfileLoaded(profile));
        },
      );
    });

    on<UpdateProfileEvent>((event, emit) async {
      if (_cachedProfile != null) {
        emit(ProfileUpdating(_cachedProfile!));
      } else {
        emit(ProfileLoading());
      }
      final result = await repository.updateProfile(event.data);
      result.fold(
        (failure) => emit(ProfileError(failure.message, cachedProfile: _cachedProfile)),
        (profile) {
          _cachedProfile = profile;
          emit(ProfileLoaded(profile, successMessage: 'Personal profile updated successfully!'));
        },
      );
    });

    on<UpdateBusinessProfileEvent>((event, emit) async {
      if (_cachedProfile != null) {
        emit(ProfileUpdating(_cachedProfile!));
      } else {
        emit(ProfileLoading());
      }
      final result = await repository.updateProfile(event.data);
      result.fold(
        (failure) => emit(ProfileError(failure.message, cachedProfile: _cachedProfile)),
        (profile) {
          _cachedProfile = profile;
          emit(ProfileLoaded(profile, successMessage: 'Business details saved successfully!'));
        },
      );
    });
  }
}
