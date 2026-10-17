import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_state.dart';

const _kAppStateKey = 'modulix_app_state';
const _kLegacyAppStateKey = 'flowmd_flutter_app_state';
const _kRecentSubjectsKey = 'modulix_recent_subject_timestamps';
const _kLegacyRecentSubjectsKey = 'flowmd_recent_subject_timestamps';
const _kSortModeKey = 'modulix_curriculum_sort_mode';
const _kLegacySortModeKey = 'flowmd_curriculum_sort_mode';

class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._(null);

  final SharedPreferences? _prefs;
  final Map<String, dynamic> _fallbackMemory = {};

  StorageService._(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    _instance = StorageService._(prefs);
    return _instance!;
  }

  AppState load() {
    final raw = _prefs?.getString(_kAppStateKey) ??
        _prefs?.getString(_kLegacyAppStateKey) ??
        _fallbackMemory[_kAppStateKey] as String? ??
        _fallbackMemory[_kLegacyAppStateKey] as String?;
    if (raw == null) return AppState.empty;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AppState.fromJson(json);
    } catch (_) {
      return AppState.empty;
    }
  }

  Future<void> save(AppState state) async {
    final json = jsonEncode(state.toJson());
    if (_prefs != null) {
      await _prefs!.setString(_kAppStateKey, json);
    } else {
      _fallbackMemory[_kAppStateKey] = json;
    }
  }

  Future<void> clear() async {
    if (_prefs != null) {
      await _prefs!.remove(_kAppStateKey);
    }
    _fallbackMemory.remove(_kAppStateKey);
  }

  Map<String, int> getRecentSubjectTimestamps() {
    final raw = _prefs?.getString(_kRecentSubjectsKey) ??
        _prefs?.getString(_kLegacyRecentSubjectsKey) ??
        _fallbackMemory[_kRecentSubjectsKey] as String? ??
        _fallbackMemory[_kLegacyRecentSubjectsKey] as String?;
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  Future<void> recordSubjectVisit(String subjectId) async {
    final map = getRecentSubjectTimestamps();
    map[subjectId] = DateTime.now().millisecondsSinceEpoch;
    final encoded = jsonEncode(map);
    if (_prefs != null) {
      await _prefs!.setString(_kRecentSubjectsKey, encoded);
    } else {
      _fallbackMemory[_kRecentSubjectsKey] = encoded;
    }
  }

  String getCurriculumSortMode() {
    return _prefs?.getString(_kSortModeKey) ??
        _prefs?.getString(_kLegacySortModeKey) ??
        (_fallbackMemory[_kSortModeKey] as String?) ??
        (_fallbackMemory[_kLegacySortModeKey] as String?) ??
        'default';
  }

  Future<void> setCurriculumSortMode(String mode) async {
    if (_prefs != null) {
      await _prefs!.setString(_kSortModeKey, mode);
    } else {
      _fallbackMemory[_kSortModeKey] = mode;
    }
  }

  /// Export full state as JSON string
  String export(AppState state) => jsonEncode(state.toJson());

  /// Import from JSON string — returns null if invalid
  AppState? import(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AppState.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
