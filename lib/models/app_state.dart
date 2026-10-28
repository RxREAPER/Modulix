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
        targetSubject: json['targetSubject']?.toString() ?? '',
        targetDate: json['targetDate']?.toString() ?? '',
        videosPerDay: (json['videosPerDay'] as num?)?.toInt(),
        targetUnits: (json['targetUnits'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        focusChapterName: json['focusChapterName']?.toString(),
        dailyHours: (json['dailyHours'] as num?)?.toDouble() ?? 4.0,
        revisionCycles: (json['revisionCycles'] as num?)?.toInt() ?? 1,
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
        plan: json['plan'] != null && json['plan'] is Map
            ? StudyPlan.fromJson(Map<String, dynamic>.from(json['plan'] as Map))
            : StudyPlan.empty,
        completedVideos: json['completedVideos'] is Map
            ? Map<String, dynamic>.from(json['completedVideos'] as Map)
            : {},
        completedQBanks: json['completedQBanks'] is Map
            ? Map<String, dynamic>.from(json['completedQBanks'] as Map)
            : {},
        completedNotes: json['completedNotes'] is Map
            ? Map<String, dynamic>.from(json['completedNotes'] as Map)
            : {},
        dailyHistory: (json['dailyHistory'] as Map?)
                ?.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0)) ??
            {},
        bulkCompletedChapters:
            (json['bulkCompletedChapters'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
        queueBatchVideoIds:
            (json['queueBatchVideoIds'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
        staleBatchVideoIds:
            (json['staleBatchVideoIds'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
        queueCompletedInBatch: (json['queueCompletedInBatch'] as num?)?.toInt() ?? 0,
      );

  static const empty = EditionState();
}

/// Root app state
class AppState {
  final bool onboardingDone;
  final String doctorName;
  final String activeEdition;   // 'marrow_8' | 'marrow_6_5'
  final ThemePref themePref;
  final String palettePresetId; // 'paper' | 'obsidian' | 'slate' | 'sepia'
  final String accentColorId;   // 'cobalt' | 'emerald' | 'amethyst' | 'amber' | 'coral'
  final String avatarColorId;   // profile avatar palette id (see profile_customization.dart)
  final String avatarIconId;    // profile avatar icon id ('letter' = show initial)
  final int dayStartHour;       // e.g. 5 for 5:00 AM
  final bool dailyReminderEnabled;
  final String studyReminderTime;     // e.g. '09:00'
  final bool streakReminderEnabled;
  final String streakReminderTime;    // e.g. '20:00'
  final bool moduleTasksReminderEnabled;
  final String moduleTasksReminderTime; // e.g. '08:00'
  final bool focusTimerAlertsEnabled;
  final String? leaderboardDisplayName;
  final bool isLeaderboardAnonymous;
  final bool leaderboardVisible;
  final Map<String, EditionState> editions; // keyed by edition id

  const AppState({
    this.onboardingDone = false,
    this.doctorName = 'Dr',
    this.activeEdition = 'marrow_8',
    this.themePref = ThemePref.system,
    this.palettePresetId = 'paper',
    this.accentColorId = 'cobalt',
    this.avatarColorId = 'indigo',
    this.avatarIconId = 'letter',
    this.dayStartHour = 5,
    this.dailyReminderEnabled = true,
    this.studyReminderTime = '09:00',
    this.streakReminderEnabled = true,
    this.streakReminderTime = '20:00',
    this.moduleTasksReminderEnabled = true,
    this.moduleTasksReminderTime = '08:00',
    this.focusTimerAlertsEnabled = true,
    this.leaderboardDisplayName,
    this.isLeaderboardAnonymous = false,
    this.leaderboardVisible = true,
    this.editions = const {},
  });

  String get publicDisplayName {
    final clean = doctorName.trim();
    if (clean.isEmpty || clean.toLowerCase() == 'doctor') {
      final code = (clean.isEmpty ? 'flowmd' : clean).hashCode.abs() % 9000 + 1000;
      return 'User $code';
    }
    return clean.startsWith('Dr') ? clean : 'Dr. $clean';
  }

  EditionState get currentEdition =>
      editions[activeEdition] ?? const EditionState();

  AppState copyWith({
    bool? onboardingDone,
    String? doctorName,
    String? activeEdition,
    ThemePref? themePref,
    String? palettePresetId,
    String? accentColorId,
    String? avatarColorId,
    String? avatarIconId,
    int? dayStartHour,
    bool? dailyReminderEnabled,
    String? studyReminderTime,
    bool? streakReminderEnabled,
    String? streakReminderTime,
    bool? moduleTasksReminderEnabled,
    String? moduleTasksReminderTime,
    bool? focusTimerAlertsEnabled,
    String? leaderboardDisplayName,
    bool? isLeaderboardAnonymous,
    bool? leaderboardVisible,
    Map<String, EditionState>? editions,
  }) {
    return AppState(
      onboardingDone: onboardingDone ?? this.onboardingDone,
      doctorName: doctorName ?? this.doctorName,
      activeEdition: activeEdition ?? this.activeEdition,
      themePref: themePref ?? this.themePref,
      palettePresetId: palettePresetId ?? this.palettePresetId,
      accentColorId: accentColorId ?? this.accentColorId,
      avatarColorId: avatarColorId ?? this.avatarColorId,
      avatarIconId: avatarIconId ?? this.avatarIconId,
      dayStartHour: dayStartHour ?? this.dayStartHour,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      studyReminderTime: studyReminderTime ?? this.studyReminderTime,
      streakReminderEnabled: streakReminderEnabled ?? this.streakReminderEnabled,
      streakReminderTime: streakReminderTime ?? this.streakReminderTime,
      moduleTasksReminderEnabled:
          moduleTasksReminderEnabled ?? this.moduleTasksReminderEnabled,
      moduleTasksReminderTime:
          moduleTasksReminderTime ?? this.moduleTasksReminderTime,
      focusTimerAlertsEnabled:
          focusTimerAlertsEnabled ?? this.focusTimerAlertsEnabled,
      leaderboardDisplayName:
          leaderboardDisplayName ?? this.leaderboardDisplayName,
      isLeaderboardAnonymous:
          isLeaderboardAnonymous ?? this.isLeaderboardAnonymous,
      leaderboardVisible: leaderboardVisible ?? this.leaderboardVisible,
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
        'palettePresetId': palettePresetId,
        'accentColorId': accentColorId,
        'avatarColorId': avatarColorId,
        'avatarIconId': avatarIconId,
        'dayStartHour': dayStartHour,
        'dailyReminderEnabled': dailyReminderEnabled,
        'studyReminderTime': studyReminderTime,
        'streakReminderEnabled': streakReminderEnabled,
        'streakReminderTime': streakReminderTime,
        'moduleTasksReminderEnabled': moduleTasksReminderEnabled,
        'moduleTasksReminderTime': moduleTasksReminderTime,
        'focusTimerAlertsEnabled': focusTimerAlertsEnabled,
        'leaderboardDisplayName': leaderboardDisplayName,
        'isLeaderboardAnonymous': isLeaderboardAnonymous,
        'leaderboardVisible': leaderboardVisible,
        'editions': editions.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory AppState.fromJson(Map<String, dynamic> json) => AppState(
        onboardingDone: json['onboardingDone'] as bool? ?? false,
        doctorName: json['doctorName']?.toString() ?? 'Dr',
        activeEdition: json['activeEdition']?.toString() ?? 'marrow_8',
        themePref: ThemePref.values.firstWhere(
          (e) => e.name == json['themePref'],
          orElse: () => ThemePref.system,
        ),
        palettePresetId: json['palettePresetId']?.toString() ?? 'paper',
        accentColorId: json['accentColorId']?.toString() ?? 'cobalt',
        avatarColorId: json['avatarColorId']?.toString() ?? 'indigo',
        avatarIconId: json['avatarIconId']?.toString() ?? 'letter',
        dayStartHour: (json['dayStartHour'] as num?)?.toInt() ?? 5,
        dailyReminderEnabled: json['dailyReminderEnabled'] as bool? ?? true,
        studyReminderTime: json['studyReminderTime']?.toString() ?? '09:00',
        streakReminderEnabled: json['streakReminderEnabled'] as bool? ?? true,
        streakReminderTime: json['streakReminderTime']?.toString() ?? '20:00',
        moduleTasksReminderEnabled:
            json['moduleTasksReminderEnabled'] as bool? ?? true,
        moduleTasksReminderTime:
            json['moduleTasksReminderTime']?.toString() ?? '08:00',
        focusTimerAlertsEnabled:
            json['focusTimerAlertsEnabled'] as bool? ?? true,
        leaderboardDisplayName: json['leaderboardDisplayName']?.toString(),
        isLeaderboardAnonymous: json['isLeaderboardAnonymous'] as bool? ?? false,
        leaderboardVisible: json['leaderboardVisible'] as bool? ?? true,
        editions: (json['editions'] as Map?)?.entries.fold<Map<String, EditionState>>(
              {},
              (acc, entry) {
                if (entry.value is Map) {
                  acc[entry.key.toString()] = EditionState.fromJson(
                      Map<String, dynamic>.from(entry.value as Map));
                }
                return acc;
              },
            ) ??
            {},
      );

  static const empty = AppState();
}

enum ThemePref { light, dark, system }
