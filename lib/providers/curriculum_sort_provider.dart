import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

enum CurriculumSortMode {
  defaultOrder,
  mostRecent,
  yearWise,
}

/// Sequential MBBS curriculum years without clinical tags
const Map<String, String> kSubjectYearMap = {
  // 1st Year
  'anatomy': '1st Year',
  'physiology': '1st Year',
  'biochemistry': '1st Year',

  // 2nd Year
  'pathology': '2nd Year',
  'pharmacology': '2nd Year',
  'microbiology': '2nd Year',

  // 3rd Year
  'forensic_medicine': '3rd Year',
  'community_medicine': '3rd Year',
  'ophthalmology': '3rd Year',
  'otorhinolaryngology__ent_': '3rd Year',

  // Final Year
  'medicine': 'Final Year',
  'surgery': 'Final Year',
  'obstetrics___gynaecology': 'Final Year',
  'paediatrics': 'Final Year',
  'orthopaedics': 'Final Year',
  'dermatology': 'Final Year',
  'psychiatry': 'Final Year',
  'radiology': 'Final Year',
  'anaesthesia': 'Final Year',

  // Revision
  'revision_videos': 'Revision',
};

const List<String> kCurriculumYears = [
  '1st Year',
  '2nd Year',
  '3rd Year',
  'Final Year',
  'Revision',
];

class CurriculumSortNotifier extends StateNotifier<CurriculumSortMode> {
  CurriculumSortNotifier() : super(_initialMode());

  static CurriculumSortMode _initialMode() {
    final raw = StorageService.instance.getCurriculumSortMode();
    switch (raw) {
      case 'mostRecent':
        return CurriculumSortMode.mostRecent;
      case 'yearWise':
        return CurriculumSortMode.yearWise;
      default:
        return CurriculumSortMode.defaultOrder;
    }
  }

  void setMode(CurriculumSortMode mode) {
    state = mode;
    String raw = 'default';
    if (mode == CurriculumSortMode.mostRecent) raw = 'mostRecent';
    if (mode == CurriculumSortMode.yearWise) raw = 'yearWise';
    StorageService.instance.setCurriculumSortMode(raw);
  }
}

final curriculumSortProvider =
    StateNotifierProvider<CurriculumSortNotifier, CurriculumSortMode>((ref) {
  return CurriculumSortNotifier();
});

class RecentSubjectsNotifier extends StateNotifier<Map<String, int>> {
  RecentSubjectsNotifier()
      : super(StorageService.instance.getRecentSubjectTimestamps());

  void recordVisit(String subjectId) {
    final updated = Map<String, int>.from(state);
    final now = DateTime.now().millisecondsSinceEpoch;
    updated[subjectId] = now;
    state = updated;
    StorageService.instance.recordSubjectVisit(subjectId);
  }
}

final recentSubjectsProvider =
    StateNotifierProvider<RecentSubjectsNotifier, Map<String, int>>((ref) {
  return RecentSubjectsNotifier();
});
