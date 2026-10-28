import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_state.dart';
import '../models/time_log.dart';
import '../providers/app_state_provider.dart';
import '../providers/daily_tasks_provider.dart';
import '../providers/time_log_provider.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'storage_service.dart';
import 'analytics_service.dart';
import 'metrics_service.dart';
import '../widgets/feedback/modulix_toast.dart';

class BackupService {
  static const int currentSchemaVersion = 1;

  /// Creates a complete JSON backup string representing all student data
  static Future<String> createBackupPayload(dynamic ref, {bool formatted = true}) async {
    final appStateVal = ref.read(appStateProvider);
    final appState = (appStateVal is AsyncValue<AppState>)
        ? (appStateVal.valueOrNull ?? AppState.empty)
        : (appStateVal is AppState ? appStateVal : AppState.empty);
    final timeLogs = await DatabaseService.instance.getAllTimeLogs();
    final dailyState = ref.read(dailyTasksProvider);
    final prefs = await SharedPreferences.getInstance();
    final lastActiveDate = prefs.getString('modulix_tasks_last_date_v1') ??
        prefs.getString('flowmd_tasks_last_date_v1');

    final payload = {
      'schema_version': currentSchemaVersion,
      'app_identifier': 'Modulix',
      'exported_at': DateTime.now().toIso8601String(),
      'app_state': appState.toJson(),
      'time_logs': timeLogs.map((l) => l.toJson()).toList(),
      'daily_tasks': {
        'tasks': dailyState.tasks.map((t) => t.toMap()).toList(),
        'completed_ids': dailyState.completedIds.toList(),
        'date_history': dailyState.dateHistory,
        'last_active_date': lastActiveDate,
      },
    };

    if (formatted) {
      return const JsonEncoder.withIndent('  ').convert(payload);
    }
    return jsonEncode(payload);
  }

