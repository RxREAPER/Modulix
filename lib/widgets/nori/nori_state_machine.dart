import 'dart:collection';
import 'package:flutter/material.dart';

/// Available primary actions and mood cycles for Nori.
enum NoriAction {
  walking,
  running,
  celebrating,
  celebratingAlt,
  studying,
  welcoming,
  bored,
  sleepy,
  sad,
  tired,
  yawningLoaf,
  rollingSleep,
  love,
  excited,
  playful,
  eating,
}

extension NoriActionExt on NoriAction {
  String get folderName {
    switch (this) {
      case NoriAction.walking:
        return 'walking';
      case NoriAction.running:
        return 'running';
      case NoriAction.celebrating:
        return 'celebrating';
      case NoriAction.celebratingAlt:
        return 'celebrating_alt';
      case NoriAction.studying:
        return 'studying';
      case NoriAction.welcoming:
        return 'welcoming';
      case NoriAction.bored:
        return 'bored';
      case NoriAction.sleepy:
        return 'sleepy';
      case NoriAction.sad:
        return 'sad';
      case NoriAction.tired:
        return 'tired';
      case NoriAction.yawningLoaf:
        return 'yawning_loaf';
      case NoriAction.rollingSleep:
        return 'rolling_sleep';
      case NoriAction.love:
        return 'love';
      case NoriAction.excited:
        return 'excited';
      case NoriAction.playful:
        return 'playful';
      case NoriAction.eating:
        return 'eating';
    }
  }

  int get frameCount {
    switch (this) {
      case NoriAction.walking:
      case NoriAction.running:
      case NoriAction.celebrating:
      case NoriAction.celebratingAlt:
      case NoriAction.studying:
      case NoriAction.welcoming:
      case NoriAction.bored:
      case NoriAction.sleepy:
      case NoriAction.sad:
      case NoriAction.tired:
      case NoriAction.yawningLoaf:
      case NoriAction.rollingSleep:
        return 9;
      case NoriAction.playful:
      case NoriAction.eating:
        return 3;
      case NoriAction.love:
      case NoriAction.excited:
        return 2;
    }
  }

  /// Frames per second for this action
  double get fps {
    switch (this) {
      case NoriAction.running:
        return 16.0;
      case NoriAction.celebrating:
      case NoriAction.celebratingAlt:
        return 14.0;
      case NoriAction.walking:
      case NoriAction.studying:
      case NoriAction.welcoming:
      case NoriAction.playful:
      case NoriAction.eating:
        return 12.0;
      case NoriAction.love:
      case NoriAction.excited:
        return 6.0;
      case NoriAction.bored:
      case NoriAction.sleepy:
      case NoriAction.sad:
      case NoriAction.tired:
      case NoriAction.yawningLoaf:
      case NoriAction.rollingSleep:
        return 8.0;
    }
  }
}

/// Dynamic, interlinked transition state machine for Nori
class NoriStateMachine {
  NoriStateMachine._();
  static final NoriStateMachine instance = NoriStateMachine._();

  static const String assetPrefix = 'assets/sprites/nori';

  /// All 24 authentic 6-frame transitions from the official sprite sheets
  static const Map<String, String> directTransitions = {
    'walk_to_celebrate': 'transitions/walk_to_celebrate',
    'celebrate_to_walk': 'transitions/celebrate_to_walk',
    'walk_to_run': 'transitions/walk_to_run',
    'run_to_walk': 'transitions/run_to_walk',
    'celebrate_to_run': 'transitions/celebrate_to_run',
    'run_to_celebrate': 'transitions/run_to_celebrate',
    'study_to_welcome': 'transitions/study_to_welcome',
    'welcome_to_study': 'transitions/welcome_to_study',
    'welcome_to_bored': 'transitions/welcome_to_bored',
    'bored_to_welcome': 'transitions/bored_to_welcome',
    'study_to_bored': 'transitions/study_to_bored',
    'bored_to_study': 'transitions/bored_to_study',
    'play_to_sleep': 'transitions/play_to_sleep',
    'sleep_to_play': 'transitions/sleep_to_play',
    'sleep_to_eat': 'transitions/sleep_to_eat',
    'eat_to_sleep': 'transitions/eat_to_sleep',
    'play_to_eat': 'transitions/play_to_eat',
    'eat_to_play': 'transitions/eat_to_play',
    'love_to_excited': 'transitions/love_to_excited',
    'excited_to_love': 'transitions/excited_to_love',
    'excited_to_play': 'transitions/excited_to_play',
    'play_to_excited': 'transitions/play_to_excited',
    'love_to_play': 'transitions/love_to_play',
    'play_to_love': 'transitions/play_to_love',
  };

