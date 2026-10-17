import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/data/subjects_metadata.dart';
import 'package:modulix/models/syllabus.dart';
import 'package:modulix/providers/curriculum_sort_provider.dart';

void main() {
  group('Domain 3: Curriculum & Syllabus Tests', () {
    test('loadMarrow8Syllabus loads all subjects and chapters correctly', () {
      final subjects = loadMarrow8Syllabus();
      expect(subjects.isNotEmpty, isTrue);
      expect(subjects.length, greaterThanOrEqualTo(19));

      for (final s in subjects) {
        expect(s.id.isNotEmpty, isTrue);
        expect(s.name.isNotEmpty, isTrue);
        expect(s.displayName.isNotEmpty, isTrue);
        // Every subject must have at least one chapter
        expect(s.chapters.isNotEmpty, isTrue, reason: 'Subject ${s.id} should have chapters');
      }

      final anatomy = subjects.firstWhere((s) => s.id == 'anatomy');
      expect(anatomy.name, 'Anatomy');
      expect(anatomy.chapters.length, greaterThan(0));
      expect(anatomy.chapters.first.videos.isNotEmpty, isTrue);
      expect(anatomy.chapters.first.notes.isNotEmpty, isTrue);
    });

    test('loadMarrow65Syllabus loads all subjects with standard metadata', () {
      final subjects = loadMarrow65Syllabus();
      expect(subjects.isNotEmpty, isTrue);
      expect(subjects.length, greaterThanOrEqualTo(19));

      final physio = subjects.firstWhere((s) => s.id == 'physiology');
      expect(physio.displayName, isNotNull);
      expect(physio.accent, isNotNull);
      expect(physio.chapters.isNotEmpty, isTrue);
    });

    test('Curriculum sorting: yearWise groups all subjects into designated years', () {
      final subjects = loadMarrow8Syllabus();
      final Map<String, List<Subject>> yearGroups = {};
      for (final year in kCurriculumYears) {
        yearGroups[year] = [];
      }
      for (final s in subjects) {
        final year = kSubjectYearMap[s.id] ?? 'Final Year';
        yearGroups.putIfAbsent(year, () => []).add(s);
      }

      expect(yearGroups['1st Year']!.map((s) => s.id), containsAll(['anatomy', 'physiology', 'biochemistry']));
      expect(yearGroups['2nd Year']!.map((s) => s.id), containsAll(['pathology', 'pharmacology', 'microbiology']));
      expect(yearGroups['3rd Year']!.map((s) => s.id), containsAll(['forensic_medicine', 'community_medicine', 'ophthalmology', 'otorhinolaryngology__ent_']));
      expect(yearGroups['Final Year']!.map((s) => s.id), containsAll(['medicine', 'surgery', 'paediatrics']));
    });

    test('Curriculum sorting: mostRecent orders subjects by visit timestamp descending', () {
      final subjects = loadMarrow8Syllabus();
      final recentTimestamps = <String, int>{
        'anatomy': 100,
        'physiology': 500,
        'pathology': 300,
      };

      final sorted = List<Subject>.from(subjects);
      sorted.sort((a, b) {
        final timeA = recentTimestamps[a.id] ?? 0;
        final timeB = recentTimestamps[b.id] ?? 0;
        if (timeA != timeB) {
          return timeB.compareTo(timeA); // descending
        }
        return subjects.indexOf(a).compareTo(subjects.indexOf(b));
      });

      expect(sorted[0].id, 'physiology');
      expect(sorted[1].id, 'pathology');
      expect(sorted[2].id, 'anatomy');
    });
  });
}
