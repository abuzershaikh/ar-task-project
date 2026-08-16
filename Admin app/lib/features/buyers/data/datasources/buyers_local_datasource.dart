import 'dart:convert';
import '../../../../core/database/app_database.dart';
import '../models/buyer_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class BuyersLocalDataSource {
  Future<List<BuyerModel>> getCachedBuyers();
  Future<void> cacheBuyers(List<BuyerModel> buyers);
  Future<BuyerModel?> getCachedBuyerDetail(String buyerId);
  Future<void> cacheBuyerDetail(String buyerId, Map<String, dynamic> fullDetail);
  Future<Map<String, dynamic>?> getCachedBuyerFullDetail(String buyerId);
}

class BuyersLocalDataSourceImpl implements BuyersLocalDataSource {
  final AppDatabase _dbManager;

  BuyersLocalDataSourceImpl(this._dbManager);

  @override
  Future<List<BuyerModel>> getCachedBuyers() async {
    final db = await _dbManager.database;
    final maps = await db.query('buyers');
    
    if (maps.isNotEmpty) {
      return maps.map((map) {
        final data = json.decode(map['data'] as String);
        return BuyerModel.fromJson(data);
      }).toList();
    }
    return [];
  }

  @override
  Future<void> cacheBuyers(List<BuyerModel> buyers) async {
    final db = await _dbManager.database;
    final batch = db.batch();
    
    for (var buyer in buyers) {
      batch.insert(
        'buyers',
        {
          'id': buyer.id,
          'data': json.encode(buyer.toJson()),
          'last_updated': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  @override
  Future<BuyerModel?> getCachedBuyerDetail(String buyerId) async {
    final db = await _dbManager.database;
    final maps = await db.query(
      'buyers',
      where: 'id = ?',
      whereArgs: [buyerId],
    );

    if (maps.isNotEmpty) {
      final data = json.decode(maps.first['data'] as String);
      return BuyerModel.fromJson(data);
    }
    return null;
  }

  @override
  Future<void> cacheBuyerDetail(String buyerId, Map<String, dynamic> fullDetail) async {
    final db = await _dbManager.database;
    
    await db.insert(
      'buyers',
      {
        'id': buyerId,
        'data': json.encode(fullDetail),
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<Map<String, dynamic>?> getCachedBuyerFullDetail(String buyerId) async {
    final db = await _dbManager.database;
    final maps = await db.query(
      'buyers',
      where: 'id = ?',
      whereArgs: [buyerId],
    );

    if (maps.isNotEmpty) {
      return json.decode(maps.first['data'] as String) as Map<String, dynamic>;
    }
    return null;
  }
}