  /// Exports backup to a temporary file and opens the system Share sheet
  static Future<bool> exportAndShare(BuildContext context, WidgetRef ref) async {
    try {
      final jsonStr = await createBackupPayload(ref);
      final tempDir = await getTemporaryDirectory();
      final now = DateTime.now();
      final dateSlug =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final file = File('${tempDir.path}/modulix_backup_$dateSlug.json');
      await file.writeAsString(jsonStr, flush: true);

      if (!context.mounted) return false;

      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      final result = await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json', name: 'modulix_backup_$dateSlug.json')],
        subject: 'Modulix Study Backup ($dateSlug)',
        text: 'Modulix study progress and focus time backup archive.',
        sharePositionOrigin: origin,
      );

      AnalyticsService.instance.logBackupExported();
      return result.status == ShareResultStatus.success || result.status == ShareResultStatus.dismissed;
    } catch (e) {
      debugPrint('[BackupService] Export error: $e');
      return false;
    }
  }

  /// Restores data from a given JSON payload
  static Future<bool> restoreFromPayload(WidgetRef ref, String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final version = decoded['schema_version'] as int? ?? 1;
      if (version > currentSchemaVersion) {
        throw Exception('Backup version ($version) is newer than supported ($currentSchemaVersion).');
      }

      final appStateMap = decoded['app_state'] as Map<String, dynamic>?;
      if (appStateMap == null) {
        throw Exception('Invalid backup: Missing app_state data.');
      }

      final restoredAppState = AppState.fromJson(appStateMap);
      await StorageService.instance.save(restoredAppState);

      // Restore time logs
      final timeLogsRaw = decoded['time_logs'] as List<dynamic>?;
      if (timeLogsRaw != null) {
        await DatabaseService.instance.clearAllTimeLogs();
        final List<TimeLog> restoredLogs = [];
        for (final item in timeLogsRaw) {
          if (item is Map<String, dynamic>) {
            restoredLogs.add(TimeLog.fromJson(item));
          }
        }
        if (restoredLogs.isNotEmpty) {
          await DatabaseService.instance.insertTimeLogsBatch(restoredLogs);
        }
      }

      // Restore daily tasks
      final dailyTasksMap = decoded['daily_tasks'] as Map<String, dynamic>?;
      if (dailyTasksMap != null) {
        final prefs = await SharedPreferences.getInstance();
        final tasksList = dailyTasksMap['tasks'] as List<dynamic>? ?? [];
        final completedIds = (dailyTasksMap['completed_ids'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList();
        final dateHist = dailyTasksMap['date_history'] as Map<String, dynamic>? ?? {};
        final lastActiveDate = dailyTasksMap['last_active_date'] as String? ??
            dailyTasksMap['last_date'] as String? ??
            MetricsService.todayKey(restoredAppState.dayStartHour);

        final tasksJson = jsonEncode(tasksList);
        final completedJson = jsonEncode(completedIds);
        final dateHistJson = jsonEncode(dateHist);

        // Synchronize both Modulix primary keys and legacy fallback keys
        await prefs.setString('modulix_daily_tasks_v1', tasksJson);
        await prefs.setString('flowmd_daily_tasks_v2', tasksJson);

        await prefs.setString('modulix_completed_tasks_v1', completedJson);
        await prefs.setString('flowmd_completed_tasks_v1', completedJson);

        await prefs.setString('modulix_tasks_history_v1', dateHistJson);
        await prefs.setString('flowmd_tasks_history_v1', dateHistJson);

        await prefs.setString('modulix_tasks_last_date_v1', lastActiveDate);
        await prefs.setString('flowmd_tasks_last_date_v1', lastActiveDate);
      }

      // Refresh Riverpod providers
      ref.invalidate(appStateProvider);
      await ref.read(timeLogsProvider.notifier).reloadFromDatabase();
      ref.invalidate(dailyTasksProvider);
      await ref.read(dailyTasksProvider.notifier).reload();

      AnalyticsService.instance.logBackupRestored();
      return true;
    } catch (e) {
      debugPrint('[BackupService] Restore error: $e');
      return false;
    }
  }

  /// Opens file picker, reads file, confirms with user, and restores
  static Future<bool> pickAndRestore(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'modulix', 'flowmd'],
      );

      if (result == null || result.files.isEmpty) return false;
      final file = File(result.files.first.path!);
      final content = await file.readAsString();

      // Show confirmation dialog before restoring
      if (!context.mounted) return false;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Restore Study Data?'),
          content: const Text(
            'Restoring from this backup will merge and update your curriculum progress and time logs. Existing study logs will be updated.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Restore Now'),
            ),
          ],
        ),
      );

      if (confirmed != true) return false;

      final success = await restoreFromPayload(ref, content);
      if (context.mounted) {
        if (success) {
          ModulixToast.showSuccess(
            context,
            message: 'Study backup successfully restored!',
          );
        } else {
          ModulixToast.showError(
            context,
            message: 'Failed to restore backup file. Please verify format.',
          );
        }
      }
      return success;
    } catch (e) {
      debugPrint('[BackupService] File pick error: $e');
      return false;
    }
  }

  // ── CLOUD SNAPSHOT VAULT (SUPABASE STORAGE) ───────────────────────────────

  /// Creates a compressed (.json.gz) backup payload byte array
  static Future<Uint8List> createCompressedBackupBytes(dynamic ref) async {
    final jsonStr = await createBackupPayload(ref, formatted: false);
    final utf8Bytes = utf8.encode(jsonStr);
    final compressed = gzip.encode(utf8Bytes);
    return Uint8List.fromList(compressed);
  }

  /// Decompresses a .json.gz byte payload into a JSON string
  static String decompressBackupBytes(List<int> compressedBytes) {
    final decompressed = gzip.decode(compressedBytes);
    return utf8.decode(decompressed);
  }

  /// Uploads a compressed snapshot archive to the user's private Supabase Storage vault
  static Future<bool> uploadSnapshotToCloud(dynamic ref) async {
    try {
      final auth = AuthService.instance;
      if (!auth.isAuthenticated || auth.client == null || auth.currentUserId == null) {
        throw Exception('User must be signed in to upload cloud snapshots.');
      }

      final client = auth.client!;
      final userId = auth.currentUserId!;
      final compressedBytes = await createCompressedBackupBytes(ref);

      final now = DateTime.now().toUtc();
      final dateSlug =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final fileName = 'modulix_vault_$dateSlug.json.gz';
      final storagePath = '$userId/$fileName';

      await client.storage.from('user-vaults').uploadBinary(
        storagePath,
        compressedBytes,
        fileOptions: const FileOptions(
          contentType: 'application/gzip',
          upsert: true,
        ),
      );

      AnalyticsService.instance.logBackupExported();
      return true;
    } catch (e) {
      debugPrint('[BackupService] Cloud snapshot upload error: $e');
      return false;
    }
  }

  /// Lists all cloud snapshot archives available in the user's private vault
  static Future<List<CloudSnapshot>> listCloudSnapshots() async {
    try {
      final auth = AuthService.instance;
      if (!auth.isAuthenticated || auth.client == null || auth.currentUserId == null) {
        return [];
      }

      final client = auth.client!;
      final userId = auth.currentUserId!;

      final files = await client.storage.from('user-vaults').list(
        path: userId,
        searchOptions: const SearchOptions(
          sortBy: SortBy(column: 'created_at', order: 'desc'),
        ),
      );

      return files.map((f) {
        final rawSize = f.metadata?['size'];
        final size = (rawSize is num) ? rawSize.toInt() : 0;
        final created = DateTime.tryParse(f.createdAt ?? '');
        return CloudSnapshot(
          name: f.name,
          path: '$userId/${f.name}',
          sizeBytes: size,
          createdAt: created,
        );
      }).toList();
    } catch (e) {
      debugPrint('[BackupService] List cloud snapshots error: $e');
      return [];
    }
  }

  /// Downloads and restores a cloud snapshot archive from Supabase Storage
  static Future<bool> restoreCloudSnapshot(String storagePath, WidgetRef ref) async {
    try {
      final auth = AuthService.instance;
      if (!auth.isAuthenticated || auth.client == null) {
        throw Exception('User must be signed in to restore cloud snapshots.');
      }

      final client = auth.client!;
      final Uint8List fileBytes =
          await client.storage.from('user-vaults').download(storagePath);

      String jsonString;
      if (storagePath.endsWith('.gz')) {
        jsonString = decompressBackupBytes(fileBytes);
      } else {
        jsonString = utf8.decode(fileBytes);
      }

      return await restoreFromPayload(ref, jsonString);
    } catch (e) {
      debugPrint('[BackupService] Restore cloud snapshot error: $e');
      return false;
    }
  }

  /// Deletes a cloud snapshot archive from Supabase Storage
  static Future<bool> deleteCloudSnapshot(String storagePath) async {
    try {
      final auth = AuthService.instance;
      if (!auth.isAuthenticated || auth.client == null) return false;
      final client = auth.client!;
      await client.storage.from('user-vaults').remove([storagePath]);
      return true;
    } catch (e) {
      debugPrint('[BackupService] Delete cloud snapshot error: $e');
      return false;
    }
  }
}

/// Model representing a cloud snapshot stored in Supabase Storage user-vaults
class CloudSnapshot {
  final String name;
  final String path;
  final int sizeBytes;
  final DateTime? createdAt;

  const CloudSnapshot({
    required this.name,
    required this.path,
    required this.sizeBytes,
    this.createdAt,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

