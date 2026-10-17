import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/time_log.dart';

const String _kDbName = 'modulix.db';
const String _kLegacyDbName = 'flowmd.db';
const int _kDbVersion = 1;
const String _kLegacyTimeLogsKey = 'flowmd_time_logs_v1';
const String _kMetaLegacyMigrated = 'migrated_legacy_time_logs';

class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  Database? _db;

  DatabaseService._();

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDb();
    return _db!;
  }

  @visibleForTesting
  void setTestDatabase(Database? testDb) {
    _db = testDb;
  }

  Future<Database> _initDb([String? overridePath]) async {
    String dbPath = inMemoryDatabasePath;
    if (overridePath != null) {
      dbPath = overridePath;
    } else {
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final newDbFile = File(p.join(docsDir.path, _kDbName));
        final legacyDbFile = File(p.join(docsDir.path, _kLegacyDbName));

        // Zero-data-loss migration: If legacy flowmd.db exists and modulix.db does not,
        // copy legacy database to modulix.db so user records are preserved.
        if (!newDbFile.existsSync() && legacyDbFile.existsSync()) {
          try {
            await legacyDbFile.copy(newDbFile.path);
          } catch (_) {
            dbPath = legacyDbFile.path;
          }
        }
        if (dbPath != legacyDbFile.path) {
          dbPath = newDbFile.path;
        }
      } catch (_) {
        dbPath = inMemoryDatabasePath;
      }
    }

    final db = await openDatabase(
      dbPath,
      version: _kDbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE time_logs (
            id TEXT PRIMARY KEY,
            subject_id TEXT NOT NULL,
            topic_id TEXT,
            topic_type TEXT NOT NULL,
            topic_title TEXT NOT NULL,
            chapter_name TEXT NOT NULL,
            duration_secs INTEGER NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');

        await db.execute(
            'CREATE INDEX idx_time_logs_subject ON time_logs(subject_id)');
        await db.execute(
            'CREATE INDEX idx_time_logs_timestamp ON time_logs(timestamp)');

        await db.execute('''
          CREATE TABLE metadata (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );

    // Run legacy migration if needed
    await _migrateLegacyPreferences(db);

    return db;
  }

  Future<void> _migrateLegacyPreferences(Database db) async {
    try {
      final metaCheck = await db.query(
        'metadata',
        where: 'key = ?',
        whereArgs: [_kMetaLegacyMigrated],
      );

      if (metaCheck.isNotEmpty && metaCheck.first['value'] == 'true') {
        return; // Already migrated
      }

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kLegacyTimeLogsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        final batch = db.batch();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final log = TimeLog.fromJson(item);
            batch.insert(
              'time_logs',
              _logToMap(log),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
        await batch.commit(noResult: true);
        debugPrint(
            '[DatabaseService] Successfully migrated ${decoded.length} legacy time logs to SQLite.');
      }

      await db.insert(
        'metadata',
        {'key': _kMetaLegacyMigrated, 'value': 'true'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[DatabaseService] Migration notice: $e');
    }
  }

  Map<String, dynamic> _logToMap(TimeLog log) {
    return {
      'id': log.id,
      'subject_id': log.subjectId,
      'topic_id': log.topicId,
      'topic_type': log.topicType,
      'topic_title': log.topicTitle,
      'chapter_name': log.chapterName,
      'duration_secs': log.durationSecs,
      'timestamp': log.timestamp.millisecondsSinceEpoch,
    };
  }

  TimeLog _mapToLog(Map<String, dynamic> map) {
    return TimeLog(
      id: map['id'] as String,
      subjectId: map['subject_id'] as String,
      topicId: map['topic_id'] as String?,
      topicType: map['topic_type'] as String? ?? 'standalone',
      topicTitle: map['topic_title'] as String? ?? '',
      chapterName: map['chapter_name'] as String? ?? '',
      durationSecs: map['duration_secs'] as int? ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> insertTimeLog(TimeLog log) async {
    final db = await database;
    await db.insert(
      'time_logs',
      _logToMap(log),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TimeLog>> getAllTimeLogs() async {
    final db = await database;
    final results = await db.query(
      'time_logs',
      orderBy: 'timestamp ASC',
    );
    return results.map(_mapToLog).toList();
  }

  Future<List<TimeLog>> getTimeLogsForSubject(String subjectId) async {
    final db = await database;
    final results = await db.query(
      'time_logs',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'timestamp ASC',
    );
    return results.map(_mapToLog).toList();
  }

  Future<List<TimeLog>> getTimeLogsBetween(DateTime start, DateTime end) async {
    final db = await database;
    final results = await db.query(
      'time_logs',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp ASC',
    );
    return results.map(_mapToLog).toList();
  }

  Future<void> deleteTimeLog(String id) async {
    final db = await database;
    await db.delete('time_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllTimeLogs() async {
    final db = await database;
    await db.delete('time_logs');
  }

  Future<int> getDatabaseSizeBytes() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(docsDir.path, _kDbName);
      final file = File(dbPath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (_) {}
    return 0;
  }
}
