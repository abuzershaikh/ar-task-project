import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/workers_repository.dart';
import '../../data/models/worker_model.dart';

abstract class WorkersEvent {}
class LoadWorkersEvent extends WorkersEvent {}
class RefreshWorkersEvent extends WorkersEvent {}
class LoadWorkerDetailEvent extends WorkersEvent {
  final String workerId;
  LoadWorkerDetailEvent(this.workerId);
}
class RefreshWorkerDetailEvent extends WorkersEvent {
  final String workerId;
  RefreshWorkerDetailEvent(this.workerId);
}
class UpdateWorkerStatusEvent extends WorkersEvent {
  final String workerId;
  final String status;
  UpdateWorkerStatusEvent({required this.workerId, required this.status});
}

abstract class WorkersState {}
class WorkersInitial extends WorkersState {}
class WorkersLoading extends WorkersState {}
class WorkersLoaded extends WorkersState {
  final List<WorkerModel> workers;
  WorkersLoaded(this.workers);
}
class WorkerDetailLoading extends WorkersLoaded {
  WorkerDetailLoading(List<WorkerModel> workers) : super(workers);
}
class WorkerDetailLoaded extends WorkersLoaded {
  final WorkerModel worker;
  final List<dynamic> tasks;
  final List<dynamic> earnings;
  final List<dynamic> ratings;
  final Map<String, dynamic> scoreHistory;
  final List<dynamic> activity;
  final Map<String, dynamic> risk;

  WorkerDetailLoaded({
    required List<WorkerModel> workers,
    required this.worker,
    required this.tasks,
    required this.earnings,
    required this.ratings,
    required this.scoreHistory,
    required this.activity,
    required this.risk,
  }) : super(workers);
}
class WorkersError extends WorkersState {
  final String message;
  WorkersError(this.message);
}

class WorkersBloc extends Bloc<WorkersEvent, WorkersState> {
  final WorkersRepository repository;
  List<WorkerModel> _cachedWorkers = [];

  WorkersBloc({required this.repository}) : super(WorkersInitial()) {
    on<LoadWorkersEvent>(_onLoadWorkers);
    on<RefreshWorkersEvent>(_onRefreshWorkers);
    on<LoadWorkerDetailEvent>(_onLoadWorkerDetail);
    on<RefreshWorkerDetailEvent>(_onRefreshWorkerDetail);
    on<UpdateWorkerStatusEvent>(_onUpdateStatus);
  }

  Future<void> _onLoadWorkers(LoadWorkersEvent event, Emitter<WorkersState> emit) async {
    if (_cachedWorkers.isEmpty) {
      emit(WorkersLoading());
    } else {
      emit(WorkersLoaded(_cachedWorkers));
    }
    try {
      final workers = await repository.getWorkers();
      _cachedWorkers = workers;
      emit(WorkersLoaded(_cachedWorkers));
    } catch (e) {
      if (_cachedWorkers.isNotEmpty) {
        emit(WorkersLoaded(_cachedWorkers));
      } else {
        emit(WorkersError(e.toString()));
      }
    }
  }

  Future<void> _onRefreshWorkers(RefreshWorkersEvent event, Emitter<WorkersState> emit) async {
    try {
      final workers = await repository.getWorkers(forceRefresh: true);
      _cachedWorkers = workers;
      emit(WorkersLoaded(_cachedWorkers));
    } catch (e) {
      if (_cachedWorkers.isNotEmpty) {
        emit(WorkersLoaded(_cachedWorkers));
      } else {
        emit(WorkersError(e.toString()));
      }
    }
  }

  Future<void> _onLoadWorkerDetail(LoadWorkerDetailEvent event, Emitter<WorkersState> emit) async {
    emit(WorkerDetailLoading(_cachedWorkers));
    try {
      final worker = await repository.getWorkerDetail(event.workerId);
      final tasks = await repository.getWorkerTasks(event.workerId).catchError((_) => <dynamic>[]);
      final earnings = await repository.getWorkerEarnings(event.workerId).catchError((_) => <dynamic>[]);
      final ratings = await repository.getWorkerRatings(event.workerId).catchError((_) => <dynamic>[]);
      final scoreHistory = await repository.getWorkerScoreHistory(event.workerId).catchError((_) => <String, dynamic>{});
      final activity = await repository.getWorkerActivity(event.workerId).catchError((_) => <dynamic>[]);
      final risk = await repository.getWorkerRisk(event.workerId).catchError((_) => <String, dynamic>{});

      emit(WorkerDetailLoaded(
        workers: _cachedWorkers,
        worker: worker,
        tasks: tasks,
        earnings: earnings,
        ratings: ratings,
        scoreHistory: scoreHistory,
        activity: activity,
        risk: risk,
      ));
    } catch (e) {
      if (_cachedWorkers.isNotEmpty) {
        emit(WorkersLoaded(_cachedWorkers));
      } else {
        emit(WorkersError(e.toString()));
      }
    }
  }

  Future<void> _onRefreshWorkerDetail(RefreshWorkerDetailEvent event, Emitter<WorkersState> emit) async {
    try {
      final worker = await repository.getWorkerDetail(event.workerId, forceRefresh: true);
      final tasks = await repository.getWorkerTasks(event.workerId).catchError((_) => <dynamic>[]);
      final earnings = await repository.getWorkerEarnings(event.workerId).catchError((_) => <dynamic>[]);
      final ratings = await repository.getWorkerRatings(event.workerId).catchError((_) => <dynamic>[]);
      final scoreHistory = await repository.getWorkerScoreHistory(event.workerId).catchError((_) => <String, dynamic>{});
      final activity = await repository.getWorkerActivity(event.workerId).catchError((_) => <dynamic>[]);
      final risk = await repository.getWorkerRisk(event.workerId).catchError((_) => <String, dynamic>{});

      emit(WorkerDetailLoaded(
        workers: _cachedWorkers,
        worker: worker,
        tasks: tasks,
        earnings: earnings,
        ratings: ratings,
        scoreHistory: scoreHistory,
        activity: activity,
        risk: risk,
      ));
    } catch (e) {
      if (_cachedWorkers.isNotEmpty) {
        emit(WorkersLoaded(_cachedWorkers));
      } else {
        emit(WorkersError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateStatus(UpdateWorkerStatusEvent event, Emitter<WorkersState> emit) async {
    try {
      await repository.updateWorkerStatus(event.workerId, event.status);
      add(LoadWorkerDetailEvent(event.workerId));
    } catch (e) {
      if (_cachedWorkers.isNotEmpty) {
        emit(WorkersLoaded(_cachedWorkers));
      } else {
        emit(WorkersError(e.toString()));
      }
    }
  }
}
