import 'package:flutter/material.dart' show Color;

int _safeInt(dynamic val, [int fallback = 0]) {
  if (val is num) return val.toInt();
  if (val is String) {
    return int.tryParse(val) ?? fallback;
  }
  return fallback;
}

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
    final assignedNo = map['assignedNumber'] != null ? _safeInt(map['assignedNumber']) : null;
    final rawVideoNumber = map['videoNumber']?.toString() ?? '';
    int parsedNumber = 0;
    if (rawVideoNumber.isNotEmpty) {
      parsedNumber = int.tryParse(rawVideoNumber.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }
    if (parsedNumber == 0) {
      final sNo = _safeInt(map['sNo']);
      if (sNo != 0) {
        parsedNumber = sNo;
      } else {
        final idStr = map['id']?.toString() ?? '';
        final vMatch = RegExp(r'__v(\d+)').firstMatch(idStr);
        if (vMatch != null) {
          parsedNumber = int.tryParse(vMatch.group(1)!) ?? 0;
        }
      }
    }

    final rawChapter = map['chapterName']?.toString() ?? '';
    final resolvedChapter = rawChapter.isNotEmpty ? rawChapter : (fallbackChapterName ?? '');

    return Video(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      subjectId: subjectId,
      chapterName: resolvedChapter,
      durationMins: _safeInt(map['durationMins']),
      durationSecs: _safeInt(map['durationSecs']),
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
    final assignedNo = map['assignedNumber'] != null ? _safeInt(map['assignedNumber']) : null;
    final sNo = _safeInt(map['serialNumber'], assignedNo ?? 0);
    return QBankTopic(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      subjectId: subjectId,
      chapterName: (map['chapterName']?.toString()) ?? (fallbackChapterName ?? ''),
      totalMcqs: _safeInt(map['totalMcqs']),
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

  double get totalMinutes {
    double sum = 0.0;
    for (final v in videos) {
      sum += v.totalMinutes;
    }
    return sum;
  }

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

  int get totalMcqs {
    int sum = 0;
    for (final q in qbanks) {
      sum += q.totalMcqs;
    }
    return sum;
  }
  int get totalItems => totalVideos + totalQBanks + totalNotes;

  int completedCount({
    required Map<String, dynamic> completedVideos,
    required Map<String, dynamic> completedQBanks,
    required Map<String, dynamic> completedNotes,
  }) {
    int count = 0;
    for (final v in videos) {
      if (completedVideos.containsKey(v.id)) count++;
    }
    for (final q in qbanks) {
      if (completedQBanks.containsKey(q.id)) count++;
    }
    for (final n in notes) {
      if (completedNotes.containsKey(n.id)) count++;
    }
    return count;
  }

  double completionRatio({
    required Map<String, dynamic> completedVideos,
    required Map<String, dynamic> completedQBanks,
    required Map<String, dynamic> completedNotes,
  }) {
    if (totalItems == 0) return 0.0;
    final done = completedCount(
      completedVideos: completedVideos,
      completedQBanks: completedQBanks,
      completedNotes: completedNotes,
    );
    return (done / totalItems).clamp(0.0, 1.0);
  }
}

final _allVideosExpando = Expando<List<Video>>('allVideos');
final _allQBanksExpando = Expando<List<QBankTopic>>('allQBanks');
final _allNotesExpando = Expando<List<NotesItem>>('allNotes');
final _totalVideosExpando = Expando<int>('totalVideos');
final _totalQBanksExpando = Expando<int>('totalQBanks');
final _totalNotesExpando = Expando<int>('totalNotes');
final _totalHoursExpando = Expando<double>('totalHours');

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

  List<Video> get allVideos {
    final cached = _allVideosExpando[this];
    if (cached != null) return cached;
    final list = List<Video>.unmodifiable(chapters.expand((c) => c.videos));
    _allVideosExpando[this] = list;
    return list;
  }

  List<QBankTopic> get allQBanks {
    final cached = _allQBanksExpando[this];
    if (cached != null) return cached;
    final list = List<QBankTopic>.unmodifiable(
      (qbankChapters.isNotEmpty ? qbankChapters : chapters).expand((c) => c.qbanks),
    );
    _allQBanksExpando[this] = list;
    return list;
  }

  List<NotesItem> get allNotes {
    final cached = _allNotesExpando[this];
    if (cached != null) return cached;
    final list = List<NotesItem>.unmodifiable(chapters.expand((c) => c.notes));
    _allNotesExpando[this] = list;
    return list;
  }

  int get totalVideos {
    final cached = _totalVideosExpando[this];
    if (cached != null) return cached;
    int sum = 0;
    for (final c in chapters) {
      sum += c.videos.length;
    }
    _totalVideosExpando[this] = sum;
    return sum;
  }

  int get totalQBanks {
    final cached = _totalQBanksExpando[this];
    if (cached != null) return cached;
    final source = qbankChapters.isNotEmpty ? qbankChapters : chapters;
    int sum = 0;
    for (final c in source) {
      sum += c.qbanks.length;
    }
    _totalQBanksExpando[this] = sum;
    return sum;
  }

  int get totalNotes {
    final cached = _totalNotesExpando[this];
    if (cached != null) return cached;
    int sum = 0;
    for (final c in chapters) {
      sum += c.notes.length;
    }
    _totalNotesExpando[this] = sum;
    return sum;
  }

  double get totalHours {
    final cached = _totalHoursExpando[this];
    if (cached != null) return cached;
    double totalMins = 0.0;
    for (final c in chapters) {
      for (final v in c.videos) {
        totalMins += v.totalMinutes;
      }
    }
    final hours = totalMins / 60;
    _totalHoursExpando[this] = hours;
    return hours;
  }
}
