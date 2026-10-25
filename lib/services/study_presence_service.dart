import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

@immutable
class StudyPresenceState {
  final int activeDoctorsCount;
  final bool isConnected;
  final bool isTrackingSelf;

  const StudyPresenceState({
    this.activeDoctorsCount = 0,
    this.isConnected = false,
    this.isTrackingSelf = false,
  });

  StudyPresenceState copyWith({
    int? activeDoctorsCount,
    bool? isConnected,
    bool? isTrackingSelf,
  }) {
    return StudyPresenceState(
      activeDoctorsCount: activeDoctorsCount ?? this.activeDoctorsCount,
      isConnected: isConnected ?? this.isConnected,
      isTrackingSelf: isTrackingSelf ?? this.isTrackingSelf,
    );
  }
}

class StudyPresenceService extends StateNotifier<StudyPresenceState> {
  static const String channelName = 'modulix_study_lounge';
  static StudyPresenceService? _instance;
  static StudyPresenceService get instance => _instance ??= StudyPresenceService._();

  RealtimeChannel? _channel;
  bool _isInitialized = false;

  StudyPresenceService._() : super(const StudyPresenceState()) {
    init();
  }

  @visibleForTesting
  static void resetInstanceForTesting() {
    _instance?.dispose();
    _instance = null;
  }

  void init() {
    if (_isInitialized) return;
    final client = AuthService.instance.client;
    if (client == null || !AuthService.instance.isReady) return;

    _isInitialized = true;
    _channel = client.channel(channelName);

    _channel!.onPresenceSync((_) {
      _recalculatePresence();
    });

    _channel!.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        state = state.copyWith(isConnected: true);
        _recalculatePresence();
      } else if (status == RealtimeSubscribeStatus.closed || status == RealtimeSubscribeStatus.channelError) {
        state = state.copyWith(isConnected: false);
      }
    });
  }

  void _recalculatePresence() {
    if (_channel == null) return;
    final presenceList = _channel!.presenceState();
    int count = 0;
    for (final item in presenceList) {
      count += item.presences.length;
    }
    state = state.copyWith(activeDoctorsCount: count);
  }

  Future<void> startFocusSession({String? subjectName, String? topicTitle}) async {
    final client = AuthService.instance.client;
    if (client == null || !AuthService.instance.isReady) return;

    if (_channel == null || !_isInitialized) {
      init();
    }

    final userId = AuthService.instance.currentUserId ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
    final payload = {
      'user_id': userId,
      'status': 'focusing',
      'subject': subjectName ?? 'General Study',
      'topic': topicTitle ?? '',
      'started_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      if (_channel != null) {
        await _channel!.track(payload);
        state = state.copyWith(isTrackingSelf: true);
      }
    } catch (e) {
      debugPrint('[StudyPresenceService] track failed: $e');
    }
  }

  Future<void> stopFocusSession() async {
    if (_channel != null && state.isTrackingSelf) {
      try {
        await _channel!.untrack();
      } catch (e) {
        debugPrint('[StudyPresenceService] untrack failed: $e');
      }
      state = state.copyWith(isTrackingSelf: false);
    }
  }

  @override
  void dispose() {
    stopFocusSession();
    if (_channel != null) {
      final client = AuthService.instance.client;
      client?.removeChannel(_channel!);
      _channel = null;
    }
    _isInitialized = false;
    super.dispose();
  }
}

final studyPresenceProvider = StateNotifierProvider<StudyPresenceService, StudyPresenceState>((ref) {
  return StudyPresenceService.instance;
});
