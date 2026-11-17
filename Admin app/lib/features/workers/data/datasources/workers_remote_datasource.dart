import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/worker_model.dart';

class WorkerBatchDeleteException implements Exception {
  final List<String> deletedIds;
  final String message;
  WorkerBatchDeleteException(this.deletedIds, this.message);
  @override
  String toString() => message;
}

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
  Future<void> deleteWorker(String workerId);
  Future<void> batchDeleteWorkers(
    List<String> workerIds, {
    void Function(int completed, int total)? onProgress,
  });
}

class WorkersRemoteDataSourceImpl implements WorkersRemoteDataSource {
  final DioClient _dioClient;

  WorkersRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<WorkerModel>> getWorkers() async {
    final response = await _dioClient.get(
      ApiEndpoints.workers,
      queryParameters: {'page': 1, 'limit': 50},
    );
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

  @override
  Future<void> deleteWorker(String workerId) async {
    await _dioClient.delete('${ApiEndpoints.workers}/$workerId');
  }

  @override
  Future<void> batchDeleteWorkers(
    List<String> workerIds, {
    void Function(int completed, int total)? onProgress,
  }) async {
    final uniqueIds = workerIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (uniqueIds.isEmpty) return;

    const int chunkSize = 10;
    final List<String> allDeletedIds = [];
    final List<String> failedMessages = [];
    int processed = 0;

    for (var i = 0; i < uniqueIds.length; i += chunkSize) {
      final end = (i + chunkSize < uniqueIds.length) ? i + chunkSize : uniqueIds.length;
      final chunk = uniqueIds.sublist(i, end);

      try {
        final response = await _dioClient.post(
          ApiEndpoints.workersBatchDelete,
          data: {'ids': chunk},
          options: Options(receiveTimeout: const Duration(seconds: 120)),
        );
        final data = response.data;
        if (data is Map) {
          final chunkDeleted = data['deletedIds'] is List
              ? (data['deletedIds'] as List).map((id) => id.toString()).toList()
              : <String>[];
          allDeletedIds.addAll(chunkDeleted);

          if (data['success'] != true || data['deletedCount'] != chunk.length) {
            final msg = (data['message'] ?? 'Some workers could not be deleted').toString();
            failedMessages.add(msg);
          }
        } else {
          failedMessages.add('Invalid deletion response from server');
        }
      } catch (e) {
        failedMessages.add(e.toString());
      }

      processed += chunk.length;
      onProgress?.call(processed, uniqueIds.length);
    }

    if (failedMessages.isNotEmpty || allDeletedIds.length != uniqueIds.length) {
      throw WorkerBatchDeleteException(
        allDeletedIds,
        failedMessages.isNotEmpty
            ? failedMessages.first
            : 'Some workers could not be deleted. Refresh and retry.',
      );
    }
  }
}
