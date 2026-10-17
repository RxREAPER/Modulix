import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/models/daily_desk_task.dart';
import 'package:modulix/widgets/task_setup_sheet.dart';

void main() {
  testWidgets('TaskSetupSheet starts clean with empty tasks without auto-injecting', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskSetupSheet(
            currentTasks: const [],
            onConfirmTasks: (_) {},
          ),
        ),
      ),
    );

    // Verify clean desk empty state is shown
    expect(find.text('Your desk is clear'), findsOneWidget);
    expect(find.text("Plan Today's Desk"), findsOneWidget);
    expect(find.text('0 Targets'), findsOneWidget);
  });

  testWidgets('TaskSetupSheet can switch modality and add tasks', (tester) async {
    List<DailyDeskTask>? confirmed;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskSetupSheet(
            currentTasks: const [],
            onConfirmTasks: (tasks) => confirmed = tasks,
          ),
        ),
      ),
    );

    // Initial category is Video
    expect(find.text('Video'), findsOneWidget);

    // Tap category stamp to toggle palette
    await tester.tap(find.text('Video'));
    await tester.pumpAndSettle();

    // Select Q-BANK
    await tester.tap(find.text('Q-BANK'));
    await tester.pumpAndSettle();

    // Verify Q-Bank is now selected in the stamp
    expect(find.text('Q-Bank'), findsOneWidget);

    // Enter a task title
    await tester.enterText(find.byType(TextField), '50 MCQs Endocrinology');
    await tester.pump();

    // Tap the '+' add button
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    // Verify task is added to list
    expect(find.text('50 MCQs Endocrinology'), findsOneWidget);
    expect(find.text('1 Target'), findsOneWidget);

    // Confirm tasks
    await tester.tap(find.text('Place 1 Target on Desk'));
    await tester.pump();

    expect(confirmed, isNotNull);
    expect(confirmed!.length, 1);
    expect(confirmed!.first.title, '50 MCQs Endocrinology');
    expect(confirmed!.first.category, TaskCategory.qbank);
  });
}
