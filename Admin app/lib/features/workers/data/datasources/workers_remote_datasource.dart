import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/worker_model.dart';

abstract class WorkersRemoteDataSource {
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

class WorkersRemoteDataSourceImpl implements WorkersRemoteDataSource {
  final DioClient _dioClient;

  WorkersRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<WorkerModel>> getWorkers() async {
    final response = await _dioClient.get(ApiEndpoints.workers);
    final list = (response.data['workers'] as List?) ?? [];
    return list.map((item) => WorkerModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<WorkerModel> getWorkerDetail(String workerId) async {
    final response = await _dioClient.get(ApiEndpoints.workerById(workerId));
    final data = Map<String, dynamic>.from(response.data['worker'] ?? response.data);
    if (response.data['user'] != null) {
      data['user'] = response.data['user'];
    }
    if (response.data['totalEarningsRecorded'] != null) {
      data['totalEarnings'] = response.data['totalEarningsRecorded'];
    }
    return WorkerModel.fromJson(data);
  }

  @override
  Future<void> updateWorkerStatus(String workerId, String status) async {
    await _dioClient.post(
      '${ApiEndpoints.workers}/$workerId/status',
      data: {'status': status},
    );
  }

  @override
  Future<List<dynamic>> getWorkerTasks(String workerId) async {
    final response = await _dioClient.get(ApiEndpoints.workerTasks(workerId));
    return (response.data['tasks'] as List?) ?? [];
  }

  @override
  Future<List<dynamic>> getWorkerEarnings(String workerId) async {
    final response = await _dioClient.get(ApiEndpoints.workerEarnings(workerId));
    return (response.data['earnings'] as List?) ?? [];
  }

  @override
  Future<List<dynamic>> getWorkerRatings(String workerId) async {
    final response = await _dioClient.get('${ApiEndpoints.workers}/$workerId/ratings');
    return (response.data['ratings'] as List?) ?? [];
  }

  @override
  Future<Map<String, dynamic>> getWorkerScoreHistory(String workerId) async {
    final response = await _dioClient.get('${ApiEndpoints.workers}/$workerId/score-history');
    return Map<String, dynamic>.from(response.data ?? {});
  }

  @override
  Future<List<dynamic>> getWorkerActivity(String workerId) async {
    final response = await _dioClient.get('${ApiEndpoints.workers}/$workerId/activity');
    return (response.data['activity'] as List?) ?? [];
  }

  @override
  Future<Map<String, dynamic>> getWorkerRisk(String workerId) async {
    final response = await _dioClient.get('${ApiEndpoints.workers}/$workerId/risk');
    return Map<String, dynamic>.from(response.data ?? {});
  }
}
