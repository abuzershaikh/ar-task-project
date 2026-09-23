import 'package:sqflite/sqflite.dart';

/// Centralized local persistent avatar cache.
/// 
/// Stores avatar URLs in memory for instant 0ms retrieval,
/// and in local SQLite for permanent persistence across app restarts.
/// Never hits VPS if the avatar URL is already present locally.
class LocalAvatarCache {
  static final Map<String, String> _memoryCache = {};
  static Database? _db;

  /// Initialize local avatar cache with the SQLite database.
  /// Preloads all known avatar URLs into memory.
  static Future<void> init(Database db) async {
    _db = db;
    try {
      await _db!.execute('''
        CREATE TABLE IF NOT EXISTS avatar_cache (
          user_id TEXT PRIMARY KEY,
          avatar_url TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      final rows = await _db!.query('avatar_cache');
      for (final row in rows) {
        final id = row['user_id'] as String?;
        final url = row['avatar_url'] as String?;
        if (id != null && url != null && url.trim().isNotEmpty) {
          _memoryCache[id] = url.trim();
        }
      }
    } catch (_) {}
  }

  /// Synchronous retrieval from in-memory cache (0ms latency).
  static String? getAvatarSync(String? id) {
    if (id == null || id.trim().isEmpty) return null;
    final cached = _memoryCache[id.trim()];
    if (cached != null && cached.isNotEmpty) return cached;
    return null;
  }

  /// Asynchronous retrieval: checks in-memory cache, then SQLite table.
  static Future<String?> getAvatar(String? id) async {
    if (id == null || id.trim().isEmpty) return null;
    final cleanId = id.trim();

    final mem = _memoryCache[cleanId];
    if (mem != null && mem.isNotEmpty) return mem;

    if (_db != null) {
      try {
        final rows = await _db!.query(
          'avatar_cache',
          where: 'user_id = ?',
          whereArgs: [cleanId],
        );
        if (rows.isNotEmpty) {
          final url = rows.first['avatar_url'] as String?;
          if (url != null && url.trim().isNotEmpty) {
            _memoryCache[cleanId] = url.trim();
            return url.trim();
          }
        }
      } catch (_) {}
    }
    return null;
  }

  /// Saves or updates avatar URL for a given ID in memory and SQLite.
  static Future<void> saveAvatar(String? id, String? url) async {
    if (id == null || id.trim().isEmpty || url == null || url.trim().isEmpty) return;
    final cleanId = id.trim();
    final cleanUrl = url.trim();

    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) return;

    _memoryCache[cleanId] = cleanUrl;

    if (_db != null) {
      try {
        await _db!.insert(
          'avatar_cache',
          {
            'user_id': cleanId,
            'avatar_url': cleanUrl,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (_) {}
    }
  }

  /// Batch save avatar URLs to memory and SQLite.
  static Future<void> saveAvatars(Map<String, String> idToUrl) async {
    if (idToUrl.isEmpty) return;

    final validEntries = <String, String>{};
    for (final entry in idToUrl.entries) {
      final k = entry.key.trim();
      final v = entry.value.trim();
      if (k.isNotEmpty && (v.startsWith('http://') || v.startsWith('https://'))) {
        validEntries[k] = v;
      }
    }

    if (validEntries.isEmpty) return;
    _memoryCache.addAll(validEntries);

    if (_db != null) {
      try {
        final batch = _db!.batch();
        final now = DateTime.now().millisecondsSinceEpoch;
        for (final entry in validEntries.entries) {
          batch.insert(
            'avatar_cache',
            {
              'user_id': entry.key,
              'avatar_url': entry.value,
              'updated_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      } catch (_) {}
    }
  }

  /// Clear all cached avatars (e.g. on logout or database clear).
  static Future<void> clearAll() async {
    _memoryCache.clear();
    if (_db != null) {
      try {
        await _db!.delete('avatar_cache');
      } catch (_) {}
    }
  }
}
