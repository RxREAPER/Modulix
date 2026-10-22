import 'package:flutter/material.dart';
import '../models/syllabus.dart';
import 'syllabus_marrow8.dart';
import 'syllabus_marrow65.dart';
import 'syllabus_qbank.dart';

// ─── Subject palette ─────────────────────────────────────────────────────────
// Each subject gets a deterministic accent color + icon glyph

class SubjectMeta {
  final Color accent;
  final Color bgLight;
  final Color bgDark;
  final IconData icon;
  final String displayName;

  const SubjectMeta({
    required this.accent,
    required this.bgLight,
    required this.bgDark,
    required this.icon,
    required this.displayName,
  });
}

const _subjectMetaMap = <String, SubjectMeta>{
  'anatomy': SubjectMeta(
    accent: Color(0xFF3B82F6),
    bgLight: Color(0xFFEFF6FF),
    bgDark: Color(0xFF1E3A5F),
    icon: Icons.accessibility_new_rounded,
    displayName: 'Anatomy',
  ),
  'physiology': SubjectMeta(
    accent: Color(0xFF10B981),
    bgLight: Color(0xFFECFDF5),
    bgDark: Color(0xFF064E3B),
    icon: Icons.favorite_rounded,
    displayName: 'Physiology',
  ),
  'biochemistry': SubjectMeta(
    accent: Color(0xFF8B5CF6),
    bgLight: Color(0xFFF5F3FF),
    bgDark: Color(0xFF2E1065),
    icon: Icons.science_rounded,
    displayName: 'Biochemistry',
  ),
  'pathology': SubjectMeta(
    accent: Color(0xFFEF4444),
    bgLight: Color(0xFFFEF2F2),
    bgDark: Color(0xFF450A0A),
    icon: Icons.biotech_rounded,
    displayName: 'Pathology',
  ),
  'pharmacology': SubjectMeta(
    accent: Color(0xFFF97316),
    bgLight: Color(0xFFFFF7ED),
    bgDark: Color(0xFF431407),
    icon: Icons.medication_rounded,
    displayName: 'Pharmacology',
  ),
  'microbiology': SubjectMeta(
    accent: Color(0xFF06B6D4),
    bgLight: Color(0xFFECFEFF),
    bgDark: Color(0xFF083344),
    icon: Icons.coronavirus_rounded,
    displayName: 'Microbiology',
  ),
  'community_medicine': SubjectMeta(
    accent: Color(0xFF14B8A6),
    bgLight: Color(0xFFF0FDFA),
    bgDark: Color(0xFF042F2E),
    icon: Icons.people_rounded,
    displayName: 'Community Medicine',
  ),
  'forensic_medicine': SubjectMeta(
    accent: Color(0xFF64748B),
    bgLight: Color(0xFFF8FAFC),
    bgDark: Color(0xFF0F172A),
    icon: Icons.gavel_rounded,
    displayName: 'Forensic Medicine',
  ),
  'ophthalmology': SubjectMeta(
    accent: Color(0xFF6366F1),
    bgLight: Color(0xFFEEF2FF),
    bgDark: Color(0xFF1E1B4B),
    icon: Icons.visibility_rounded,
    displayName: 'Ophthalmology',
  ),
  'otorhinolaryngology__ent_': SubjectMeta(
    accent: Color(0xFF84CC16),
    bgLight: Color(0xFFF7FEE7),
    bgDark: Color(0xFF1A2E05),
    icon: Icons.hearing_rounded,
    displayName: 'ENT',
  ),
  'anaesthesia': SubjectMeta(
    accent: Color(0xFFEC4899),
    bgLight: Color(0xFFFDF2F8),
    bgDark: Color(0xFF500724),
    icon: Icons.air_rounded,
    displayName: 'Anaesthesia',
  ),
  'dermatology': SubjectMeta(
    accent: Color(0xFFD946EF),
    bgLight: Color(0xFFFDF4FF),
    bgDark: Color(0xFF3B0764),
    icon: Icons.face_rounded,
    displayName: 'Dermatology',
  ),
  'psychiatry': SubjectMeta(
    accent: Color(0xFF7C3AED),
    bgLight: Color(0xFFF5F3FF),
    bgDark: Color(0xFF2E1065),
    icon: Icons.psychology_rounded,
    displayName: 'Psychiatry',
  ),
  'radiology': SubjectMeta(
    accent: Color(0xFF0EA5E9),
    bgLight: Color(0xFFF0F9FF),
    bgDark: Color(0xFF082F49),
    icon: Icons.radio_button_checked_rounded,
    displayName: 'Radiology',
  ),
  'medicine': SubjectMeta(
    accent: Color(0xFF059669),
    bgLight: Color(0xFFECFDF5),
    bgDark: Color(0xFF064E3B),
    icon: Icons.local_hospital_rounded,
    displayName: 'Medicine',
  ),
  'surgery': SubjectMeta(
    accent: Color(0xFFF43F5E),
    bgLight: Color(0xFFFFF1F2),
    bgDark: Color(0xFF4C0519),
    icon: Icons.medical_services_rounded,
    displayName: 'Surgery',
  ),
  'orthopaedics': SubjectMeta(
    accent: Color(0xFFB45309),
    bgLight: Color(0xFFFFFBEB),
    bgDark: Color(0xFF451A03),
    icon: Icons.elderly_rounded,
    displayName: 'Orthopaedics',
  ),
  'paediatrics': SubjectMeta(
    accent: Color(0xFFF59E0B),
    bgLight: Color(0xFFFFFBEB),
    bgDark: Color(0xFF451A03),
    icon: Icons.child_care_rounded,
    displayName: 'Paediatrics',
  ),
  'obstetrics___gynaecology': SubjectMeta(
    accent: Color(0xFFEC4899),
    bgLight: Color(0xFFFDF2F8),
    bgDark: Color(0xFF500724),
    icon: Icons.pregnant_woman_rounded,
    displayName: 'Obs & Gynae',
  ),
  'revision_videos': SubjectMeta(
    accent: Color(0xFF6C3BAA),
    bgLight: Color(0xFFF5F3FF),
    bgDark: Color(0xFF2E1065),
    icon: Icons.replay_rounded,
    displayName: 'Revision Videos',
  ),
};

