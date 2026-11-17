import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../lib/features/workers/presentation/widgets/worker_delete_progress.dart';
import '../lib/features/workers/data/datasources/workers_local_datasource.dart';
import '../lib/features/workers/data/datasources/workers_remote_datasource.dart';
import '../lib/features/workers/data/models/worker_model.dart';
import '../lib/features/workers/domain/repositories/workers_repository.dart';
import '../lib/features/workers/presentation/bloc/workers_bloc.dart';

class _Repository implements WorkersRepository {
  final worker = WorkerModel.fromJson({'id': 'worker-1', 'userId': 'user-1', 'name': 'Test'});
  bool failDelete = false;
  Completer<List<WorkerModel>>? delayedLoad;
  Completer<void>? delayedDelete;

  @override
  Future<List<WorkerModel>> getWorkers({bool forceRefresh = false}) async =>
      delayedLoad == null ? [worker] : await delayedLoad!.future;

  @override
  Future<void> deleteWorker(String id) async {
    if (failDelete) throw StateError('Server deletion failed');
    await delayedDelete?.future;
  }

  @override
  Future<void> batchDeleteWorkers(List<String> ids) => deleteWorker(ids.first);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Remote implements WorkersRemoteDataSource {
  bool fail = false;
  Completer<List<WorkerModel>>? delayedLoad;
  @override
  Future<void> deleteWorker(String id) async {
    if (fail) throw StateError('Server failure');
  }
  @override
  Future<List<WorkerModel>> getWorkers() => delayedLoad!.future;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Local implements WorkersLocalDataSource {
  List<WorkerModel> workers = [WorkerModel.fromJson({'id': 'worker-1', 'userId': 'user-1'})];
  @override
  Future<List<WorkerModel>> getCachedWorkers() async => List.from(workers);
  @override
  Future<void> cacheWorkers(List<WorkerModel> data) async => workers = List.from(data);
  @override
  Future<void> deleteWorker(String id) async => workers.removeWhere((worker) => worker.id == id || worker.userId == id);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _load(WorkersBloc bloc) async {
  final ready = bloc.stream.firstWhere((state) => state is WorkersLoaded);
  bloc.add(LoadWorkersEvent());
  await ready;
}

void main() {
  test('repository preserves local worker data on API failure', () async {
    final local = _Local();
    final repository = WorkersRepositoryImpl(remoteDataSource: _Remote()..fail = true, localDataSource: local);
    await expectLater(repository.deleteWorker('worker-1'), throwsStateError);
    expect(local.workers.single.id, 'worker-1');
  });

  test('a pending response cannot repopulate the persistent cache after deletion', () async {
    final local = _Local();
    final oldWorkers = List<WorkerModel>.from(local.workers);
    final remote = _Remote()..delayedLoad = Completer<List<WorkerModel>>();
    final repository = WorkersRepositoryImpl(remoteDataSource: remote, localDataSource: local);
    final loading = repository.getWorkers();
    await repository.deleteWorker('worker-1');
    remote.delayedLoad!.complete(oldWorkers);
    expect(await loading, isEmpty);
    expect(local.workers, isEmpty);
  });

  test('failed server delete keeps the worker and reports failure to the screen', () async {
    final repository = _Repository()..failDelete = true;
    final bloc = WorkersBloc(repository: repository);
    await _load(bloc);
    final completion = Completer<void>();
    final check = expectLater(completion.future, throwsStateError);
    bloc.add(DeleteWorkerEvent('worker-1', completion: completion));
    await check;
    expect((bloc.state as WorkersLoaded).workers.single.id, 'worker-1');
    await bloc.close();
  });

  test('successful delete cannot be undone by a delayed list request', () async {
    final repository = _Repository();
    final bloc = WorkersBloc(repository: repository);
    await _load(bloc);
    repository.delayedLoad = Completer<List<WorkerModel>>();
    bloc.add(RefreshWorkersEvent());
    await Future<void>.delayed(Duration.zero);
    final completion = Completer<void>();
    bloc.add(DeleteWorkerEvent('worker-1', completion: completion));
    await completion.future;
    repository.delayedLoad!.complete([repository.worker]);
    await Future<void>.delayed(Duration.zero);
    expect((bloc.state as WorkersLoaded).workers, isEmpty);
    await bloc.close();
  });

  test('partial batch failure is not presented as successful local deletion', () async {
    final repository = _Repository()..failDelete = true;
    final bloc = WorkersBloc(repository: repository);
    await _load(bloc);
    final completion = Completer<void>();
    final check = expectLater(completion.future, throwsStateError);
    bloc.add(BatchDeleteWorkersEvent(['worker-1'], completion: completion));
    await check;
    expect((bloc.state as WorkersLoaded).workers.single.id, 'worker-1');
    await bloc.close();
  });

  testWidgets('success feedback waits for the deletion response', (tester) async {
    final repository = _Repository()..delayedDelete = Completer<void>();
    final bloc = WorkersBloc(repository: repository);
    await tester.pumpWidget(MaterialApp(home: BlocProvider.value(value: bloc,
      child: Scaffold(body: Builder(builder: (context) => TextButton(
        onPressed: () => deleteWorkersWithFeedback(context, ['worker-1']), child: const Text('Delete'),
      ))))));
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Deleting worker data. Please wait…'), findsOneWidget);
    expect(find.text('Worker account and all worker history permanently deleted.'), findsNothing);
    repository.delayedDelete!.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Worker account and all worker history permanently deleted.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(bloc.close);
  });
}
