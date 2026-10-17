import 'package:flutter/material.dart' show Color;

/// Represents a single lecture/video in the syllabus
class Video {
  final String id;
  final String title;
  final String subjectId;
  final String chapterName;
  final int durationMins;
  final int durationSecs;
  final int serialNumber;
  final int? assignedNumber;

  const Video({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.chapterName,
    this.durationMins = 0,
    this.durationSecs = 0,
    required this.serialNumber,
    this.assignedNumber,
  });

  factory Video.fromMap(Map<String, dynamic> map, String subjectId, [String? fallbackChapterName]) {
    final assignedNo = map['assignedNumber'] as int?;
    final rawVideoNumber = map['videoNumber'] as String? ?? '';
    int parsedNumber = 0;
    if (rawVideoNumber.isNotEmpty) {
      parsedNumber = int.tryParse(rawVideoNumber.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }
    if (parsedNumber == 0) {
      final sNo = map['sNo'] as int? ?? 0;
      if (sNo != 0) {
        parsedNumber = sNo;
      } else {
        final idStr = map['id'] as String? ?? '';
        final vMatch = RegExp(r'__v(\d+)').firstMatch(idStr);
        if (vMatch != null) {
          parsedNumber = int.tryParse(vMatch.group(1)!) ?? 0;
        }
      }
    }

    final rawChapter = map['chapterName'] as String? ?? '';
    final resolvedChapter = rawChapter.isNotEmpty ? rawChapter : (fallbackChapterName ?? '');

    return Video(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      subjectId: subjectId,
      chapterName: resolvedChapter,
      durationMins: map['durationMins'] as int? ?? 0,
      durationSecs: map['durationSecs'] as int? ?? 0,
      serialNumber: assignedNo ?? parsedNumber,
      assignedNumber: assignedNo,
    );
  }

  double get totalMinutes => durationMins + durationSecs / 60;

  String get durationLabel {
    if (durationMins == 0 && durationSecs == 0) return '';
    if (durationSecs == 0) return '${durationMins}m';
    return '${durationMins}m ${durationSecs}s';
  }
}

/// Represents a Q-Bank topic/module
class QBankTopic {
  final String id;
  final String title;
  final String subjectId;
  final String chapterName;
  final int totalMcqs;
  final int serialNumber;
  final int? assignedNumber;

  const QBankTopic({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.chapterName,
    required this.totalMcqs,
    required this.serialNumber,
    this.assignedNumber,
  });

  factory QBankTopic.fromMap(Map<String, dynamic> map, String subjectId, [String? fallbackChapterName]) {
    final assignedNo = map['assignedNumber'] as int?;
    final sNo = map['serialNumber'] as int? ?? assignedNo ?? 0;
    return QBankTopic(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      subjectId: subjectId,
      chapterName: (map['chapterName'] as String?) ?? (fallbackChapterName ?? ''),
      totalMcqs: map['totalMcqs'] as int? ?? 0,
      serialNumber: sNo,
      assignedNumber: assignedNo ?? sNo,
    );
  }
}

/// Represents a Notes/Textbook resource
class NotesItem {
  final String id;
  final String title;
  final String subjectId;
  final String chapterName;
  final int pages;
  final bool isCustom;

  const NotesItem({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.chapterName,
    this.pages = 10,
    this.isCustom = false,
  });
}

/// A chapter (unit) within a subject
class Chapter {
  final String name;
  final List<Video> videos;
  final List<QBankTopic> qbanks;
  final List<NotesItem> notes;

  const Chapter({
    required this.name,
    required this.videos,
    this.qbanks = const [],
    this.notes = const [],
  });

  int get totalVideos => videos.length;
  int get totalQBanks => qbanks.length;
  int get totalNotes => notes.length;

  double get totalMinutes => videos.fold<double>(0.0, (acc, v) => acc + v.totalMinutes);

  double get totalHours => totalMinutes / 60;

  String get durationLabel {
    final mins = totalMinutes.round();
    if (mins == 0) return '';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

/// A subject in the syllabus
class Subject {
  final String id;
  final String name;
  final String displayName;
  final List<Chapter> chapters;
  final List<Chapter> qbankChapters;
  final Color accent;

  const Subject({
    required this.id,
    required this.name,
    required this.displayName,
    required this.chapters,
    this.qbankChapters = const [],
    required this.accent,
  });

  Color get accentColor => accent;

  List<Video> get allVideos => chapters.expand((c) => c.videos).toList();
  List<QBankTopic> get allQBanks =>
      (qbankChapters.isNotEmpty ? qbankChapters : chapters).expand((c) => c.qbanks).toList();
  List<NotesItem> get allNotes => chapters.expand((c) => c.notes).toList();

  int get totalVideos => allVideos.length;
  int get totalQBanks => allQBanks.length;
  int get totalNotes => allNotes.length;

  double get totalHours {
    final totalMins = allVideos.fold<double>(0.0, (acc, v) => acc + v.totalMinutes);
    return totalMins / 60;
  }
}