SubjectMeta subjectMeta(String subjectId) {
  return _subjectMetaMap[subjectId] ??
      const SubjectMeta(
        accent: Color(0xFF6C3BAA),
        bgLight: Color(0xFFF5F3FF),
        bgDark: Color(0xFF2E1065),
        icon: Icons.book_rounded,
        displayName: 'Subject',
      );
}

// ─── Deterministic tile color (mirrors JS mvTileColor) ────────────────────────

const _tileColors = [
  Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFF59E0B),
  Color(0xFF84CC16), Color(0xFF10B981), Color(0xFF06B6D4),
  Color(0xFF3B82F6), Color(0xFF6366F1), Color(0xFF8B5CF6),
  Color(0xFFD946EF), Color(0xFFEC4899), Color(0xFF14B8A6),
];

Color videoTileColor(String videoId) {
  int h = 5381;
  for (final c in videoId.codeUnits) {
    h = ((h << 5) + h + c) & 0x7FFFFFFF;
  }
  return _tileColors[h % _tileColors.length];
}

String _formatUnitNotesTitle(String chapterName) {
  final words = chapterName.trim().split(RegExp(r'\s+'));
  final titleWords = words.map((w) {
    if (w.isEmpty) return '';
    final lower = w.toLowerCase();
    if (lower == 'and' || lower == '&' || lower == 'of' || lower == 'the' || lower == 'to' || lower == 'in') {
      return lower;
    }
    return lower[0].toUpperCase() + lower.substring(1);
  }).join(' ');
  return '$titleWords Notes';
}

// ─── Q-Bank Loader ──────────────────────────────────────────────────────────

