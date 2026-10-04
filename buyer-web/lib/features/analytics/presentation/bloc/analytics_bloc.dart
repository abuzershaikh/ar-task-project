import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/analytics_model.dart';
import '../../data/repositories/analytics_repository_impl.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();
  @override
  List<Object?> get props => [];
}

class LoadAnalyticsEvent extends AnalyticsEvent {}

abstract class AnalyticsState extends Equatable {
  const AnalyticsState();
  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}
class AnalyticsLoading extends AnalyticsState {}
class AnalyticsLoaded extends AnalyticsState {
  final AnalyticsModel analytics;
  const AnalyticsLoaded(this.analytics);
  @override
  List<Object?> get props => [analytics];
}
class AnalyticsError extends AnalyticsState {
  final String message;
  const AnalyticsError(this.message);
  @override
  List<Object?> get props => [message];
}

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRepository repository;

  AnalyticsBloc({required this.repository}) : super(AnalyticsInitial()) {
    on<LoadAnalyticsEvent>((event, emit) async {
      emit(AnalyticsLoading());
      final result = await repository.getAnalytics();
      result.fold(
        (failure) => emit(AnalyticsError(failure.message)),
        (analytics) => emit(AnalyticsLoaded(analytics)),
      );
    });
  }
}
