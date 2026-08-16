import '../../data/models/worker_model.dart';
import '../../data/datasources/workers_remote_datasource.dart';
import '../../data/datasources/workers_local_datasource.dart';

abstract class WorkersRepository {
  Future<List<WorkerModel>> getWorkers({bool forceRefresh = false});
  Future<WorkerModel> getWorkerDetail(String workerId, {bool forceRefresh = false});
  Future<void> updateWorkerStatus(String workerId, String status);
  Future<List<dynamic>> getWorkerTasks(String workerId);
  Future<List<dynamic>> getWorkerEarnings(String workerId);
  Future<List<dynamic>> getWorkerRatings(String workerId);
  Future<Map<String, dynamic>> getWorkerScoreHistory(String workerId);
  Future<List<dynamic>> getWorkerActivity(String workerId);
  Future<Map<String, dynamic>> getWorkerRisk(String workerId);
}

class WorkersRepositoryImpl implements WorkersRepository {
  final WorkersRemoteDataSource remoteDataSource;
  final WorkersLocalDataSource localDataSource;

  WorkersRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<WorkerModel>> getWorkers({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final localData = await localDataSource.getCachedWorkers();
      if (localData.isNotEmpty) {
        // Fetch in background to keep cache fresh
        remoteDataSource.getWorkers().then((remoteWorkers) {
          localDataSource.cacheWorkers(remoteWorkers);
        }).catchError((_) {});
        return localData;
      }
    }
    
    final remoteWorkers = await remoteDataSource.getWorkers();
    await localDataSource.cacheWorkers(remoteWorkers);
    return remoteWorkers;
  }

  @override
  Future<WorkerModel> getWorkerDetail(String workerId, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final localData = await localDataSource.getCachedWorkerDetail(workerId);
      if (localData != null) {
        // Fetch in background
        remoteDataSource.getWorkerDetail(workerId).then((remoteWorker) async {
          final fullDetail = remoteWorker.toJson();
          final tasks = await remoteDataSource.getWorkerTasks(workerId).catchError((_) => []);
          final earnings = await remoteDataSource.getWorkerEarnings(workerId).catchError((_) => []);
          fullDetail['tasks_cache'] = tasks;
          fullDetail['earnings_cache'] = earnings;
          await localDataSource.cacheWorkerDetail(workerId, fullDetail);
        }).catchError((_) {});
        return localData;
      }
    }

    final remoteWorker = await remoteDataSource.getWorkerDetail(workerId);
    final fullDetail = remoteWorker.toJson();
    final tasks = await remoteDataSource.getWorkerTasks(workerId).catchError((_) => []);
    final earnings = await remoteDataSource.getWorkerEarnings(workerId).catchError((_) => []);
    fullDetail['tasks_cache'] = tasks;
    fullDetail['earnings_cache'] = earnings;
    await localDataSource.cacheWorkerDetail(workerId, fullDetail);
    return remoteWorker;
  }

  @override
  Future<void> updateWorkerStatus(String workerId, String status) =>
      remoteDataSource.updateWorkerStatus(workerId, status);

  @override
  Future<List<dynamic>> getWorkerTasks(String workerId) async {
    try {
      return await remoteDataSource.getWorkerTasks(workerId);
    } catch (_) {
      final localData = await localDataSource.getCachedWorkerFullDetail(workerId);
      if (localData != null && localData.containsKey('tasks_cache')) {
        return localData['tasks_cache'] as List<dynamic>;
      }
      return [];
    }
  }

  @override
  Future<List<dynamic>> getWorkerEarnings(String workerId) async {
    try {
      return await remoteDataSource.getWorkerEarnings(workerId);
    } catch (_) {
      final localData = await localDataSource.getCachedWorkerFullDetail(workerId);
      if (localData != null && localData.containsKey('earnings_cache')) {
        return localData['earnings_cache'] as List<dynamic>;
      }
      return [];
    }
  }

  @override
  Future<List<dynamic>> getWorkerRatings(String workerId) => remoteDataSource.getWorkerRatings(workerId);

  @override
  Future<Map<String, dynamic>> getWorkerScoreHistory(String workerId) => remoteDataSource.getWorkerScoreHistory(workerId);

  @override
  Future<List<dynamic>> getWorkerActivity(String workerId) => remoteDataSource.getWorkerActivity(workerId);

  @override
  Future<Map<String, dynamic>> getWorkerRisk(String workerId) => remoteDataSource.getWorkerRisk(workerId);
}
