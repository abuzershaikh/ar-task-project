import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/workers_remote_datasource.dart';
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
class DeleteWorkerEvent extends WorkersEvent {
  final String workerId;
  final Completer<void>? completion;
  DeleteWorkerEvent(this.workerId, {this.completion});
}
class BatchDeleteWorkersEvent extends WorkersEvent {
  final List<String> workerIds;
  final Completer<void>? completion;
  final void Function(int completed, int total)? onProgress;
  BatchDeleteWorkersEvent(this.workerIds, {this.completion, this.onProgress});
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
  final Set<String> _deletedIds = {};
  bool _deleting = false;
  int _revision = 0;

  WorkersBloc({required this.repository}) : super(WorkersInitial()) {
    on<LoadWorkersEvent>(_onLoadWorkers);
    on<RefreshWorkersEvent>(_onRefreshWorkers);
    on<LoadWorkerDetailEvent>(_onLoadWorkerDetail);
    on<RefreshWorkerDetailEvent>(_onRefreshWorkerDetail);
    on<UpdateWorkerStatusEvent>(_onUpdateStatus);
    on<DeleteWorkerEvent>(_onDeleteWorker);
    on<BatchDeleteWorkersEvent>(_onBatchDeleteWorkers);
  }

  Future<void> _onLoadWorkers(LoadWorkersEvent event, Emitter<WorkersState> emit) async {
    final revision = _revision;
    if (_cachedWorkers.isEmpty) {
      emit(WorkersLoading());
    } else {
      emit(WorkersLoaded(_cachedWorkers));
    }
    try {
      final workers = await repository.getWorkers();
      if (revision != _revision) return;
      _cachedWorkers = workers.where((w) => !_deletedIds.contains(w.id) && !_deletedIds.contains(w.userId)).toList();
      emit(WorkersLoaded(_cachedWorkers));
    } catch (e) {
      if (revision != _revision) return;
      if (_cachedWorkers.isNotEmpty) {
        emit(WorkersLoaded(_cachedWorkers));
      } else {
        emit(WorkersError(e.toString()));
      }
    }
  }

  Future<void> _onRefreshWorkers(RefreshWorkersEvent event, Emitter<WorkersState> emit) async {
    final revision = _revision;
    try {
      final workers = await repository.getWorkers(forceRefresh: true);
      if (revision != _revision) return;
      _cachedWorkers = workers.where((w) => !_deletedIds.contains(w.id) && !_deletedIds.contains(w.userId)).toList();
      emit(WorkersLoaded(_cachedWorkers));
    } catch (e) {
      if (revision != _revision) return;
      if (_cachedWorkers.isNotEmpty) {
        emit(WorkersLoaded(_cachedWorkers));
      } else {
        emit(WorkersError(e.toString()));
      }
    }
  }

  Future<void> _onLoadWorkerDetail(LoadWorkerDetailEvent event, Emitter<WorkersState> emit) async {
    final revision = _revision;
    emit(WorkerDetailLoading(_cachedWorkers));
    try {
      final worker = await repository.getWorkerDetail(event.workerId, forceRefresh: true);
      final tasks = await repository.getWorkerTasks(event.workerId).catchError((_) => <dynamic>[]);
      final earnings = await repository.getWorkerEarnings(event.workerId).catchError((_) => <dynamic>[]);
      final ratings = await repository.getWorkerRatings(event.workerId).catchError((_) => <dynamic>[]);
      final scoreHistory = await repository.getWorkerScoreHistory(event.workerId).catchError((_) => <String, dynamic>{});
      final activity = await repository.getWorkerActivity(event.workerId).catchError((_) => <dynamic>[]);
      final risk = await repository.getWorkerRisk(event.workerId).catchError((_) => <String, dynamic>{});

      if (revision != _revision || _deletedIds.contains(event.workerId)) return;
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
      if (revision != _revision) return;
      emit(WorkersError(e.toString()));
    }
  }

