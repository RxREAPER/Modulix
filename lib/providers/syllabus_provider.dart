import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/syllabus.dart';
import '../data/subjects_metadata.dart';
import '../services/metrics_service.dart';
import 'app_state_provider.dart';

// Lazy-loaded syllabus data providers
final _marrow8Provider = FutureProvider<List<Subject>>((ref) async {
  // We use compute-isolate here to avoid blocking UI during first parse
  return loadMarrow8Syllabus();
});

final _marrow65Provider = FutureProvider<List<Subject>>((ref) async {
  return loadMarrow65Syllabus();
});

/// Active syllabus based on the current edition
final activeSyllabusProvider = Provider<AsyncValue<List<Subject>>>((ref) {
  final appState = ref.watch(appStateProvider);
  return appState.when(
    loading: () => const AsyncLoading(),
    error: (e, s) => AsyncError(e, s),
    data: (state) {
      if (state.activeEdition == 'marrow_6_5') {
        return ref.watch(_marrow65Provider);
      }
      return ref.watch(_marrow8Provider);
    },
  );
});

/// Single subject by id from the active syllabus
final subjectProvider = Provider.family<AsyncValue<Subject?>, String>((ref, id) {
  final syllabus = ref.watch(activeSyllabusProvider);
  return syllabus.when(
    loading: () => const AsyncLoading(),
    error: (e, s) => AsyncError(e, s),
    data: (subjects) => AsyncData(
      subjects.where((s) => s.id == id).firstOrNull,
    ),
  );
});

/// Computed metrics provider
final syllabusMetricsProvider = Provider((ref) {
  final syllabus = ref.watch(activeSyllabusProvider);
  final appState = ref.watch(appStateProvider);

  return syllabus.when(
    loading: () => null,
    error: (_, __) => null,
    data: (subjects) => appState.when(
      loading: () => null,
      error: (_, __) => null,
      data: (state) {
        // Returns map of subjectId → completion %
        final result = <String, double>{};
        final completedVideos = state.currentEdition.completedVideos;
        for (final s in subjects) {
          final total = s.totalVideos;
          if (total == 0) {
            result[s.id] = 0;
            continue;
          }
          int done = 0;
          for (final c in s.chapters) {
            for (final v in c.videos) {
              if (completedVideos.containsKey(v.id)) {
                done++;
              }
            }
          }
          result[s.id] = done / total;
        }
        return result;
      },
    ),
  );
});

/// Cached daily suggested videos batch for active study plan
final suggestedVideosProvider = Provider<List<Video>>((ref) {
  final syllabus = ref.watch(activeSyllabusProvider);
  final appState = ref.watch(appStateProvider);

  final subjects = syllabus.valueOrNull ?? [];
  final state = appState.valueOrNull;
  if (state == null || subjects.isEmpty) return const [];

  final edition = state.currentEdition;
  final plan = edition.plan;
  if (!plan.isConfigured) return const [];

  try {
    return MetricsService.computeDailyBatch(edition, plan, subjects);
  } catch (_) {
    return const [];
  }
});
