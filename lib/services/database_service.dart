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
const int _kDbVersion = 4;
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
      onConfigure: (db) async {
        try {
          await db.execute('PRAGMA foreign_keys = ON;');
          await db.execute('PRAGMA journal_mode = WAL;');
          await db.execute('PRAGMA synchronous = NORMAL;');
          await db.execute('PRAGMA temp_store = MEMORY;');
          await db.execute('PRAGMA cache_size = -64000;');
        } catch (_) {}
      },
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
            'CREATE INDEX IF NOT EXISTS idx_time_logs_subject ON time_logs(subject_id)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_time_logs_timestamp ON time_logs(timestamp)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_time_logs_subject_timestamp ON time_logs(subject_id, timestamp ASC)');

        await db.execute('''
          CREATE TABLE metadata (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await _createTasksTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_time_logs_subject_timestamp ON time_logs(subject_id, timestamp ASC)');
        }
        if (oldVersion < 3) {
          await _createTasksTables(db);
        }
        if (oldVersion < 4) {
          try {
            await db.execute('ALTER TABLE task_projects ADD COLUMN mode TEXT NOT NULL DEFAULT "module"');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE task_projects ADD COLUMN subject_id TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE task_projects ADD COLUMN subject_name TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE task_projects ADD COLUMN unit_name TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE task_projects ADD COLUMN deadline TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE task_projects ADD COLUMN per_day_modules INTEGER');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE task_projects ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE task_items ADD COLUMN module_id TEXT');
          } catch (_) {}
        }
      },
    );

    // Run legacy migration if needed
    await _migrateLegacyPreferences(db);

    return db;
  }

  /// Creates the Tasks Hub tables (task_items + task_projects).
  /// Called both in onCreate (fresh install) and onUpgrade v2→v3.
  static Future<void> _createTasksTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color_hex TEXT NOT NULL DEFAULT '#6B7280',
        icon_name TEXT NOT NULL DEFAULT 'list',
        sort_order INTEGER NOT NULL DEFAULT 0,
        mode TEXT NOT NULL DEFAULT 'module',
        subject_id TEXT,
        subject_name TEXT,
        unit_name TEXT,
        deadline TEXT,
        per_day_modules INTEGER,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_items (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        note TEXT,
        due_date TEXT,
        due_hour INTEGER,
        due_minute INTEGER,
        project_id TEXT,
        priority INTEGER NOT NULL DEFAULT 4,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        sub_tasks TEXT NOT NULL DEFAULT '[]',
        tags TEXT NOT NULL DEFAULT '[]',
        estimated_minutes INTEGER,
        module_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES task_projects(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_task_items_due_date ON task_items(due_date)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_task_items_project_id ON task_items(project_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_task_items_is_completed ON task_items(is_completed)');
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
      id: map['id']?.toString() ?? '',
      subjectId: map['subject_id']?.toString() ?? '',
      topicId: map['topic_id']?.toString(),
      topicType: map['topic_type']?.toString() ?? 'standalone',
      topicTitle: map['topic_title']?.toString() ?? '',
      chapterName: map['chapter_name']?.toString() ?? '',
      durationSecs: (map['duration_secs'] as num?)?.toInt() ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
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

  /// High-performance bulk insert using a single SQLite batch transaction
  Future<void> insertTimeLogsBatch(List<TimeLog> logs) async {
    if (logs.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final log in logs) {
      batch.insert(
        'time_logs',
        _logToMap(log),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
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

  /// High-performance incremental fetch: queries only logs on or after given timestamp
  /// utilizing SQLite index `idx_time_logs_timestamp`.
  Future<List<TimeLog>> getTimeLogsSince(int sinceTimestampMs) async {
    final db = await database;
    final results = await db.query(
      'time_logs',
      where: 'timestamp >= ?',
      whereArgs: [sinceTimestampMs],
      orderBy: 'timestamp ASC',
    );
    return results.map(_mapToLog).toList();
  }

  /// Fast ID check without instantiating full TimeLog model objects
  Future<Set<String>> getExistingLogIds(List<String> ids) async {
    if (ids.isEmpty) return <String>{};
    final db = await database;
    final existing = <String>{};
    const chunkSize = 500;
    for (var i = 0; i < ids.length; i += chunkSize) {
      final end = (i + chunkSize < ids.length) ? i + chunkSize : ids.length;
      final chunk = ids.sublist(i, end);
      final placeholders = List.filled(chunk.length, '?').join(',');
      final res = await db.rawQuery(
        'SELECT id FROM time_logs WHERE id IN ($placeholders)',
        chunk,
      );
      for (final row in res) {
        final id = row['id']?.toString();
        if (id != null) existing.add(id);
      }
    }
    return existing;
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

  /// High-performance native SQLite aggregation across study time windows.
  /// Executes inside SQLite C-engine, avoiding allocating thousands of TimeLog instances in Dart heap.
  Future<Map<String, int>> getStudyTimeBreakdown({
    required int todayStartMs,
    required int weekStartMs,
    required int monthStartMs,
  }) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT
        COALESCE(SUM(duration_secs), 0) AS total,
        COALESCE(SUM(CASE WHEN timestamp >= ? THEN duration_secs ELSE 0 END), 0) AS daily,
        COALESCE(SUM(CASE WHEN timestamp >= ? THEN duration_secs ELSE 0 END), 0) AS weekly,
        COALESCE(SUM(CASE WHEN timestamp >= ? THEN duration_secs ELSE 0 END), 0) AS monthly
      FROM time_logs
    ''', [todayStartMs, weekStartMs, monthStartMs]);

    if (results.isEmpty) {
      return {'total': 0, 'daily': 0, 'weekly': 0, 'monthly': 0};
    }

    final row = results.first;
    return {
      'total': (row['total'] as num?)?.toInt() ?? 0,
      'daily': (row['daily'] as num?)?.toInt() ?? 0,
      'weekly': (row['weekly'] as num?)?.toInt() ?? 0,
      'monthly': (row['monthly'] as num?)?.toInt() ?? 0,
    };
  }

  /// High-performance count of logs pending sync since given timestamp.
  /// Executes directly in SQLite without fetching rows.
  Future<int> getPendingTimeLogsCount(int sinceMs) async {
    final db = await database;
    if (sinceMs <= 0) {
      final res = await db.rawQuery('SELECT COUNT(*) as count FROM time_logs');
      return (res.first['count'] as num?)?.toInt() ?? 0;
    }
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM time_logs WHERE timestamp > ?',
      [sinceMs],
    );
    return (res.first['count'] as num?)?.toInt() ?? 0;
  }

  /// Closes database connection cleanly (useful for tests and teardown)
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