  Future<void> _onRefreshWorkerDetail(RefreshWorkerDetailEvent event, Emitter<WorkersState> emit) async {
    final revision = _revision;
    try {
      final worker = await repository.getWorkerDetail(event.workerId, forceRefresh: true);
      final tasks = await repository.getWorkerTasks(event.workerId).catchError((_) => <dynamic>[]);
      final earnings = await repository.getWorkerEarnings(event.workerId).catchError((_) => <dynamic>[]);
      final ratings = await repository.getWorkerRatings(event.workerId).catchError((_) => <dynamic>[]);
      final scoreHistory = await repository.getWorkerScoreHistory(event.workerId).catchError((_) => <String, dynamic>{});
      final activity = await repository.getWorkerActivity(event.workerId).catchError((_) => <dynamic>[]);
      final risk = await repository.getWorkerRisk(event.workerId).catchError((_) => <String, dynamic>{});

      if (revision != _revision || _deletedIds.contains(event.workerId)) return;
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
      if (revision != _revision) return;
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
      _cachedWorkers = _cachedWorkers.map((w) {
        if (w.id == event.workerId || w.userId == event.workerId) {
          final s = event.status.toUpperCase();
          return w.copyWith(
            status: s,
            accountStatus: s,
            activityStatus: s == 'ACTIVE' ? 'ACTIVE' : 'INACTIVE',
          );
        }
        return w;
      }).toList();
      emit(WorkersLoaded(_cachedWorkers));
      add(LoadWorkerDetailEvent(event.workerId));
      add(RefreshWorkersEvent());
    } catch (e) {
      if (_cachedWorkers.isNotEmpty) {
        emit(WorkersLoaded(_cachedWorkers));
      } else {
        emit(WorkersError(e.toString()));
      }
    }
  }

  Future<void> _onDeleteWorker(DeleteWorkerEvent event, Emitter<WorkersState> emit) async {
    await _deleteWorkers([event.workerId], event.completion, emit, batch: false);
  }

  Future<void> _onBatchDeleteWorkers(BatchDeleteWorkersEvent event, Emitter<WorkersState> emit) async {
    await _deleteWorkers(
      event.workerIds,
      event.completion,
      emit,
      batch: true,
      onProgress: event.onProgress,
    );
  }

  void _removeDeletedFromCache(List<String> deleted, Emitter<WorkersState> emit) {
    if (deleted.isEmpty) return;
    final selected = _cachedWorkers.where((w) => deleted.contains(w.id) || deleted.contains(w.userId));
    _deletedIds.addAll(deleted);
    for (final worker in selected) {
      _deletedIds.addAll([worker.id, worker.userId]);
    }
    _cachedWorkers = _cachedWorkers.where((w) => !_deletedIds.contains(w.id) && !_deletedIds.contains(w.userId)).toList();
    emit(WorkersLoaded(List.from(_cachedWorkers)));
  }

  Future<void> _deleteWorkers(List<String> ids, Completer<void>? completion,
      Emitter<WorkersState> emit, {required bool batch, void Function(int completed, int total)? onProgress}) async {
    if (_deleting) {
      completion?.completeError(StateError('A worker deletion is already in progress.'));
      return;
    }
    _deleting = true;
    _revision++;
    try {
      if (batch) {
        await repository.batchDeleteWorkers(ids, onProgress: onProgress);
      } else {
        await repository.deleteWorker(ids.single);
      }
      _removeDeletedFromCache(ids, emit);
      completion?.complete();
    } catch (error, stack) {
      if (error is WorkerBatchDeleteException && error.deletedIds.isNotEmpty) {
        _removeDeletedFromCache(error.deletedIds, emit);
      }
      // Keep the current detail/list visible. The requesting screen shows the error.
      if (completion != null) {
        completion.completeError(error, stack);
      } else {
        emit(WorkersError('Worker deletion failed: $error'));
      }
      add(RefreshWorkersEvent());
    } finally {
      _revision++;
      _deleting = false;
    }
  }
}
