import '../../../../core/storage/local_avatar_cache.dart';
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
  Future<void> deleteWorker(String workerId);
  Future<void> batchDeleteWorkers(List<String> workerIds);
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
    try {
      final remoteWorkers = await remoteDataSource.getWorkers();
      for (final w in remoteWorkers) {
        if (w.avatarUrl != null && w.avatarUrl!.isNotEmpty) {
          LocalAvatarCache.saveAvatar(w.id, w.avatarUrl);
          if (w.userId.isNotEmpty) {
            LocalAvatarCache.saveAvatar(w.userId, w.avatarUrl);
          }
        }
      }
      await localDataSource.cacheWorkers(remoteWorkers);
      return remoteWorkers;
    } catch (e) {
      final localData = await localDataSource.getCachedWorkers();
      if (localData.isNotEmpty) {
        return localData;
      }
      rethrow;
    }
  }

  @override
  Future<WorkerModel> getWorkerDetail(String workerId, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      var localData = await localDataSource.getCachedWorkerDetail(workerId);
      if (localData != null) {
        // If avatarUrl is missing locally, check LocalAvatarCache
        if (localData.avatarUrl == null || localData.avatarUrl!.isEmpty) {
          final cachedAvatar = await LocalAvatarCache.getAvatar(workerId);
          if (cachedAvatar != null && cachedAvatar.isNotEmpty) {
            localData = localData.copyWith(avatarUrl: cachedAvatar);
          }
        }

        // Return local immediately if avatar is present
        if (localData.avatarUrl != null && localData.avatarUrl!.isNotEmpty) {
          // Background sync
          remoteDataSource.getWorkerDetail(workerId).then((remoteWorker) async {
            if (remoteWorker.avatarUrl != null && remoteWorker.avatarUrl!.isNotEmpty) {
              await LocalAvatarCache.saveAvatar(workerId, remoteWorker.avatarUrl);
              if (remoteWorker.userId.isNotEmpty) {
                await LocalAvatarCache.saveAvatar(remoteWorker.userId, remoteWorker.avatarUrl);
              }
            }
            final fullDetail = remoteWorker.toJson();
            final tasks = await remoteDataSource.getWorkerTasks(workerId).catchError((_) => []);
            final earnings = await remoteDataSource.getWorkerEarnings(workerId).catchError((_) => []);
            fullDetail['tasks_cache'] = tasks;
            fullDetail['earnings_cache'] = earnings;
            await localDataSource.cacheWorkerDetail(workerId, fullDetail);
          }).catchError((_) {});
          return localData;
        }
        // If local avatar is null, fetch immediately from remote VPS
      }
    }

    final remoteWorker = await remoteDataSource.getWorkerDetail(workerId);
    if (remoteWorker.avatarUrl != null && remoteWorker.avatarUrl!.isNotEmpty) {
      await LocalAvatarCache.saveAvatar(workerId, remoteWorker.avatarUrl);
      if (remoteWorker.userId.isNotEmpty) {
        await LocalAvatarCache.saveAvatar(remoteWorker.userId, remoteWorker.avatarUrl);
      }
    }
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

  @override
  Future<void> deleteWorker(String workerId) async {
    try {
      await remoteDataSource.deleteWorker(workerId);
    } catch (_) {}
    await localDataSource.deleteWorker(workerId);
  }

  @override
  Future<void> batchDeleteWorkers(List<String> workerIds) async {
    try {
      await remoteDataSource.batchDeleteWorkers(workerIds);
    } catch (_) {}
    for (final id in workerIds) {
      await localDataSource.deleteWorker(id);
    }
  }
}
