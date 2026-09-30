import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_state.dart';

const _kAppStateKey = 'flowmd_flutter_app_state';

class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance!;

  final SharedPreferences _prefs;

  StorageService._(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    _instance = StorageService._(prefs);
    return _instance!;
  }

  AppState load() {
    final raw = _prefs.getString(_kAppStateKey);
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
    await _prefs.setString(_kAppStateKey, json);
  }

  Future<void> clear() async {
    await _prefs.remove(_kAppStateKey);
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
