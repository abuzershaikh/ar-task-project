import '../../data/models/worker_model.dart';
import '../../data/datasources/workers_remote_datasource.dart';

abstract class WorkersRepository {
  Future<List<WorkerModel>> getWorkers();
  Future<WorkerModel> getWorkerDetail(String workerId);
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

  WorkersRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<WorkerModel>> getWorkers() => remoteDataSource.getWorkers();

  @override
  Future<WorkerModel> getWorkerDetail(String workerId) => remoteDataSource.getWorkerDetail(workerId);

  @override
  Future<void> updateWorkerStatus(String workerId, String status) =>
      remoteDataSource.updateWorkerStatus(workerId, status);

  @override
  Future<List<dynamic>> getWorkerTasks(String workerId) => remoteDataSource.getWorkerTasks(workerId);

  @override
  Future<List<dynamic>> getWorkerEarnings(String workerId) => remoteDataSource.getWorkerEarnings(workerId);

  @override
  Future<List<dynamic>> getWorkerRatings(String workerId) => remoteDataSource.getWorkerRatings(workerId);

  @override
  Future<Map<String, dynamic>> getWorkerScoreHistory(String workerId) => remoteDataSource.getWorkerScoreHistory(workerId);

  @override
  Future<List<dynamic>> getWorkerActivity(String workerId) => remoteDataSource.getWorkerActivity(workerId);

  @override
  Future<Map<String, dynamic>> getWorkerRisk(String workerId) => remoteDataSource.getWorkerRisk(workerId);
}
