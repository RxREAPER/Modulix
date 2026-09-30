class TimeLog {
  final String id;
  final String subjectId;
  final String? topicId;
  final String topicType; // 'video' | 'qbank' | 'notes' | 'standalone'
  final String topicTitle;
  final String chapterName;
  final int durationSecs;
  final DateTime timestamp;

  const TimeLog({
    required this.id,
    required this.subjectId,
    this.topicId,
    required this.topicType,
    required this.topicTitle,
    this.chapterName = '',
    required this.durationSecs,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'topicId': topicId,
        'topicType': topicType,
        'topicTitle': topicTitle,
        'chapterName': chapterName,
        'durationSecs': durationSecs,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TimeLog.fromJson(Map<String, dynamic> json) => TimeLog(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String,
        topicId: json['topicId'] as String?,
        topicType: json['topicType'] as String? ?? 'standalone',
        topicTitle: json['topicTitle'] as String? ?? '',
        chapterName: json['chapterName'] as String? ?? '',
        durationSecs: json['durationSecs'] as int? ?? 0,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      );
}
