import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modulix/providers/app_state_provider.dart';
import 'package:modulix/providers/focus_timer_provider.dart';
import 'package:modulix/services/storage_service.dart';
import 'package:modulix/services/metrics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  group('AppStateNotifier Idempotency Tests', () {
    test('markQBankComplete is idempotent and never unchecks existing completed item', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appStateProvider.notifier);
      await container.read(appStateProvider.future);

      const qbankId = 'qbank_embryology_1';

      // Initially not completed
      var state = container.read(appStateProvider).value!;
      expect(state.currentEdition.completedQBanks.containsKey(qbankId), isFalse);

      // Mark complete 1st time
      await notifier.markQBankComplete(qbankId);
      state = container.read(appStateProvider).value!;
      expect(state.currentEdition.completedQBanks.containsKey(qbankId), isTrue);

      // Mark complete 2nd time (must be idempotent, not remove or uncheck)
      await notifier.markQBankComplete(qbankId);
      state = container.read(appStateProvider).value!;
      expect(state.currentEdition.completedQBanks.containsKey(qbankId), isTrue);

      // But manual toggle can still uncheck when explicitly desired
      await notifier.toggleQBankComplete(qbankId);
      state = container.read(appStateProvider).value!;
      expect(state.currentEdition.completedQBanks.containsKey(qbankId), isFalse);
    });

    test('markNotesComplete is idempotent and never unchecks existing completed item', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appStateProvider.notifier);
      await container.read(appStateProvider.future);

      const noteId = 'notes_histology_1';

      // Initially not completed
      var state = container.read(appStateProvider).value!;
      expect(state.currentEdition.completedNotes.containsKey(noteId), isFalse);

      // Mark complete 1st time
      await notifier.markNotesComplete(noteId);
      state = container.read(appStateProvider).value!;
      expect(state.currentEdition.completedNotes.containsKey(noteId), isTrue);

      // Mark complete 2nd time (must remain completed)
      await notifier.markNotesComplete(noteId);
      state = container.read(appStateProvider).value!;
      expect(state.currentEdition.completedNotes.containsKey(noteId), isTrue);

      // Manual toggle toggles off
      await notifier.toggleNotesComplete(noteId);
      state = container.read(appStateProvider).value!;
      expect(state.currentEdition.completedNotes.containsKey(noteId), isFalse);
    });

    test('markVideoComplete is idempotent and does not double-count daily history', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appStateProvider.notifier);
      await container.read(appStateProvider.future);

      const videoId = 'vid_pathology_cell_death';
      final todayKey = MetricsService.todayKey(container.read(appStateProvider).value!.dayStartHour);

      // First completion
      await notifier.markVideoComplete(videoId);
      var state = container.read(appStateProvider).value!;
      expect(state.currentEdition.completedVideos.containsKey(videoId), isTrue);
      final countAfterFirst = state.currentEdition.dailyHistory[todayKey] ?? 0;
      expect(countAfterFirst, greaterThanOrEqualTo(1));

      // Second completion with same videoId should not increment dailyHistory count
      await notifier.markVideoComplete(videoId);
      state = container.read(appStateProvider).value!;
      final countAfterSecond = state.currentEdition.dailyHistory[todayKey] ?? 0;
      expect(countAfterSecond, equals(countAfterFirst));
    });
  });

  group('FocusTimerNotifier Idempotent Session Completion Tests', () {
    test('Focus timer finishSession with Q-Bank topic does not uncheck completed Q-Bank', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final appNotifier = container.read(appStateProvider.notifier);
      await container.read(appStateProvider.future);

      const qbankId = 'qbank_cardio_arrhythmias';

      // Pre-complete the Q-Bank
      await appNotifier.markQBankComplete(qbankId);
      var appState = container.read(appStateProvider).value!;
      expect(appState.currentEdition.completedQBanks.containsKey(qbankId), isTrue);

      // Start a focus timer session targeting this Q-Bank
      final timerNotifier = container.read(focusTimerProvider.notifier);
      timerNotifier.setTask(
        subjectId: 'cardiology',
        subjectName: 'Cardiology',
        topicId: qbankId,
        topicTitle: 'Arrhythmias Q-Bank',
        topicType: 'qbank',
      );

      // Set focusSecondsElapsed > 0 so finishSession processes the completion
      timerNotifier.state = timerNotifier.state.copyWith(focusSecondsElapsed: 120);

      // Finish session
      await timerNotifier.finishSession();

      // Verify the Q-Bank remains completed and was NOT toggled off!
      appState = container.read(appStateProvider).value!;
      expect(appState.currentEdition.completedQBanks.containsKey(qbankId), isTrue);

      // Another session for the same Q-Bank finishes
      timerNotifier.setTask(
        subjectId: 'cardiology',
        subjectName: 'Cardiology',
        topicId: qbankId,
        topicTitle: 'Arrhythmias Q-Bank',
        topicType: 'qbank',
      );
      timerNotifier.state = timerNotifier.state.copyWith(focusSecondsElapsed: 120);
      await timerNotifier.finishSession();

      appState = container.read(appStateProvider).value!;
      expect(appState.currentEdition.completedQBanks.containsKey(qbankId), isTrue);
    });

    test('Focus timer finishSession with Notes topic does not uncheck completed Notes', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final appNotifier = container.read(appStateProvider.notifier);
      await container.read(appStateProvider.future);

      const noteId = 'notes_renal_tubular_acidosis';

      // Pre-complete the Notes
      await appNotifier.markNotesComplete(noteId);
      var appState = container.read(appStateProvider).value!;
      expect(appState.currentEdition.completedNotes.containsKey(noteId), isTrue);

      // Start a focus timer session targeting this Note
      final timerNotifier = container.read(focusTimerProvider.notifier);
      timerNotifier.setTask(
        subjectId: 'nephrology',
        subjectName: 'Nephrology',
        topicId: noteId,
        topicTitle: 'RTA Notes',
        topicType: 'notes',
      );

      timerNotifier.state = timerNotifier.state.copyWith(focusSecondsElapsed: 120);

      // Finish session
      await timerNotifier.finishSession();

      // Verify the Note remains completed and was NOT toggled off!
      appState = container.read(appStateProvider).value!;
      expect(appState.currentEdition.completedNotes.containsKey(noteId), isTrue);

      // Second session finishes
      timerNotifier.setTask(
        subjectId: 'nephrology',
        subjectName: 'Nephrology',
        topicId: noteId,
        topicTitle: 'RTA Notes',
        topicType: 'notes',
      );
      timerNotifier.state = timerNotifier.state.copyWith(focusSecondsElapsed: 120);
      await timerNotifier.finishSession();

      appState = container.read(appStateProvider).value!;
      expect(appState.currentEdition.completedNotes.containsKey(noteId), isTrue);
    });
  });
}
