/// The user's single subject study plan
class StudyPlan {
  final String targetSubject;      // subject id
  final String targetDate;         // ISO date string
  final int? videosPerDay;
  final List<String> targetUnits;  // chapter names (empty = whole subject)
  final String? focusChapterName;
  final double dailyHours;
  final int revisionCycles;

  const StudyPlan({
    this.targetSubject = '',
    this.targetDate = '',
    this.videosPerDay,
    this.targetUnits = const [],
    this.focusChapterName,
    this.dailyHours = 4.0,
    this.revisionCycles = 1,
  });

  bool get isConfigured =>
      targetSubject.isNotEmpty && targetDate.isNotEmpty && videosPerDay != null;

  StudyPlan copyWith({
    String? targetSubject,
    String? targetDate,
    int? videosPerDay,
    List<String>? targetUnits,
    String? focusChapterName,
    double? dailyHours,
    int? revisionCycles,
  }) {
    return StudyPlan(
      targetSubject: targetSubject ?? this.targetSubject,
      targetDate: targetDate ?? this.targetDate,
      videosPerDay: videosPerDay ?? this.videosPerDay,
      targetUnits: targetUnits ?? this.targetUnits,
      focusChapterName: focusChapterName ?? this.focusChapterName,
      dailyHours: dailyHours ?? this.dailyHours,
      revisionCycles: revisionCycles ?? this.revisionCycles,
    );
  }

  Map<String, dynamic> toJson() => {
        'targetSubject': targetSubject,
        'targetDate': targetDate,
        'videosPerDay': videosPerDay,
        'targetUnits': targetUnits,
        'focusChapterName': focusChapterName,
        'dailyHours': dailyHours,
        'revisionCycles': revisionCycles,
      };

