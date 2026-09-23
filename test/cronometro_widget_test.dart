import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/widgets/cronometro_widget.dart';
import 'package:gym_saiyajin/widgets/escotilha_camara_painter.dart';

void main() {
  group('CronometroWidget - Escotilha da Câmara de Regeneração', () {
    testWidgets('Deve renderizar estado inicial em repouso corretamente', (tester) async {
      bool tappedConfig = false;
      bool tappedStart = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CronometroWidget(
              tempoFormatado: '01:30',
              tempoAtual: 90,
              tempoDescansoPadrao: 90,
              isTimerRodando: false,
              onTapConfig: () => tappedConfig = true,
              onPausar: () {},
              onReiniciar: () {},
              onIniciarOuContinuar: () => tappedStart = true,
            ),
          ),
        ),
      );

      // Verifica textos
      expect(find.text('01:30'), findsOneWidget);
      expect(find.text('CÂMARA DE KI'), findsOneWidget);
      expect(find.text('TOQUE P/ AJUSTAR'), findsOneWidget);

      // Verifica presença do CustomPaint da Escotilha
      expect(find.byType(CustomPaint), findsWidgets);
      final customPaintFinder = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is EscotilhaCamaraPainter,
      );
      expect(customPaintFinder, findsOneWidget);

      // Botão Play presente
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Toque para abrir configuração
      await tester.tap(find.text('01:30'));
      expect(tappedConfig, isTrue);

      // Toque no botão Play
      await tester.tap(find.byIcon(Icons.play_arrow));
      expect(tappedStart, isTrue);
    });

    testWidgets('Deve renderizar estado em regeneração ativa com animação', (tester) async {
      bool tappedPause = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CronometroWidget(
              tempoFormatado: '00:45',
              tempoAtual: 45,
              tempoDescansoPadrao: 90,
              isTimerRodando: true,
              onTapConfig: () {},
              onPausar: () => tappedPause = true,
              onReiniciar: () {},
              onIniciarOuContinuar: () {},
            ),
          ),
        ),
      );

      expect(find.text('00:45'), findsOneWidget);
      expect(find.text('REGENERAÇÃO'), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);

      // Avança a animação de bolhas sem travar
      await tester.pump(const Duration(milliseconds: 500));

      // Toque no botão Pause
      await tester.tap(find.byIcon(Icons.pause));
      expect(tappedPause, isTrue);
    });

    testWidgets('Deve renderizar estado pausado e permitir reiniciar', (tester) async {
      bool tappedRestart = false;
      bool tappedResume = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CronometroWidget(
              tempoFormatado: '00:30',
              tempoAtual: 30,
              tempoDescansoPadrao: 90,
              isTimerRodando: false,
              onTapConfig: () {},
              onPausar: () {},
              onReiniciar: () => tappedRestart = true,
              onIniciarOuContinuar: () => tappedResume = true,
            ),
          ),
        ),
      );

      expect(find.text('00:30'), findsOneWidget);
      expect(find.text('PAUSADO'), findsOneWidget);
      expect(find.byIcon(Icons.restart_alt), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Toque no botão Reiniciar
      await tester.tap(find.byIcon(Icons.restart_alt));
      expect(tappedRestart, isTrue);

      // Toque no botão Play (Retomar)
      await tester.tap(find.byIcon(Icons.play_arrow));
      expect(tappedResume, isTrue);
    });
  });
}