  /// Natural bridge connections connecting the 4 clusters:
  /// Cluster A: {walk, run, celebrate}
  /// Cluster B: {study, welcome, bored}
  /// Cluster C: {play, sleep, eat}
  /// Cluster D: {love, excited, play}
  static final Map<NoriAction, List<NoriAction>> _bridgeAdjacency = {
    // Cluster A <-> Cluster B
    NoriAction.walking: [NoriAction.running, NoriAction.celebrating, NoriAction.welcoming],
    NoriAction.running: [NoriAction.walking, NoriAction.celebrating],
    NoriAction.celebrating: [NoriAction.walking, NoriAction.running, NoriAction.excited],
    NoriAction.celebratingAlt: [NoriAction.celebrating],

    // Cluster B
    NoriAction.welcoming: [NoriAction.studying, NoriAction.bored, NoriAction.walking],
    NoriAction.studying: [NoriAction.welcoming, NoriAction.bored],
    NoriAction.bored: [NoriAction.studying, NoriAction.welcoming, NoriAction.yawningLoaf, NoriAction.playful],

    // Rest & idle poses
    NoriAction.yawningLoaf: [NoriAction.bored, NoriAction.sleepy, NoriAction.rollingSleep],
    NoriAction.rollingSleep: [NoriAction.yawningLoaf, NoriAction.sleepy],
    NoriAction.sleepy: [NoriAction.playful, NoriAction.eating, NoriAction.yawningLoaf],
    NoriAction.sad: [NoriAction.love, NoriAction.sleepy],
    NoriAction.tired: [NoriAction.yawningLoaf, NoriAction.sleepy, NoriAction.studying],

    // Cluster C & D
    NoriAction.playful: [
      NoriAction.sleepy,
      NoriAction.eating,
      NoriAction.excited,
      NoriAction.love,
      NoriAction.bored,
    ],
    NoriAction.eating: [NoriAction.playful, NoriAction.sleepy],
    NoriAction.love: [NoriAction.excited, NoriAction.playful, NoriAction.sad],
    NoriAction.excited: [NoriAction.love, NoriAction.playful, NoriAction.celebrating],
  };

  /// Check if a direct 6-frame transition exists between two actions
  static String? getDirectTransitionKey(NoriAction from, NoriAction to) {
    final fromName = _canonicalName(from);
    final toName = _canonicalName(to);
    final key = '${fromName}_to_$toName';
    if (directTransitions.containsKey(key)) {
      return key;
    }
    return null;
  }

  static String _canonicalName(NoriAction action) {
    switch (action) {
      case NoriAction.walking:
        return 'walk';
      case NoriAction.running:
        return 'run';
      case NoriAction.celebrating:
      case NoriAction.celebratingAlt:
        return 'celebrate';
      case NoriAction.studying:
        return 'study';
      case NoriAction.welcoming:
        return 'welcome';
      case NoriAction.bored:
        return 'bored';
      case NoriAction.sleepy:
      case NoriAction.rollingSleep:
      case NoriAction.yawningLoaf:
        return 'sleep';
      case NoriAction.eating:
        return 'eat';
      case NoriAction.playful:
        return 'play';
      case NoriAction.love:
      case NoriAction.sad:
        return 'love';
      case NoriAction.excited:
        return 'excited';
      case NoriAction.tired:
        return 'sleep';
    }
  }

  /// Finds the shortest transition sequence of actions from `start` to `goal`.
  static List<NoriAction> findPath(NoriAction start, NoriAction goal) {
    if (start == goal) return [];

    final queue = Queue<List<NoriAction>>();
    final visited = <NoriAction>{start};
    queue.add([start]);

    while (queue.isNotEmpty) {
      final path = queue.removeFirst();
      final current = path.last;

      if (current == goal) {
        return path;
      }

      final neighbors = _bridgeAdjacency[current] ?? [];
      for (final next in neighbors) {
        if (!visited.contains(next)) {
          visited.add(next);
          queue.add([...path, next]);
        }
      }
    }

    return [start, goal];
  }

  /// Returns the complete list of frame asset paths to play when transitioning
  /// from [from] to [to]. If direct transition exists, returns its 6 frames.
  /// If path requires multi-hop, returns the chained transition frames.
  static List<String> getTransitionFrames(NoriAction from, NoriAction to) {
    if (from == to) return [];

    // Direct transition lookup
    final directKey = getDirectTransitionKey(from, to);
    if (directKey != null) {
      final folder = directTransitions[directKey]!;
      return List.generate(6, (i) => '$assetPrefix/$folder/$i.png');
    }

    // Graph pathfinding
    final path = findPath(from, to);
    final frames = <String>[];

    for (int i = 0; i < path.length - 1; i++) {
      final hopFrom = path[i];
      final hopTo = path[i + 1];
      final hopKey = getDirectTransitionKey(hopFrom, hopTo);

      if (hopKey != null) {
        final folder = directTransitions[hopKey]!;
        for (int f = 0; f < 6; f++) {
          frames.add('$assetPrefix/$folder/$f.png');
        }
      } else {
        // Fallback smooth blend frame from hopTo
        frames.add('$assetPrefix/${hopTo.folderName}/0.png');
      }
    }

    return frames;
  }

  /// Returns the asset path for an action loop frame.
  static String getActionFrame(NoriAction action, int frameIndex) {
    final idx = frameIndex % action.frameCount;
    return '$assetPrefix/${action.folderName}/$idx.png';
  }

  /// Pre-cache all 262 frames in the background so transitions are 100% instant
  static Future<void> precacheAll(BuildContext context) async {
    final futures = <Future>[];

    // Pre-cache action loops
    for (final action in NoriAction.values) {
      for (int i = 0; i < action.frameCount; i++) {
        final path = getActionFrame(action, i);
        futures.add(precacheImage(AssetImage(path), context));
      }
    }

    // Pre-cache transition frames
    for (final folder in directTransitions.values) {
      for (int i = 0; i < 6; i++) {
        final path = '$assetPrefix/$folder/$i.png';
        futures.add(precacheImage(AssetImage(path), context));
      }
    }

    await Future.wait(futures);
  }
}
