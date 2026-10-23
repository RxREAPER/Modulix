import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/widgets/analytics/pacing_velocity_chart.dart';
import 'package:modulix/widgets/heatmap_calendar.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  group('NEET-PG Consistency Matrix Widget Tests', () {
    final sampleVideoHistory = {
      '2026-10-22': 6,
      '2026-10-21': 4,
      '2026-10-20': 8,
      '2026-10-19': 2,
    };

    final sampleFocusSecs = {
      '2026-10-22': 12600, // 3.5h
      '2026-10-21': 7200,  // 2.0h
      '2026-10-20': 18000, // 5.0h
    };

    final sampleTaskHistory = {
      '2026-10-22': 5,
      '2026-10-21': 3,
    };

    testWidgets('renders matrix title, metric segmented chips, and legend', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NeetConsistencyMatrix(
                dailyVideos: sampleVideoHistory,
                dailyFocusSecs: sampleFocusSecs,
                dailyTasks: sampleTaskHistory,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NEET-PG Consistency Matrix'), findsOneWidget);
      expect(find.text('Videos'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Less'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('switches metric mode when tapping Time and Tasks chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NeetConsistencyMatrix(
                dailyVideos: sampleVideoHistory,
                dailyFocusSecs: sampleFocusSecs,
                dailyTasks: sampleTaskHistory,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Time'
      await tester.tap(find.text('Time'));
      await tester.pumpAndSettle();
      expect(find.text('Time'), findsOneWidget);

      // Tap 'Tasks'
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();
      expect(find.text('Tasks'), findsOneWidget);
    });

    testWidgets('renders and switches Q-Banks and Notes metric chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NeetConsistencyMatrix(
                dailyVideos: sampleVideoHistory,
                dailyQBanks: const {'2026-10-22': 30},
                dailyNotes: const {'2026-10-22': 2},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Videos'), findsOneWidget);
      expect(find.text('Q-Banks'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);

      await tester.tap(find.text('Q-Banks'));
      await tester.pumpAndSettle();
      expect(find.text('Q-Banks'), findsOneWidget);

      await tester.tap(find.text('Notes'));
      await tester.pumpAndSettle();
      expect(find.text('Notes'), findsOneWidget);
    });

    testWidgets('HeatmapCalendar backward-compatibility adapter renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HeatmapCalendar(
                dailyHistory: sampleVideoHistory,
                accentColor: const Color(0xFF6366F1),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NEET-PG Consistency Matrix'), findsOneWidget);
      expect(find.byType(NeetConsistencyMatrix), findsOneWidget);
    });
  });

  group('Pacing Velocity Chart Widget Tests', () {
    testWidgets('renders trajectory header, velocity badge, and line chart', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PacingVelocityChart(
                totalModules: 120,
                completedModules: 48,
                dailyHistory: {
                  '2026-10-22': 5,
                  '2026-10-21': 4,
                  '2026-10-20': 6,
                },
                dailyQuota: 4.0,
                targetDateStr: '2026-11-30',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pacing Velocity & Trajectory'), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('Actual'), findsOneWidget);
      expect(find.text('Target'), findsOneWidget);
      expect(find.text('Forecast'), findsOneWidget);
    });

    testWidgets('handles zero completed modules and zero total gracefully', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PacingVelocityChart(
                totalModules: 0,
                completedModules: 0,
                dailyHistory: {},
                dailyQuota: 0.0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pacing Velocity & Trajectory'), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
    });
  });
}