  factory StudyPlan.fromJson(Map<String, dynamic> json) => StudyPlan(
        targetSubject: json['targetSubject'] as String? ?? '',
        targetDate: json['targetDate'] as String? ?? '',
        videosPerDay: json['videosPerDay'] as int?,
        targetUnits: (json['targetUnits'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        focusChapterName: json['focusChapterName'] as String?,
        dailyHours: (json['dailyHours'] as num?)?.toDouble() ?? 4.0,
        revisionCycles: json['revisionCycles'] as int? ?? 1,
      );

  static const empty = StudyPlan();
}

/// Per-edition state partition (mirrors JS edition partitions in schema v4)
class EditionState {
  final StudyPlan plan;
  final Map<String, dynamic> completedVideos; // videoId → ISO timestamp or true
  final Map<String, dynamic> completedQBanks; // qbankId → ISO timestamp or true
  final Map<String, dynamic> completedNotes;  // noteId → ISO timestamp or true
  final Map<String, int> dailyHistory;        // dateKey → count
  final List<String> bulkCompletedChapters;
  final List<String> queueBatchVideoIds;
  final List<String> staleBatchVideoIds;
  final int queueCompletedInBatch;

  const EditionState({
    this.plan = StudyPlan.empty,
    this.completedVideos = const {},
    this.completedQBanks = const {},
    this.completedNotes = const {},
    this.dailyHistory = const {},
    this.bulkCompletedChapters = const [],
    this.queueBatchVideoIds = const [],
    this.staleBatchVideoIds = const [],
    this.queueCompletedInBatch = 0,
  });

  EditionState copyWith({
    StudyPlan? plan,
    Map<String, dynamic>? completedVideos,
    Map<String, dynamic>? completedQBanks,
    Map<String, dynamic>? completedNotes,
    Map<String, int>? dailyHistory,
    List<String>? bulkCompletedChapters,
    List<String>? queueBatchVideoIds,
    List<String>? staleBatchVideoIds,
    int? queueCompletedInBatch,
  }) {
    return EditionState(
      plan: plan ?? this.plan,
      completedVideos: completedVideos ?? this.completedVideos,
      completedQBanks: completedQBanks ?? this.completedQBanks,
      completedNotes: completedNotes ?? this.completedNotes,
      dailyHistory: dailyHistory ?? this.dailyHistory,
      bulkCompletedChapters: bulkCompletedChapters ?? this.bulkCompletedChapters,
      queueBatchVideoIds: queueBatchVideoIds ?? this.queueBatchVideoIds,
      staleBatchVideoIds: staleBatchVideoIds ?? this.staleBatchVideoIds,
      queueCompletedInBatch: queueCompletedInBatch ?? this.queueCompletedInBatch,
    );
  }

  Map<String, dynamic> toJson() => {
        'plan': plan.toJson(),
        'completedVideos': completedVideos,
        'completedQBanks': completedQBanks,
        'completedNotes': completedNotes,
        'dailyHistory': dailyHistory,
        'bulkCompletedChapters': bulkCompletedChapters,
        'queueBatchVideoIds': queueBatchVideoIds,
        'staleBatchVideoIds': staleBatchVideoIds,
        'queueCompletedInBatch': queueCompletedInBatch,
      };

  factory EditionState.fromJson(Map<String, dynamic> json) => EditionState(
        plan: json['plan'] != null
            ? StudyPlan.fromJson(json['plan'] as Map<String, dynamic>)
            : StudyPlan.empty,
        completedVideos:
            (json['completedVideos'] as Map<String, dynamic>?) ?? {},
        completedQBanks:
            (json['completedQBanks'] as Map<String, dynamic>?) ?? {},
        completedNotes:
            (json['completedNotes'] as Map<String, dynamic>?) ?? {},
        dailyHistory: (json['dailyHistory'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as int)) ??
            {},
        bulkCompletedChapters:
            (json['bulkCompletedChapters'] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                [],
        queueBatchVideoIds:
            (json['queueBatchVideoIds'] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                [],
        staleBatchVideoIds:
            (json['staleBatchVideoIds'] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                [],
        queueCompletedInBatch: json['queueCompletedInBatch'] as int? ?? 0,
      );

  static const empty = EditionState();
}

/// Root app state
class AppState {
  final bool onboardingDone;
  final String doctorName;
  final String activeEdition;   // 'marrow_8' | 'marrow_6_5'
  final ThemePref themePref;
  final String accentColorId;   // 'indigo' | 'coral' | 'emerald' | 'amber' | 'violet' | 'rose'
  final int dayStartHour;       // e.g. 5 for 5:00 AM
  final bool dailyReminderEnabled;
  final String noriPropId; // 'none' | 'stethoscope' | 'glasses' | 'coffee' | 'headphones' | 'nightcap' | 'crown'
  final int noriInteractions; // total times petted/tapped
  final Map<String, EditionState> editions; // keyed by edition id

  const AppState({
    this.onboardingDone = false,
    this.doctorName = 'Dr',
    this.activeEdition = 'marrow_8',
    this.themePref = ThemePref.system,
    this.accentColorId = 'indigo',
    this.dayStartHour = 5,
    this.dailyReminderEnabled = true,
    this.noriPropId = 'stethoscope',
    this.noriInteractions = 0,
    this.editions = const {},
  });

  EditionState get currentEdition =>
      editions[activeEdition] ?? const EditionState();

  AppState copyWith({
    bool? onboardingDone,
    String? doctorName,
    String? activeEdition,
    ThemePref? themePref,
    String? accentColorId,
    int? dayStartHour,
    bool? dailyReminderEnabled,
    String? noriPropId,
    int? noriInteractions,
    Map<String, EditionState>? editions,
  }) {
    return AppState(
      onboardingDone: onboardingDone ?? this.onboardingDone,
      doctorName: doctorName ?? this.doctorName,
      activeEdition: activeEdition ?? this.activeEdition,
      themePref: themePref ?? this.themePref,
      accentColorId: accentColorId ?? this.accentColorId,
      dayStartHour: dayStartHour ?? this.dayStartHour,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      noriPropId: noriPropId ?? this.noriPropId,
      noriInteractions: noriInteractions ?? this.noriInteractions,
      editions: editions ?? this.editions,
    );
  }

  AppState withEdition(String editionId, EditionState edState) {
    return copyWith(editions: {...editions, editionId: edState});
  }

  AppState updateCurrentEdition(EditionState Function(EditionState) updater) {
    final updated = updater(currentEdition);
    return withEdition(activeEdition, updated);
  }

  Map<String, dynamic> toJson() => {
        'onboardingDone': onboardingDone,
        'doctorName': doctorName,
        'activeEdition': activeEdition,
        'themePref': themePref.name,
        'accentColorId': accentColorId,
        'dayStartHour': dayStartHour,
        'dailyReminderEnabled': dailyReminderEnabled,
        'noriPropId': noriPropId,
        'noriInteractions': noriInteractions,
        'editions': editions.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory AppState.fromJson(Map<String, dynamic> json) => AppState(
        onboardingDone: json['onboardingDone'] as bool? ?? false,
        doctorName: json['doctorName'] as String? ?? 'Dr',
        activeEdition: json['activeEdition'] as String? ?? 'marrow_8',
        themePref: ThemePref.values.firstWhere(
          (e) => e.name == json['themePref'],
          orElse: () => ThemePref.system,
        ),
        accentColorId: json['accentColorId'] as String? ?? 'indigo',
        dayStartHour: json['dayStartHour'] as int? ?? 5,
        dailyReminderEnabled: json['dailyReminderEnabled'] as bool? ?? true,
        noriPropId: json['noriPropId'] as String? ?? 'stethoscope',
        noriInteractions: json['noriInteractions'] as int? ?? 0,
        editions: (json['editions'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(
                  k, EditionState.fromJson(v as Map<String, dynamic>)),
            ) ??
            {},
      );

  static const empty = AppState();
}

enum ThemePref { light, dark, system }
