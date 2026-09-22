import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/widgets/dragon_ball_icon.dart';

void main() {
  group('DragonBallIcon Widget Tests', () {
    testWidgets('Deve renderizar DragonBallIcon com parâmetros padrão (size: 24, stars: 4)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DragonBallIcon(),
            ),
          ),
        ),
      );

      final iconFinder = find.byType(DragonBallIcon);
      expect(iconFinder, findsOneWidget);

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(of: iconFinder, matching: find.byType(SizedBox)),
      );
      expect(sizedBox.width, 24.0);
      expect(sizedBox.height, 24.0);

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(of: iconFinder, matching: find.byType(CustomPaint)),
      );
      final painter = customPaint.painter as DragonBallPainter;
      expect(painter.stars, 4);
    });

    testWidgets('Deve renderizar com dimensões personalizadas e diferentes quantidades de estrelas', (tester) async {
      for (final count in [1, 2, 3, 4, 5, 6, 7]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: DragonBallIcon(size: 48, stars: count),
              ),
            ),
          ),
        );

        final iconFinder = find.byType(DragonBallIcon);
        expect(iconFinder, findsOneWidget);

        final sizedBox = tester.widget<SizedBox>(
          find.descendant(of: iconFinder, matching: find.byType(SizedBox)),
        );
        expect(sizedBox.width, 48.0);
        expect(sizedBox.height, 48.0);
      }
    });

    test('DragonBallPainter shouldRepaint deve comparar a propriedade stars', () {
      const painter4a = DragonBallPainter(stars: 4);
      const painter4b = DragonBallPainter(stars: 4);
      const painter1 = DragonBallPainter(stars: 1);

      expect(painter4a.shouldRepaint(painter4b), isFalse);
      expect(painter4a.shouldRepaint(painter1), isTrue);
    });
  });
}
