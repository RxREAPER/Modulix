import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/widgets/errors/modulix_error_scaffold.dart';
import 'package:modulix/widgets/errors/app_error_state_view.dart';
import 'package:modulix/widgets/errors/route_error_view.dart';
import 'package:modulix/widgets/errors/diagnostic_telemetry_drawer.dart';

void main() {
  group('Doctor Error Widgets', () {
    testWidgets('ModulixErrorScaffold renders clinical headline and cache guarantee', (tester) async {
      await tester.pumpWidget(
        const ModulixErrorScaffold(
          error: 'RenderFlex overflowed by 30 pixels',
        ),
      );

      expect(find.text('Study Session Protected'), findsOneWidget);
      expect(find.text('Local Study Cache Intact'), findsOneWidget);
      expect(find.text('Reopen Home Desk'), findsOneWidget);
      expect(find.byType(DiagnosticTelemetryDrawer), findsOneWidget);
    });

    testWidgets('AppErrorStateView renders translated error and handles retry tap', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorStateView(
              error: 'Failed host lookup: api.supabase.co',
              onRetry: () {
                retried = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Offline Mode Active'), findsOneWidget);
      expect(find.text('Got It'), findsOneWidget);

      await tester.tap(find.text('Got It'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('DiagnosticTelemetryDrawer expands on tap and contains copy button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DiagnosticTelemetryDrawer(
              technicalDetails: 'Exception: Something crashed\nat line 42',
            ),
          ),
        ),
      );

      expect(find.text('Diagnostic Telemetry (for Support)'), findsOneWidget);
      expect(
        tester.widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade)).crossFadeState,
        CrossFadeState.showFirst,
      );

      // Tap to expand drawer
      await tester.tap(find.text('Diagnostic Telemetry (for Support)'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade)).crossFadeState,
        CrossFadeState.showSecond,
      );
      expect(find.text('Copy Diagnostics'), findsOneWidget);
    });

    testWidgets('RouteErrorView renders destination not in syllabus', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RouteErrorView(
            uri: Uri.parse('/curriculum/neuro_surgery_super_specialty'),
          ),
        ),
      );

      expect(find.text('Destination Not in Syllabus'), findsOneWidget);
      expect(find.text('Return to Home Desk'), findsOneWidget);
    });
  });
}
