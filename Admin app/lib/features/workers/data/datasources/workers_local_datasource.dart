import 'dart:convert';
import '../../../../core/database/app_database.dart';
import '../models/worker_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class WorkersLocalDataSource {
  Future<List<WorkerModel>> getCachedWorkers();
  Future<void> cacheWorkers(List<WorkerModel> workers);
  Future<WorkerModel?> getCachedWorkerDetail(String workerId);
  Future<void> cacheWorkerDetail(String workerId, Map<String, dynamic> fullDetail);
  Future<Map<String, dynamic>?> getCachedWorkerFullDetail(String workerId);
}

class WorkersLocalDataSourceImpl implements WorkersLocalDataSource {
  final AppDatabase _dbManager;

  WorkersLocalDataSourceImpl(this._dbManager);

  @override
  Future<List<WorkerModel>> getCachedWorkers() async {
    final db = await _dbManager.database;
    final maps = await db.query('workers');
    
    if (maps.isNotEmpty) {
      return maps.map((map) {
        final data = json.decode(map['data'] as String);
        return WorkerModel.fromJson(data);
      }).toList();
    }
    return [];
  }

  @override
  Future<void> cacheWorkers(List<WorkerModel> workers) async {
    final db = await _dbManager.database;
    final batch = db.batch();
    
    // Clear old workers or just replace
    // We will use REPLACE to update existing and add new
    for (var worker in workers) {
      batch.insert(
        'workers',
        {
          'id': worker.id,
          'data': json.encode(worker.toJson()),
          'last_updated': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  @override
  Future<WorkerModel?> getCachedWorkerDetail(String workerId) async {
    final db = await _dbManager.database;
    final maps = await db.query(
      'workers',
      where: 'id = ?',
      whereArgs: [workerId],
    );

    if (maps.isNotEmpty) {
      final data = json.decode(maps.first['data'] as String);
      return WorkerModel.fromJson(data);
    }
    return null;
  }

  @override
  Future<void> cacheWorkerDetail(String workerId, Map<String, dynamic> fullDetail) async {
    final db = await _dbManager.database;
    
    // We can store the full detail including tasks, earnings, etc. in the same data blob
    // This allows the detail view to also work offline!
    await db.insert(
      'workers',
      {
        'id': workerId,
        'data': json.encode(fullDetail),
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<Map<String, dynamic>?> getCachedWorkerFullDetail(String workerId) async {
    final db = await _dbManager.database;
    final maps = await db.query(
      'workers',
      where: 'id = ?',
      whereArgs: [workerId],
    );

    if (maps.isNotEmpty) {
      return json.decode(maps.first['data'] as String) as Map<String, dynamic>;
    }
    return null;
  }
}
