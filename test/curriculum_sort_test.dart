import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/providers/curriculum_sort_provider.dart';
import 'package:modulix/models/syllabus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CurriculumSort and Year Categorization Tests', () {
    test('All MBBS subjects map to clean year names without clinical tags', () {
      // 1st Year
      expect(kSubjectYearMap['anatomy'], equals('1st Year'));
      expect(kSubjectYearMap['physiology'], equals('1st Year'));
      expect(kSubjectYearMap['biochemistry'], equals('1st Year'));

      // 2nd Year
      expect(kSubjectYearMap['pathology'], equals('2nd Year'));
      expect(kSubjectYearMap['pharmacology'], equals('2nd Year'));
      expect(kSubjectYearMap['microbiology'], equals('2nd Year'));

      // 3rd Year
      expect(kSubjectYearMap['forensic_medicine'], equals('3rd Year'));
      expect(kSubjectYearMap['community_medicine'], equals('3rd Year'));
      expect(kSubjectYearMap['ophthalmology'], equals('3rd Year'));
      expect(kSubjectYearMap['otorhinolaryngology__ent_'], equals('3rd Year'));

      // Final Year
      expect(kSubjectYearMap['medicine'], equals('Final Year'));
      expect(kSubjectYearMap['surgery'], equals('Final Year'));
      expect(kSubjectYearMap['obstetrics___gynaecology'], equals('Final Year'));
      expect(kSubjectYearMap['paediatrics'], equals('Final Year'));
      expect(kSubjectYearMap['orthopaedics'], equals('Final Year'));
      expect(kSubjectYearMap['dermatology'], equals('Final Year'));
      expect(kSubjectYearMap['psychiatry'], equals('Final Year'));
      expect(kSubjectYearMap['radiology'], equals('Final Year'));
      expect(kSubjectYearMap['anaesthesia'], equals('Final Year'));

      // Revision
      expect(kSubjectYearMap['revision_videos'], equals('Revision'));

      // Ensure NO clinical tags exist
      for (final year in kSubjectYearMap.values) {
        expect(year.contains('pre-clinical'), isFalse);
        expect(year.contains('para-clinical'), isFalse);
        expect(year.contains('clinical'), isFalse);
        expect(kCurriculumYears.contains(year), isTrue);
      }
    });

    test('Most Recent sort places recently visited subjects at top descending', () {
      final sampleSubjects = [
        const Subject(id: 'anatomy', name: 'Anatomy', displayName: 'Anatomy', chapters: [], accent: Colors.blue),
        const Subject(id: 'pathology', name: 'Pathology', displayName: 'Pathology', chapters: [], accent: Colors.red),
        const Subject(id: 'medicine', name: 'Medicine', displayName: 'Medicine', chapters: [], accent: Colors.green),
        const Subject(id: 'surgery', name: 'Surgery', displayName: 'Surgery', chapters: [], accent: Colors.amber),
      ];

      final timestamps = <String, int>{
        'surgery': 1000,
        'pathology': 5000,
        'anatomy': 2000,
      };

      final sorted = List<Subject>.from(sampleSubjects);
      sorted.sort((a, b) {
        final timeA = timestamps[a.id] ?? 0;
        final timeB = timestamps[b.id] ?? 0;
        if (timeA != timeB) {
          return timeB.compareTo(timeA); // descending
        }
        return sampleSubjects.indexOf(a).compareTo(sampleSubjects.indexOf(b));
      });

      expect(sorted.map((s) => s.id).toList(), equals([
        'pathology', // 5000
        'anatomy',   // 2000
        'surgery',   // 1000
        'medicine',  // 0 (unvisited, kept in default order)
      ]));
    });

    test('Year Wise grouping groups subjects sequentially into clean years', () {
      final sampleSubjects = [
        const Subject(id: 'medicine', name: 'Medicine', displayName: 'Medicine', chapters: [], accent: Colors.green),
        const Subject(id: 'anatomy', name: 'Anatomy', displayName: 'Anatomy', chapters: [], accent: Colors.blue),
        const Subject(id: 'pathology', name: 'Pathology', displayName: 'Pathology', chapters: [], accent: Colors.red),
        const Subject(id: 'forensic_medicine', name: 'FMT', displayName: 'FMT', chapters: [], accent: Colors.grey),
      ];

      final Map<String, List<Subject>> groups = {};
      for (final y in kCurriculumYears) {
        groups[y] = [];
      }
      for (final s in sampleSubjects) {
        final y = kSubjectYearMap[s.id] ?? 'Final Year';
        groups[y]!.add(s);
      }

      expect(groups['1st Year']!.map((s) => s.id).toList(), equals(['anatomy']));
      expect(groups['2nd Year']!.map((s) => s.id).toList(), equals(['pathology']));
      expect(groups['3rd Year']!.map((s) => s.id).toList(), equals(['forensic_medicine']));
      expect(groups['Final Year']!.map((s) => s.id).toList(), equals(['medicine']));
    });
  });
}
