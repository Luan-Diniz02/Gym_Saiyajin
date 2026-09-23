import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/widgets/dragon_radar_icon.dart';

void main() {
  group('DragonRadarIcon Widget Tests', () {
    testWidgets('Deve renderizar DragonRadarIcon com parâmetros padrão (size: 28, dots: 3)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DragonRadarIcon(),
            ),
          ),
        ),
      );

      final iconFinder = find.byType(DragonRadarIcon);
      expect(iconFinder, findsOneWidget);

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(of: iconFinder, matching: find.byType(SizedBox)),
      );
      expect(sizedBox.width, 28.0);
      expect(sizedBox.height, 28.0);

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(of: iconFinder, matching: find.byType(CustomPaint)),
      );
      final painter = customPaint.painter as DragonRadarPainter;
      expect(painter.dots, 3);
      expect(painter.showCenterArrow, isTrue);
      expect(painter.showCrosshair, isTrue);
    });

    testWidgets('Deve renderizar com dimensões customizadas e diferentes quantidades de esferas (0 a 7)', (tester) async {
      for (final dotsCount in [0, 1, 2, 3, 4, 5, 6, 7]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: DragonRadarIcon(size: 36, dots: dotsCount),
              ),
            ),
          ),
        );

        final iconFinder = find.byType(DragonRadarIcon);
        expect(iconFinder, findsOneWidget);

        final sizedBox = tester.widget<SizedBox>(
          find.descendant(of: iconFinder, matching: find.byType(SizedBox)),
        );
        expect(sizedBox.width, 36.0);
        expect(sizedBox.height, 36.0);
      }
    });

    testWidgets('Deve respeitar flags de ocultar mira e seta central', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DragonRadarIcon(
                size: 32,
                dots: 4,
                showCenterArrow: false,
                showCrosshair: false,
              ),
            ),
          ),
        ),
      );

      final iconFinder = find.byType(DragonRadarIcon);
      expect(iconFinder, findsOneWidget);

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(of: iconFinder, matching: find.byType(CustomPaint)),
      );
      final painter = customPaint.painter as DragonRadarPainter;
      expect(painter.showCenterArrow, isFalse);
      expect(painter.showCrosshair, isFalse);
    });

    test('DragonRadarPainter shouldRepaint deve comparar propriedades', () {
      const painter3a = DragonRadarPainter(dots: 3);
      const painter3b = DragonRadarPainter(dots: 3);
      const painter4 = DragonRadarPainter(dots: 4);
      const painterNoCross = DragonRadarPainter(dots: 3, showCrosshair: false);
      const painterNoArrow = DragonRadarPainter(dots: 3, showCenterArrow: false);

      expect(painter3a.shouldRepaint(painter3b), isFalse);
      expect(painter3a.shouldRepaint(painter4), isTrue);
      expect(painter3a.shouldRepaint(painterNoCross), isTrue);
      expect(painter3a.shouldRepaint(painterNoArrow), isTrue);
    });
  });
}