final Map<String, List<Chapter>> _qbankChaptersMap = () {
  final map = <String, List<Chapter>>{};
  for (final subjMap in marrowQBankRaw) {
    final subjId = subjMap['id'] as String;
    final chRaw = (subjMap['chapters'] as List<dynamic>?) ?? [];
    final chapters = chRaw.map((c) {
      final chMap = c as Map<String, dynamic>;
      final chName = chMap['name'] as String? ?? '';
      final tRaw = (chMap['topics'] as List<dynamic>?) ?? [];
      final topics = tRaw
          .map((t) => QBankTopic.fromMap(t as Map<String, dynamic>, subjId, chName))
          .toList();
      return Chapter(
        name: chName,
        videos: const [],
        qbanks: topics,
        notes: const [],
      );
    }).toList();
    map[subjId] = chapters;
  }
  return map;
}();

// ─── Loaders ─────────────────────────────────────────────────────────────

List<Subject> loadMarrow8Syllabus() => _buildSubjectsFromRaw(marrow8Raw);
List<Subject> loadMarrow65Syllabus() => _buildSubjectsFromRaw(marrow65Raw);

String _canonicalChapterKey(String name) {
  return name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '')
      .replaceAll('and', '')
      .replaceAll('&', '');
}

List<Subject> _buildSubjectsFromRaw(List<Map<String, dynamic>> raw) {
  return raw.map((subjectMap) {
    final id = subjectMap['id'] as String;
    final name = subjectMap['subject'] as String? ?? id;
    final meta = subjectMeta(id);
    final chaptersRaw =
        (subjectMap['chapters'] as List<dynamic>?) ?? [];

    final qbankChapters = _qbankChaptersMap[id] ?? const <Chapter>[];
    final matchedQBankNames = <String>{};

    final videoChapters = chaptersRaw.asMap().entries.map((chEntry) {
      final chIndex = chEntry.key;
      final chapterMap = chEntry.value as Map<String, dynamic>;
      final chapterName = chapterMap['name'] as String? ?? '';
      final videosRaw =
          (chapterMap['videos'] as List<dynamic>?) ?? [];
      final videos = videosRaw
          .map((vMap) => Video.fromMap(vMap as Map<String, dynamic>, id, chapterName))
          .toList();

      // Find matching Q-Bank topics for this chapter
      final chKey = _canonicalChapterKey(chapterName);
      final matchedTopics = <QBankTopic>[];
      for (final qbCh in qbankChapters) {
        final qbKey = _canonicalChapterKey(qbCh.name);
        if (qbKey == chKey ||
            (qbKey.length > 4 && chKey.contains(qbKey)) ||
            (chKey.length > 4 && qbKey.contains(chKey))) {
          matchedTopics.addAll(qbCh.qbanks);
          matchedQBankNames.add(qbCh.name);
        }
      }

      // Exactly one Notes topic per unit, named after the unit
      final notes = <NotesItem>[
        NotesItem(
          id: 'note_${id}_ch$chIndex',
          title: _formatUnitNotesTitle(chapterName),
          subjectId: id,
          chapterName: chapterName,
          pages: 15,
          isCustom: false,
        ),
      ];

      return Chapter(
        name: chapterName,
        videos: videos,
        qbanks: matchedTopics,
        notes: notes,
      );
    }).toList();

    // Any remaining Q-Bank chapters that did not match video chapters are added as dedicated units
    final unMatchedUnits = <Chapter>[];
    for (int qbIdx = 0; qbIdx < qbankChapters.length; qbIdx++) {
      final qbCh = qbankChapters[qbIdx];
      if (!matchedQBankNames.contains(qbCh.name)) {
        unMatchedUnits.add(
          Chapter(
            name: qbCh.name,
            videos: const [],
            qbanks: qbCh.qbanks,
            notes: [
              NotesItem(
                id: 'note_${id}_qb_$qbIdx',
                title: _formatUnitNotesTitle(qbCh.name),
                subjectId: id,
                chapterName: qbCh.name,
                pages: 10,
                isCustom: false,
              ),
            ],
          ),
        );
      }
    }

    final allChapters = [...videoChapters, ...unMatchedUnits];

    return Subject(
      id: id,
      name: name,
      displayName: meta.displayName,
      chapters: allChapters,
      qbankChapters: qbankChapters,
      accent: meta.accent,
    );
  }).toList();
}
