import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/widgets/ki_aura_icon.dart';

void main() {
  group('KiAuraIcon Widget Tests', () {
    testWidgets('Deve renderizar KiAuraIcon com tamanho padrão (24x24)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: KiAuraIcon(),
            ),
          ),
        ),
      );

      final iconFinder = find.byType(KiAuraIcon);
      expect(iconFinder, findsOneWidget);

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(of: iconFinder, matching: find.byType(SizedBox)).first,
      );
      expect(sizedBox.width, 24.0);
      expect(sizedBox.height, 24.0);

      final customPaintFinder = find.byType(CustomPaint);
      expect(customPaintFinder, findsWidgets);
    });

    testWidgets('Deve renderizar com dimensões customizadas e responder a onTap', (tester) async {
      bool clicou = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: KiAuraIcon(
                size: 48.0,
                primaryColor: const Color(0xFFFF5252),
                secondaryColor: const Color(0xFFD50000),
                onTap: () {
                  clicou = true;
                },
              ),
            ),
          ),
        ),
      );

      final iconFinder = find.byType(KiAuraIcon);
      expect(iconFinder, findsOneWidget);

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(of: iconFinder, matching: find.byType(SizedBox)).first,
      );
      expect(sizedBox.width, 48.0);
      expect(sizedBox.height, 48.0);

      // Clicar no ícone
      await tester.tap(iconFinder);
      await tester.pump();
      expect(clicou, isTrue);
    });

    testWidgets('Deve renderizar com flags showGlow, showSparks e showCore desativadas', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: KiAuraIcon(
                size: 32.0,
                showGlow: false,
                showSparks: false,
                showCore: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(KiAuraIcon), findsOneWidget);
    });

    test('KiAuraPainter shouldRepaint deve detectar mudanças de propriedades', () {
      const p1 = KiAuraPainter(
        primaryColor: Color(0xFFFFD700),
        secondaryColor: Color(0xFFFF8C00),
        coreColor: Color(0xFFFFFDE7),
      );

      const p2 = KiAuraPainter(
        primaryColor: Color(0xFFFFD700),
        secondaryColor: Color(0xFFFF8C00),
        coreColor: Color(0xFFFFFDE7),
      );

      const p3 = KiAuraPainter(
        primaryColor: Color(0xFFFF5252),
        secondaryColor: Color(0xFFFF8C00),
        coreColor: Color(0xFFFFFDE7),
      );

      expect(p1.shouldRepaint(p2), isFalse);
      expect(p1.shouldRepaint(p3), isTrue);
    });
  });
}
