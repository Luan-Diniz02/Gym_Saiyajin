import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/models/serie.dart';
import 'package:gym_saiyajin/widgets/kinto_un_icon.dart';

void main() {
  group('KintoUnIcon Widget & Painter Tests', () {
    testWidgets('Deve renderizar KintoUnIcon com tamanho padrão (24x24)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: KintoUnIcon(),
            ),
          ),
        ),
      );

      final iconFinder = find.byType(KintoUnIcon);
      expect(iconFinder, findsOneWidget);

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(of: iconFinder, matching: find.byType(SizedBox)).first,
      );
      expect(sizedBox.width, 24.0);
      expect(sizedBox.height, 24.0);

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('Deve renderizar com dimensões customizadas e responder a onTap', (tester) async {
      bool clicou = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: KintoUnIcon(
                size: 40.0,
                showGlow: false,
                showTrail: false,
                onTap: () {
                  clicou = true;
                },
              ),
            ),
          ),
        ),
      );

      final iconFinder = find.byType(KintoUnIcon);
      expect(iconFinder, findsOneWidget);

      await tester.tap(iconFinder);
      await tester.pump();
      expect(clicou, isTrue);
    });

    test('KintoUnPainter shouldRepaint deve detectar mudanças de propriedades', () {
      const p1 = KintoUnPainter();
      const p2 = KintoUnPainter();
      const p3 = KintoUnPainter(showGlow: false);

      expect(p1.shouldRepaint(p2), isFalse);
      expect(p1.shouldRepaint(p3), isTrue);
    });
  });

  group('TipoSerie & Serie Esforço (RIR / RPE)', () {
    test('Deve converter código para TipoSerie e ciclar corretamente', () {
      expect(TipoSerie.fromCodigo(null), TipoSerie.normal);
      expect(TipoSerie.fromCodigo('warmup'), TipoSerie.warmup);
      expect(TipoSerie.fromCodigo('dropset'), TipoSerie.dropset);
      expect(TipoSerie.fromCodigo('falha'), TipoSerie.falha);
      expect(TipoSerie.fromCodigo('invalido'), TipoSerie.normal);

      expect(TipoSerie.normal.proximo, TipoSerie.warmup);
      expect(TipoSerie.warmup.proximo, TipoSerie.dropset);
      expect(TipoSerie.dropset.proximo, TipoSerie.falha);
      expect(TipoSerie.falha.proximo, TipoSerie.normal);
    });

    test('Deve calcular RPE a partir do RIR e formatar labels', () {
      final s0 = Serie(peso: 100, reps: 8, tipo: 'falha', rir: 0);
      expect(s0.isFalha, isTrue);
      expect(s0.rpe, 10.0);
      expect(s0.rirLabel, 'RIR 0');
      expect(s0.rpeLabel, 'RPE 10');

      final s2 = Serie(peso: 90, reps: 10, tipo: 'normal', rir: 2);
      expect(s2.isNormal, isTrue);
      expect(s2.rpe, 8.0);
      expect(s2.rirLabel, 'RIR 2');
      expect(s2.rpeLabel, 'RPE 8');

      final s4 = Serie(peso: 50, reps: 12, tipo: 'warmup', rir: 4);
      expect(s4.isWarmup, isTrue);
      expect(s4.rpe, 6.0);
      expect(s4.rirLabel, 'RIR 4+');
      expect(s4.rpeLabel, 'RPE 6');
    });
  });
}
