import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/theme/app_theme.dart';
import 'package:modulix/theme/modulix_theme.dart';
import 'package:modulix/widgets/brand/modulix_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ModulixLogo Brand Insignia Tests', () {
    testWidgets('ModulixLogo renders monogram style in light theme', (tester) async {
      AppTheme.current = ModulixThemeExtension.from(preset: PalettePreset.paper);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ModulixLogo(
                size: 32,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModulixLogo), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('ModulixLogo renders monogram style in dark theme', (tester) async {
      AppTheme.current = ModulixThemeExtension.from(preset: PalettePreset.slate);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: Center(
              child: ModulixLogo(
                size: 48,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModulixLogo), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('ModulixLogo renders coaster squircle style without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ModulixLogo(
                size: 64,
                style: ModulixLogoStyle.coaster,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModulixLogo), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('ModulixLogo accepts custom tint and tap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ModulixLogo(
                size: 30,
                color: const Color(0xFF0288A6), // The Catalyst Ocean Teal
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModulixLogo), findsOneWidget);
      await tester.tap(find.byType(ModulixLogo));
      expect(tapped, isTrue);
    });
  });
}
