import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modulix/widgets/timer/ambient_sound_sheet.dart';
import 'package:modulix/widgets/timer/medical_wave_visualizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AmbientAudioService.instance.bypassNativeAudio = true;
  });

  group('Ambient Audio Catalog & Presets Integrity', () {
    test('kAmbientSounds contains 10 curated tracks across 3 categories', () {
      expect(kAmbientSounds.length, 10);
      final categories = kAmbientSounds.map((s) => s.category).toSet();
      expect(categories, containsAll([
        AmbientCategory.weather,
        AmbientCategory.nature,
        AmbientCategory.focus,
      ]));

      for (final s in kAmbientSounds) {
        expect(s.id, isNotEmpty);
        expect(s.label, isNotEmpty);
        expect(s.subtitle, isNotEmpty);
        expect(s.assetFileName, endsWith('.mp3'));
      }
    });

    test('kAmbientPresets contains 4 balanced clinical presets', () {
      expect(kAmbientPresets.length, 4);
      for (final p in kAmbientPresets) {
        expect(p.id, isNotEmpty);
        expect(p.name, isNotEmpty);
        expect(p.icon, isNotNull);
        expect(p.trackVolumes, isNotEmpty);
        for (final vol in p.trackVolumes.values) {
          expect(vol, inInclusiveRange(0.0, 1.0));
        }
      }
    });
  });

  group('AmbientAudioService Unit Tests', () {
    late AmbientAudioService service;

    setUp(() {
      service = AmbientAudioService.instance;
    });

    test('volume clamping bounds', () async {
      await service.setTrackVolume('rain_window', 1.5);
      expect(service.getTrackVolume('rain_window'), 1.0);

      await service.setTrackVolume('rain_window', -0.5);
      expect(service.getTrackVolume('rain_window'), 0.0);

      await service.setTrackVolume('rain_window', 0.65);
      expect(service.getTrackVolume('rain_window'), 0.65);

      await service.setMasterVolume(1.8);
      expect(service.masterVolume, 1.0);

      await service.setMasterVolume(-0.2);
      expect(service.masterVolume, 0.0);

      await service.setMasterVolume(0.80);
      expect(service.masterVolume, 0.80);
    });

    test('preset application updates volumes and active preset ID', () async {
      const testPreset = AmbientPreset(
        id: 'test_preset',
        name: 'Test Mix',
        icon: Icons.science_rounded,
        trackVolumes: {
          'brown_noise': 0.80,
          'singing_bowl': 0.35,
        },
      );

      await service.applyPreset(testPreset);
      expect(service.activePresetId, 'test_preset');
      expect(service.activeTrackIds, containsAll(['brown_noise', 'singing_bowl']));
      expect(service.getTrackVolume('brown_noise'), 0.80);
      expect(service.getTrackVolume('singing_bowl'), 0.35);

      await service.clearAll();
      expect(service.activeTrackIds, isEmpty);
      expect(service.activePresetId, isNull);
    });

    test('toggleMute flips mute state', () async {
      final initialMute = service.isMuted;
      await service.toggleMute();
      expect(service.isMuted, !initialMute);
      await service.toggleMute();
      expect(service.isMuted, initialMute);
    });

    test('onTimerPause stops active isPlaying flag without clearing active tracks', () async {
      const testPreset = AmbientPreset(
        id: 'test_pause_preset',
        name: 'Pause Test',
        icon: Icons.pause_rounded,
        trackVolumes: {'creek': 0.50},
      );

      await service.applyPreset(testPreset);
      expect(service.activeTrackIds, contains('creek'));

      await service.onTimerPause();
      expect(service.isPlaying, isFalse);
      expect(service.activeTrackIds, contains('creek')); // tracks retained

      await service.clearAll();
    });
  });

  group('MedicalWaveVisualizer Widget Tests', () {
    testWidgets('renders CustomPaint with baseline', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MedicalWaveVisualizer(
              height: 32,
              color: Colors.teal,
              showBaseline: true,
            ),
          ),
        ),
      );

      expect(find.byType(MedicalWaveVisualizer), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('AmbientSoundSheet Widget Tests', () {
    testWidgets('renders Multi-Track Mixer header, presets, and sound tracks', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AmbientSoundSheet(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Multi-Track Desk Mixer'), findsOneWidget);
      expect(find.text('Master'), findsOneWidget);
      expect(find.text('Rain on Window'), findsOneWidget);

      // Verify preset buttons exist
      expect(find.text('Rainy Library'), findsOneWidget);
      expect(find.text('Late-Night Cabin'), findsOneWidget);
      expect(find.text('Deep Focus Sanctum'), findsOneWidget);
    });
  });
}
