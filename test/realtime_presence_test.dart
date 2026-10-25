import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:modulix/config/supabase_config.dart';
import 'package:modulix/services/auth_service.dart';
import 'package:modulix/services/study_presence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient client;

  setUpAll(() {
    HttpOverrides.global = null;
    SupabaseConfig.resetOverrides();
    client = SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.anonKey,
    );
    AuthService.instance.setTestClient(client);
  });

  tearDownAll(() {
    AuthService.instance.setTestClient(null);
  });

  group('Supabase Realtime Presence & Study Lounge Tests', () {
    test('1. Direct Realtime Presence Channel connects, tracks peer, and untracks cleanly', () async {
      final channelName = 'study_lounge_test_${DateTime.now().millisecondsSinceEpoch}';
      final channel = client.channel(channelName);

      final completer = Completer<void>();
      channel.onPresenceSync((_) {
        if (!completer.isCompleted) completer.complete();
      });

      final subCompleter = Completer<RealtimeSubscribeStatus>();
      channel.subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed && !subCompleter.isCompleted) {
          subCompleter.complete(status);
        }
      });

      final status = await subCompleter.future.timeout(const Duration(seconds: 5));
      expect(status, RealtimeSubscribeStatus.subscribed);

      final trackRes = await channel.track({
        'user_id': 'test-doc-1',
        'doctor_name': 'Dr. Tester',
        'status': 'focusing',
        'joined_at': DateTime.now().toIso8601String(),
      });

      expect(trackRes.toString(), contains('ok'));

      await completer.future.timeout(const Duration(seconds: 3));

      final presence = channel.presenceState();
      expect(presence, isNotEmpty);

      await channel.untrack();
      await client.removeChannel(channel);
    });

    test('2. StudyPresenceService manages live focus session tracking and Riverpod state', () async {
      StudyPresenceService.resetInstanceForTesting();
      final service = StudyPresenceService.instance;
      service.init();

      // Wait a moment for channel subscription
      await Future.delayed(const Duration(milliseconds: 800));

      // Start focus session
      await service.startFocusSession(
        subjectName: 'Pathology',
        topicTitle: 'Cell Injury & Cellular Adaptations',
      );

      expect(service.state.isTrackingSelf, isTrue);

      // Give presence time to synchronize
      await Future.delayed(const Duration(milliseconds: 600));

      // Stop focus session
      await service.stopFocusSession();
      expect(service.state.isTrackingSelf, isFalse);

      service.dispose();
    });
  });
}
