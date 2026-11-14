import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/data/syllabus_marrow8.dart';
import 'package:modulix/data/syllabus_marrow65.dart';
import 'package:modulix/data/syllabus_qbank.dart';
import 'package:modulix/data/subjects_metadata.dart';
import 'package:modulix/models/app_state.dart';
import 'package:modulix/providers/curriculum_sort_provider.dart';

final _fakePatterns = [
  RegExp(r'^(untitled|dummy|placeholder|sample\s+(?:video|topic|item|\d+)|test\s+(?:video|topic|item|\d+))\b', caseSensitive: false),
  RegExp(r'^(temp\b|temporary\b|coming\s+soon|to\s+be\s+added|tbd\b|tba\b|new\s+(?:video|topic))\b', caseSensitive: false),
  RegExp(r'\b(lorem\s+ipsum|fake\s+(?:topic|video))\b', caseSensitive: false),
  RegExp(r'(\[draft\]|\[placeholder\]|\[dummy\]|\[test\])', caseSensitive: false),
];

bool _isFakeTitle(String title) {
  final clean = title.trim();
  if (clean.length < 2) return true;
  if (RegExp(r'^[0-9\W]+$').hasMatch(clean)) return true;
  for (final pat in _fakePatterns) {
    if (pat.hasMatch(clean)) return true;
  }
  return false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Curriculum Data Integrity & Security Tests', () {
    test('Edition 8 dataset integrity: contiguous 1..N sequences, zero dupes, zero fake topics', () {
      expect(marrow8Raw.length, equals(20), reason: 'E8 must have exactly 20 subjects');

      final allVideoIds = <String>{};
      int totalVideos = 0;

      for (final s in marrow8Raw) {
        final sId = s['id'] as String;
        final chapters = (s['chapters'] as List<dynamic>?) ?? [];
        expect(chapters, isNotEmpty, reason: 'Subject $sId must have chapters');

        final sVideos = <Map<String, dynamic>>[];
        final seenTitles = <String>{};
        int lastAssigned = 0;

        for (final ch in chapters) {
          final chMap = ch as Map<String, dynamic>;
          final chName = chMap['name'] as String;
          expect(chName.trim(), equals(chName), reason: 'Untrimmed chapter name in $sId');
          expect(chName, isNotEmpty, reason: 'Empty chapter name in $sId');

          final vids = (chMap['videos'] as List<dynamic>?) ?? [];
          final declaredModules = chMap['modules'] as int?;
          expect(declaredModules, equals(vids.length),
              reason: 'Declared modules mismatch in $sId -> $chName');

          for (final v in vids) {
            final vMap = v as Map<String, dynamic>;
            final vId = vMap['id'] as String;
            final title = vMap['title'] as String;
            final assignedNum = vMap['assignedNumber'] as int?;
            final dm = vMap['durationMins'] as int?;
            final ds = vMap['durationSecs'] as int?;

            // No whitespace corruption
            expect(vId.trim(), equals(vId), reason: 'Untrimmed ID: $vId');
            expect(title.trim(), equals(title), reason: 'Untrimmed title: $title');

            // Unique ID
            expect(allVideoIds.contains(vId), isFalse, reason: 'Duplicate ID: $vId');
            allVideoIds.add(vId);

            // Zero fake/placeholder topics
            expect(_isFakeTitle(title), isFalse, reason: 'Fake topic detected in $sId: $title ($vId)');

            // Zero intra-subject duplicate titles
            final normTitle = title.trim().toLowerCase();
            expect(seenTitles.contains(normTitle), isFalse,
                reason: 'Duplicate title in $sId: $title ($vId)');
            seenTitles.add(normTitle);

            // Valid duration
            expect(dm, isNotNull);
            expect(ds, isNotNull);
            expect(dm! >= 0, isTrue, reason: 'Negative durationMins in $vId');
            expect(ds! >= 0 && ds < 60, isTrue, reason: 'Invalid durationSecs in $vId');
            expect(dm * 60 + ds > 0, isTrue, reason: 'Zero duration in $vId');
            expect(dm < 600, isTrue, reason: 'Absurd duration in $vId');

            // Strictly contiguous 1..N
            expect(assignedNum, equals(lastAssigned + 1),
                reason: 'Non-contiguous sequence in $sId: expected #${lastAssigned + 1}, got #$assignedNum');
            lastAssigned = assignedNum!;

            sVideos.add(vMap);
          }
        }

        totalVideos += sVideos.length;
        final assignedList = sVideos.map((v) => v['assignedNumber'] as int).toList();
        final expectedList = List.generate(sVideos.length, (i) => i + 1);
        expect(assignedList, equals(expectedList));
      }

      expect(totalVideos, equals(1558), reason: 'Edition 8 must contain exactly 1,558 videos');
    });

    test('Edition 6.5 dataset integrity: contiguous 1..N sequences, zero dupes, zero fake topics', () {
      expect(marrow65Raw.length, equals(20), reason: 'E6.5 must have exactly 20 subjects');

      final allVideoIds = <String>{};
      int totalVideos = 0;

      for (final s in marrow65Raw) {
        final sId = s['id'] as String;
        final chapters = (s['chapters'] as List<dynamic>?) ?? [];
        expect(chapters, isNotEmpty, reason: 'Subject $sId must have chapters');

        final sVideos = <Map<String, dynamic>>[];
        final seenTitles = <String>{};
        int lastAssigned = 0;

        for (final ch in chapters) {
          final chMap = ch as Map<String, dynamic>;
          final chName = chMap['name'] as String;
          expect(chName.trim(), equals(chName), reason: 'Untrimmed chapter name in $sId');
          expect(chName, isNotEmpty, reason: 'Empty chapter name in $sId');

          final vids = (chMap['videos'] as List<dynamic>?) ?? [];
          final declaredModules = chMap['modules'] as int?;
          expect(declaredModules, equals(vids.length),
              reason: 'Declared modules mismatch in $sId -> $chName');

          for (final v in vids) {
            final vMap = v as Map<String, dynamic>;
            final vId = vMap['id'] as String;
            final title = vMap['title'] as String;
            final assignedNum = vMap['assignedNumber'] as int?;
            final dm = vMap['durationMins'] as int?;
            final ds = vMap['durationSecs'] as int?;

            expect(vId.trim(), equals(vId), reason: 'Untrimmed ID: $vId');
            expect(title.trim(), equals(title), reason: 'Untrimmed title: $title');

            expect(allVideoIds.contains(vId), isFalse, reason: 'Duplicate ID: $vId');
            allVideoIds.add(vId);

            expect(_isFakeTitle(title), isFalse, reason: 'Fake topic detected in $sId: $title ($vId)');

            final normTitle = title.trim().toLowerCase();
            expect(seenTitles.contains(normTitle), isFalse,
                reason: 'Duplicate title in $sId: $title ($vId)');
            seenTitles.add(normTitle);

            expect(dm, isNotNull);
            expect(ds, isNotNull);
            expect(dm! >= 0, isTrue, reason: 'Negative durationMins in $vId');
            expect(ds! >= 0 && ds < 60, isTrue, reason: 'Invalid durationSecs in $vId');
            expect(dm * 60 + ds > 0, isTrue, reason: 'Zero duration in $vId');
            expect(dm < 600, isTrue, reason: 'Absurd duration in $vId');

            expect(assignedNum, equals(lastAssigned + 1),
                reason: 'Non-contiguous sequence in $sId: expected #${lastAssigned + 1}, got #$assignedNum');
            lastAssigned = assignedNum!;

            sVideos.add(vMap);
          }
        }

        totalVideos += sVideos.length;
        final assignedList = sVideos.map((v) => v['assignedNumber'] as int).toList();
        final expectedList = List.generate(sVideos.length, (i) => i + 1);
        expect(assignedList, equals(expectedList));
      }

      expect(totalVideos, equals(1593), reason: 'Edition 6.5 must contain exactly 1,593 videos');
    });

    test('Marrow Q-Bank dataset integrity: contiguous 1..N sequences, positive MCQs, zero dupes', () {
      expect(marrowQBankRaw.length, equals(19), reason: 'Q-Bank must have exactly 19 core medical subjects');

      final allTopicIds = <String>{};
      int totalTopics = 0;
      int totalMcqs = 0;

      for (final s in marrowQBankRaw) {
        final sId = s['id'] as String;
        final chapters = (s['chapters'] as List<dynamic>?) ?? [];
        expect(chapters, isNotEmpty, reason: 'Subject $sId must have chapters');

        final sTopics = <Map<String, dynamic>>[];
        final seenTitles = <String>{};
        int lastAssigned = 0;

        for (final ch in chapters) {
          final chMap = ch as Map<String, dynamic>;
          final chName = chMap['name'] as String;
          expect(chName.trim(), equals(chName), reason: 'Untrimmed chapter name in $sId');
          expect(chName, isNotEmpty, reason: 'Empty chapter name in $sId');

          final topics = (chMap['topics'] as List<dynamic>?) ?? [];
          final declaredTopics = chMap['totalTopics'] as int?;
          expect(declaredTopics, equals(topics.length),
              reason: 'Declared topics mismatch in $sId -> $chName');

          for (final t in topics) {
            final tMap = t as Map<String, dynamic>;
            final tId = tMap['id'] as String;
            final title = tMap['title'] as String;
            final assignedNum = tMap['assignedNumber'] as int?;
            final mcqs = tMap['totalMcqs'] as int?;

            expect(tId.trim(), equals(tId), reason: 'Untrimmed ID: $tId');
            expect(title.trim(), equals(title), reason: 'Untrimmed title: $title');

            expect(allTopicIds.contains(tId), isFalse, reason: 'Duplicate ID: $tId');
            allTopicIds.add(tId);

            expect(_isFakeTitle(title), isFalse, reason: 'Fake topic detected in $sId: $title ($tId)');

            final normTitle = title.trim().toLowerCase();
            expect(seenTitles.contains(normTitle), isFalse,
                reason: 'Duplicate title in $sId: $title ($tId)');
            seenTitles.add(normTitle);

            expect(mcqs, isNotNull);
            expect(mcqs! > 0, isTrue, reason: 'Non-positive MCQs in $tId');
            expect(mcqs < 2000, isTrue, reason: 'Absurd MCQ count in $tId');

            expect(assignedNum, equals(lastAssigned + 1),
                reason: 'Non-contiguous sequence in $sId: expected #${lastAssigned + 1}, got #$assignedNum');
            lastAssigned = assignedNum!;

            sTopics.add(tMap);
            totalMcqs += mcqs;
          }
        }

        totalTopics += sTopics.length;
        final assignedList = sTopics.map((t) => t['assignedNumber'] as int).toList();
        final expectedList = List.generate(sTopics.length, (i) => i + 1);
        expect(assignedList, equals(expectedList));
      }

      expect(totalTopics, equals(835), reason: 'Q-Bank must contain exactly 835 topics');
      expect(totalMcqs, equals(16155), reason: 'Q-Bank must contain exactly 16,155 MCQs');
    });

    test('Strict edition separation: no Q-Bank collisions and isolated loaders with explicit editionId', () {
      final qbIds = <String>{};
      for (final s in marrowQBankRaw) {
        for (final ch in (s['chapters'] as List<dynamic>)) {
          for (final t in (ch['topics'] as List<dynamic>)) {
            qbIds.add(t['id'] as String);
          }
        }
      }

      final e8Ids = <String>{};
      for (final s in marrow8Raw) {
        for (final ch in (s['chapters'] as List<dynamic>)) {
          for (final v in (ch['videos'] as List<dynamic>)) {
            e8Ids.add(v['id'] as String);
          }
        }
      }

      final e65Ids = <String>{};
      for (final s in marrow65Raw) {
        for (final ch in (s['chapters'] as List<dynamic>)) {
          for (final v in (ch['videos'] as List<dynamic>)) {
            e65Ids.add(v['id'] as String);
          }
        }
      }

      // 1. Q-Bank IDs never collide with Video IDs
      expect(qbIds.intersection(e8Ids), isEmpty, reason: 'Q-Bank topic IDs must not collide with E8 videos');
      expect(qbIds.intersection(e65Ids), isEmpty, reason: 'Q-Bank topic IDs must not collide with E6.5 videos');

      // 2. Syllabus loaders tag each Subject and Video with its strict editionId
      final e8Subjects = loadMarrow8Syllabus();
      expect(e8Subjects.length, equals(20));
      for (final s in e8Subjects) {
        expect(s.editionId, equals('marrow_8'));
        for (final v in s.allVideos) {
          expect(v.editionId, equals('marrow_8'));
        }
      }

      final e65Subjects = loadMarrow65Syllabus();
      expect(e65Subjects.length, equals(20));
      for (final s in e65Subjects) {
        expect(s.editionId, equals('marrow_6_5'));
        for (final v in s.allVideos) {
          expect(v.editionId, equals('marrow_6_5'));
        }
      }

      // 3. Edition 6.5 ENT and Revision aliases properly map
      final e65Ent = e65Subjects.firstWhere((s) => s.id == 'ent');
      expect(e65Ent.displayName, equals('ENT'));
      expect(e65Ent.allQBanks, isNotEmpty, reason: 'Edition 6.5 ENT must have Q-Bank chapters attached via canonical alias');

      final e65Rev = e65Subjects.firstWhere((s) => s.id == 'e6_5_revision_videos');
      expect(e65Rev.displayName, equals('Revision Videos'));

      // 4. Curriculum sort year mapping for aliases
      expect(kSubjectYearMap['ent'], equals('3rd Year'));
      expect(kSubjectYearMap['e6_5_revision_videos'], equals('Revision'));
    });

    test('AppState partition isolation: mutations to one edition never affect another', () {
      var state = const AppState(
        activeEdition: 'marrow_8',
        editions: {
          'marrow_8': EditionState(
            completedVideos: {'medicine__v1': true},
          ),
          'marrow_6_5': EditionState(
            completedVideos: {'medicine__v2': true},
          ),
        },
      );

      // Verify initial separation
      expect(state.editions['marrow_8']!.completedVideos.containsKey('medicine__v1'), isTrue);
      expect(state.editions['marrow_8']!.completedVideos.containsKey('medicine__v2'), isFalse);
      expect(state.editions['marrow_6_5']!.completedVideos.containsKey('medicine__v2'), isTrue);
      expect(state.editions['marrow_6_5']!.completedVideos.containsKey('medicine__v1'), isFalse);

      // Mutate current edition (marrow_8)
      state = state.updateCurrentEdition((e) => e.copyWith(
        completedVideos: {...e.completedVideos, 'anatomy__v1': true},
      ));

      // marrow_8 updated, marrow_6_5 untouched
      expect(state.editions['marrow_8']!.completedVideos.containsKey('anatomy__v1'), isTrue);
      expect(state.editions['marrow_6_5']!.completedVideos.containsKey('anatomy__v1'), isFalse);

      // Switch to marrow_6_5 and mutate
      state = state.copyWith(activeEdition: 'marrow_6_5');
      state = state.updateCurrentEdition((e) => e.copyWith(
        completedVideos: {...e.completedVideos, 'pathology__v5': true},
      ));

      expect(state.editions['marrow_6_5']!.completedVideos.containsKey('pathology__v5'), isTrue);
      expect(state.editions['marrow_8']!.completedVideos.containsKey('pathology__v5'), isFalse);
    });
  });
}
