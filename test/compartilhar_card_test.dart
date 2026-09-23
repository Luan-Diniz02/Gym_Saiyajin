import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/models/exercicio.dart';
import 'package:gym_saiyajin/models/serie.dart';
import 'package:gym_saiyajin/models/sessao_treino.dart';
import 'package:gym_saiyajin/widgets/compartilhar_card_modal.dart';
import 'package:gym_saiyajin/widgets/scouter_icon.dart';

void main() {
  group('CompartilharCardModal Widget Tests', () {
    final sessaoMock = SessaoTreino(
      nomeTreino: 'Treino A - Peito e Tríceps',
      data: DateTime(2026, 9, 22, 19, 15),
      duracaoSegundos: 4500,
      descansoTotalSegundos: 600,
      exerciciosConcluidosHoje: [
        Exercicio(
          nome: 'Supino Reto',
          grupo: 'PEITO',
          seriesDetalhes: [
            Serie(peso: 100, reps: 10, concluida: true),
            Serie(peso: 100, reps: 10, concluida: true),
          ],
        ),
        Exercicio(
          nome: 'Crucifixo Inclinado',
          grupo: 'PEITO',
          seriesDetalhes: [
            Serie(peso: 25, reps: 10, concluida: true),
            Serie(peso: 25, reps: 10, concluida: true),
          ],
        ),
      ],
    );

    testWidgets('Deve renderizar o modal com os seletores de proporção, estilo e cor', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompartilharCardModal(sessao: sessaoMock),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica título e botão de compartilhar
      expect(find.text('COMPARTILHE SEU PROGRESSO'), findsOneWidget);
      expect(find.text('COMPARTILHAR'), findsOneWidget);

      // Verifica opções de proporção
      expect(find.text('STORIES (9:16)'), findsOneWidget);
      expect(find.text('FEED (1:1)'), findsOneWidget);

      // Verifica opções de estilo de overlay
      expect(find.text('Slim Clássico'), findsOneWidget);
      expect(find.text('Scouter HUD'), findsOneWidget);
      expect(find.text('Rodapé'), findsOneWidget);

      // Verifica elementos do layout Slim Clássico padrão (sem foto)
      expect(find.text('GYM SAIYAJIN'), findsWidgets);
      expect(find.text('TREINO A - PEITO E TRÍCEPS'), findsOneWidget);
    });

    testWidgets('Deve alternar proporção para Feed (1:1) ao clicar no chip', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompartilharCardModal(sessao: sessaoMock),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final feedButton = find.text('FEED (1:1)');
      expect(feedButton, findsOneWidget);
      await tester.tap(feedButton);
      await tester.pumpAndSettle();

      // Verifica que o AspectRatio dentro do preview agora é 1.0 (quadrado)
      final aspectRatioFinder = find.byWidgetPredicate(
        (widget) => widget is AspectRatio && widget.aspectRatio == 1.0,
      );
      expect(aspectRatioFinder, findsWidgets);
    });

    testWidgets('Deve alternar para estilo Scouter HUD e renderizar o ScouterIcon', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompartilharCardModal(sessao: sessaoMock),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clica em 'Scouter HUD'
      final scouterChip = find.text('Scouter HUD');
      expect(scouterChip, findsOneWidget);
      await tester.tap(scouterChip);
      await tester.pumpAndSettle();

      // Deve encontrar o ScouterIcon no modo HUD
      expect(find.byType(ScouterIcon), findsWidgets);
      expect(find.text('+25 Ki'), findsOneWidget);
    });

    testWidgets('Deve alternar estilo para Rodapé Minimalista', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompartilharCardModal(sessao: sessaoMock),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clica em 'Rodapé'
      final rodapeChip = find.text('Rodapé');
      expect(rodapeChip, findsOneWidget);
      await tester.tap(rodapeChip);
      await tester.pumpAndSettle();

      expect(find.text('TREINO A - PEITO E TRÍCEPS'), findsOneWidget);
      expect(find.text('2.500 kg'), findsOneWidget); // (100*10*2) + (25*10*2) = 2000 + 500 = 2500 kg
    });
  });
}
