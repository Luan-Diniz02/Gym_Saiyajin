import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/widgets/capsule_icon.dart';

void main() {
  group('CapsuleIcon Widget Tests', () {
    testWidgets('Deve renderizar CapsuleIcon com parâmetros padrão (size: 32, azul Capsule Corp)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CapsuleIcon(),
            ),
          ),
        ),
      );

      final iconFinder = find.byType(CapsuleIcon);
      expect(iconFinder, findsOneWidget);

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(of: iconFinder, matching: find.byType(SizedBox)),
      );
      expect(sizedBox.width, 32.0);
      expect(sizedBox.height, 32.0);

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(of: iconFinder, matching: find.byType(CustomPaint)),
      );
      final painter = customPaint.painter as CapsulePainter;
      expect(painter.color, const Color(0xFF00A3FF));
      expect(painter.angleDegrees, 35.0);
    });

    testWidgets('Deve renderizar com dimensões e cores personalizadas', (tester) async {
      for (final color in [Colors.orange, Colors.green, Colors.purple, Colors.red]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: CapsuleIcon(size: 48, color: color, angleDegrees: 20),
              ),
            ),
          ),
        );

        final iconFinder = find.byType(CapsuleIcon);
        expect(iconFinder, findsOneWidget);

        final customPaint = tester.widget<CustomPaint>(
          find.descendant(of: iconFinder, matching: find.byType(CustomPaint)),
        );
        final painter = customPaint.painter as CapsulePainter;
        expect(painter.color, color);
        expect(painter.angleDegrees, 20.0);
      }
    });

    test('CapsulePainter shouldRepaint deve comparar color e angleDegrees', () {
      const painterA = CapsulePainter(color: Color(0xFF00A3FF), angleDegrees: 35.0);
      const painterSame = CapsulePainter(color: Color(0xFF00A3FF), angleDegrees: 35.0);
      const painterDiffColor = CapsulePainter(color: Colors.orange, angleDegrees: 35.0);
      const painterDiffAngle = CapsulePainter(color: Color(0xFF00A3FF), angleDegrees: 0.0);

      expect(painterA.shouldRepaint(painterSame), isFalse);
      expect(painterA.shouldRepaint(painterDiffColor), isTrue);
      expect(painterA.shouldRepaint(painterDiffAngle), isTrue);
    });
  });
}
