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

      // Verifica seletor de presets e setas de navegação
      expect(find.text('SLIM CLÁSSICO'), findsOneWidget);
      expect(find.byTooltip('Próximo preset'), findsOneWidget);
      expect(find.byTooltip('Preset anterior'), findsOneWidget);

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

    testWidgets('Deve alternar para estilo Scouter HUD via seta e renderizar o ScouterIcon', (tester) async {
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

      // Inicialmente em Slim Clássico
      expect(find.text('SLIM CLÁSSICO'), findsOneWidget);

      // Clica na seta de próximo preset
      final proximoBtn = find.byTooltip('Próximo preset');
      expect(proximoBtn, findsOneWidget);
      await tester.tap(proximoBtn);
      await tester.pumpAndSettle();

      // Agora deve estar em Scouter HUD
      expect(find.text('SCOUTER HUD'), findsOneWidget);
      expect(find.byType(ScouterIcon), findsWidgets);
      expect(find.text('+25 Ki'), findsOneWidget);
    });

    testWidgets('Deve alternar estilo para Rodapé Minimalista via setas', (tester) async {
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

      final proximoBtn = find.byTooltip('Próximo preset');
      // Avança 2x para chegar a Rodapé Minimalista (Slim -> Scouter -> Rodapé)
      await tester.tap(proximoBtn);
      await tester.pumpAndSettle();
      await tester.tap(proximoBtn);
      await tester.pumpAndSettle();

      expect(find.text('RODAPÉ MINIMALISTA'), findsOneWidget);
      expect(find.text('TREINO A - PEITO E TRÍCEPS'), findsOneWidget);
      expect(find.text('2.500 kg'), findsOneWidget); // (100*10*2) + (25*10*2) = 2000 + 500 = 2500 kg
    });

    testWidgets('Deve alternar preset ao arrastar (swipe) horizontalmente no preview do card', (tester) async {
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

      expect(find.text('SLIM CLÁSSICO'), findsOneWidget);

      // Simula gesto de arrasto horizontal da direita para a esquerda (swipe left) no card
      await tester.drag(find.byType(AspectRatio).first, const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Deve ter avançado para Scouter HUD
      expect(find.text('SCOUTER HUD'), findsOneWidget);

      // Arrastar novamente para a esquerda
      await tester.drag(find.byType(AspectRatio).first, const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Deve ter avançado para Rodapé Minimalista
      expect(find.text('RODAPÉ MINIMALISTA'), findsOneWidget);

      // Arrastar da esquerda para a direita (swipe right)
      await tester.drag(find.byType(AspectRatio).first, const Offset(300, 0));
      await tester.pumpAndSettle();

      // Deve voltar para Scouter HUD
      expect(find.text('SCOUTER HUD'), findsOneWidget);
    });

    testWidgets('Deve exibir a contagem de PRs da sessão específica no modo Scouter HUD', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompartilharCardModal(
              sessao: sessaoMock,
              prsSessao: 2,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Muda para Scouter HUD
      final proximoBtn = find.byTooltip('Próximo preset');
      await tester.tap(proximoBtn);
      await tester.pumpAndSettle();

      expect(find.text('SCOUTER HUD'), findsOneWidget);
      expect(find.text('2 PRs'), findsOneWidget);
    });
  });
}
