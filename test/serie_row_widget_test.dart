import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/controllers/treino_controller.dart';
import 'package:gym_saiyajin/models/ficha_treino.dart';
import 'package:gym_saiyajin/models/recorde_pessoal.dart';
import 'package:gym_saiyajin/models/serie.dart';
import 'package:gym_saiyajin/models/sessao_treino.dart';
import 'package:gym_saiyajin/repositories/treino_repository.dart';
import 'package:gym_saiyajin/services/notification_service.dart';
import 'package:gym_saiyajin/services/preferences_service.dart';
import 'package:gym_saiyajin/widgets/calculadora_anilhas_modal.dart';
import 'package:gym_saiyajin/widgets/kinto_un_icon.dart';
import 'package:gym_saiyajin/widgets/serie_row_widget.dart';

class FakeTreinoRepository extends Fake implements TreinoRepository {
  RecordePessoal? recordeHistoricoMock;

  @override
  Future<List<Map<String, String>>> buscarExerciciosUnicosRegistrados() async => [];
  @override
  Future<List<Serie>> buscarUltimasSeriesExercicio(String nomeExercicio) async => [];
  @override
  Future<RecordePessoal?> buscarRecordeHistoricoExercicio(String nomeExercicio) async => recordeHistoricoMock;
  @override
  Future<List<FichaTreino>> buscarFichas() async => [];
  @override
  Future<void> salvarSessaoTreino(SessaoTreino sessao) async {}
}

class FakePreferencesService extends Fake implements PreferencesService {
  @override
  Future<int?> lerInt(String key) async => null;
  @override
  Future<String?> lerString(String key) async => null;
}

class FakeNotificationService extends Fake implements NotificationService {
  @override
  Future<void> agendarNotificacaoDescanso(int segundos) async {}
  @override
  Future<void> cancelarNotificacao() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeTreinoRepository repository;
  late FakePreferencesService preferences;
  late FakeNotificationService notifications;
  late TreinoController controller;

  setUp(() {
    repository = FakeTreinoRepository();
    preferences = FakePreferencesService();
    notifications = FakeNotificationService();
    controller = TreinoController(
      repository: repository,
      preferencesService: preferences,
      notificationService: notifications,
    );
  });

  Widget criarWidgetTestavel(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('SerieRowWidget - Confirmação de Exclusão [UX-01]', () {
    testWidgets('Quando há apenas 1 série, não renderiza Dismissible', (tester) async {
      controller.iniciarNovoExercicio('Supino Reto', 'PEITO', quantidadeSeries: 1);

      await tester.pumpWidget(
        criarWidgetTestavel(
          SerieRowWidget(index: 0, controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsNothing);

      controller.dispose();
    });

    testWidgets('Quando há mais de 1 série e usuário arrasta, cancelamento mantém a série', (tester) async {
      controller.iniciarNovoExercicio('Supino Reto', 'PEITO', quantidadeSeries: 3);

      await tester.pumpWidget(
        criarWidgetTestavel(
          SerieRowWidget(index: 0, controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsOneWidget);

      // Desliza para a esquerda para disparar a exclusão
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Confere se o diálogo foi aberto
      expect(find.text('REMOVER SÉRIE 1?'), findsOneWidget);
      expect(find.text('CANCELAR'), findsOneWidget);
      expect(find.text('REMOVER'), findsOneWidget);

      // Toca em CANCELAR
      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();

      // A série ainda deve existir no controller
      final exercicio = controller.exercicioAtual;
      expect(exercicio?.seriesDetalhes.length, 3);

      controller.dispose();
    });

    testWidgets('Quando há mais de 1 série e usuário confirma, a série é removida', (tester) async {
      controller.iniciarNovoExercicio('Supino Reto', 'PEITO', quantidadeSeries: 3);

      await tester.pumpWidget(
        criarWidgetTestavel(
          SerieRowWidget(index: 0, controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Desliza para a esquerda para disparar a exclusão
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('REMOVER SÉRIE 1?'), findsOneWidget);

      // Toca em REMOVER
      await tester.tap(find.text('REMOVER'));
      await tester.pumpAndSettle();

      // Agora o controller deve ter apenas 2 séries
      final exercicio = controller.exercicioAtual;
      expect(exercicio?.seriesDetalhes.length, 2);

      controller.dispose();
    });
  });

  group('SerieRowWidget - Tipos de Série (Padrão Hevy) e RIR/RPE', () {
    testWidgets('Toque no badge da série alterna entre Normal, Aquecimento, Drop-set e Falha', (tester) async {
      controller.iniciarNovoExercicio('Supino Reto', 'PEITO', quantidadeSeries: 1);

      await tester.pumpWidget(
        criarWidgetTestavel(
          SerieRowWidget(index: 0, controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      final badgeFinder = find.byKey(const ValueKey('badge-tipo-serie-0'));
      expect(badgeFinder, findsOneWidget);
      expect(find.text('SÉRIE DE TRABALHO'), findsOneWidget);

      // 1º toque -> Aquecimento
      await tester.tap(badgeFinder);
      await tester.pumpAndSettle();
      expect(controller.exercicioAtual!.seriesDetalhes[0].tipo, 'warmup');
      expect(find.byType(KintoUnIcon), findsWidgets);
      expect(find.text('AQUECIMENTO'), findsOneWidget);

      // 2º toque -> Drop-set
      await tester.tap(badgeFinder);
      await tester.pumpAndSettle();
      expect(controller.exercicioAtual!.seriesDetalhes[0].tipo, 'dropset');
      expect(find.text('DROP-SET'), findsOneWidget);

      // 3º toque -> Falha Total (define RIR 0 automaticamente)
      await tester.tap(badgeFinder);
      await tester.pumpAndSettle();
      expect(controller.exercicioAtual!.seriesDetalhes[0].tipo, 'falha');
      expect(controller.exercicioAtual!.seriesDetalhes[0].rir, 0);
      expect(find.text('FALHA TOTAL'), findsOneWidget);
      expect(find.text('RIR 0 • RPE 10'), findsOneWidget);

      // 4º toque -> Volta para Normal e reseta o RIR/RPE para o padrão (null)
      await tester.tap(badgeFinder);
      await tester.pumpAndSettle();
      expect(controller.exercicioAtual!.seriesDetalhes[0].tipo, 'normal');
      expect(controller.exercicioAtual!.seriesDetalhes[0].rir, isNull);
      expect(find.text('RIR / RPE'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Toque longo no círculo da série abre o modal de classificação', (tester) async {
      controller.iniciarNovoExercicio('Supino Reto', 'PEITO', quantidadeSeries: 1);

      await tester.pumpWidget(
        criarWidgetTestavel(
          SerieRowWidget(index: 0, controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      final badgeFinder = find.byKey(const ValueKey('badge-tipo-serie-0'));
      await tester.longPress(badgeFinder);
      await tester.pumpAndSettle();

      expect(find.text('CLASSIFICAÇÃO DA SÉRIE 1'), findsOneWidget);
      expect(find.text('Aquecimento'), findsOneWidget);
      expect(find.text('Drop-set'), findsOneWidget);
      expect(find.text('Falha Total'), findsOneWidget);

      await tester.tap(find.text('Drop-set'));
      await tester.pumpAndSettle();

      expect(controller.exercicioAtual!.seriesDetalhes[0].tipo, 'dropset');

      controller.dispose();
    });

    testWidgets('Séries de Aquecimento não consomem a numeração das séries de trabalho (padrão Hevy)', (tester) async {
      controller.iniciarNovoExercicio('Supino Reto', 'PEITO', quantidadeSeries: 3);
      controller.atualizarTipoSerie(0, 'warmup');

      await tester.pumpWidget(
        criarWidgetTestavel(
          Column(
            children: [
              SerieRowWidget(index: 0, controller: controller),
              SerieRowWidget(index: 1, controller: controller),
              SerieRowWidget(index: 2, controller: controller),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Como a linha 0 é Aquecimento, a linha 1 (Normal) deve ser numerada como '1' e a linha 2 como '2'
      expect(
        Serie.calcularNumeroSerieTrabalho(controller.exercicioAtual!.seriesDetalhes, 1),
        1,
      );
      expect(
        Serie.calcularNumeroSerieTrabalho(controller.exercicioAtual!.seriesDetalhes, 2),
        2,
      );

      controller.dispose();
    });

    testWidgets('Seletor retrátil de RIR/RPE permite registrar e limpar esforço da série', (tester) async {
      controller.iniciarNovoExercicio('Agachamento Livre', 'PERNAS', quantidadeSeries: 1);

      await tester.pumpWidget(
        criarWidgetTestavel(
          SerieRowWidget(index: 0, controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      final btnRir = find.byKey(const ValueKey('btn-rir-0'));
      expect(find.text('RIR / RPE'), findsOneWidget);

      // Abre a barra retrátil de RIR
      await tester.tap(btnRir);
      await tester.pumpAndSettle();

      final chipRir2 = find.byKey(const ValueKey('chip-rir-0-2'));
      expect(chipRir2, findsOneWidget);

      // Seleciona RIR 2 (RPE 8)
      await tester.tap(chipRir2);
      await tester.pumpAndSettle();

      expect(controller.exercicioAtual!.seriesDetalhes[0].rir, 2);
      expect(find.text('RIR 2 • RPE 8'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Série marcada como Aquecimento (warmup) nunca dispara alerta de PR', (tester) async {
      repository.recordeHistoricoMock = const RecordePessoal(
        exercicioNome: 'Supino Reto',
        grupo: 'PEITO',
        cargaMaxima: 80.0,
        repsCargaMaxima: 8,
        umRepMaxEstimado: 101.3,
        peso1RM: 80.0,
        reps1RM: 8,
      );

      controller.iniciarNovoExercicio('Supino Reto', 'PEITO', quantidadeSeries: 1);
      await tester.pumpAndSettle();

      controller.atualizarPesoSerie(0, '100');
      controller.atualizarRepsSerie(0, '10');
      controller.toggleConcluidaSerie(0);

      // Como série normal, supera o recorde base
      expect(controller.isSerieRecorde('Supino Reto', 0), isTrue);
      expect(controller.totalRecordesBatidosHoje, 1);

      // Ao marcar como warmup, deixa de ser PR imediatamente
      controller.atualizarTipoSerie(0, 'warmup');
      expect(controller.isSerieRecorde('Supino Reto', 0), isFalse);
      expect(controller.totalRecordesBatidosHoje, 0);

      controller.dispose();
    });

    testWidgets(
      'Detecta inversão acidental entre Peso e Reps e permite inverter com 1 toque no pop-up',
      (tester) async {
        repository.recordeHistoricoMock = const RecordePessoal(
          exercicioNome: 'Supino Reto',
          grupo: 'PEITO',
          cargaMaxima: 60.0,
          repsCargaMaxima: 12,
          umRepMaxEstimado: 84.0,
          peso1RM: 60.0,
          reps1RM: 12,
        );

        controller.iniciarNovoExercicio(
          'Supino Reto',
          'PEITO',
          quantidadeSeries: 1,
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          criarWidgetTestavel(
            SerieRowWidget(index: 0, controller: controller),
          ),
        );
        await tester.pumpAndSettle();

        // Atleta digita 12 kg x 60 reps por engano (invertido)
        controller.atualizarPesoSerie(0, '12');
        controller.atualizarRepsSerie(0, '60');
        await tester.pumpAndSettle();

        // Toca no botão de check da série
        await tester.tap(find.byKey(const ValueKey('btn-check-serie-0')));
        await tester.pumpAndSettle();

        // O pop-up de aviso de inversão deve aparecer e a série ainda não está concluída
        expect(find.text('VALORES INVERTIDOS?'), findsOneWidget);
        expect(controller.exercicioAtual!.seriesDetalhes[0].concluida, isFalse);

        // Toca no botão de inverter (60 kg x 12 reps)
        await tester.tap(find.byKey(const Key('btn-inverter-serie')));
        await tester.pumpAndSettle();

        final serieCorrigida = controller.exercicioAtual!.seriesDetalhes[0];
        expect(serieCorrigida.peso, 60.0);
        expect(serieCorrigida.reps, 12);
        expect(serieCorrigida.concluida, isTrue);

        controller.dispose();
      },
    );

    testWidgets(
      'Detecta salto anômalo de carga (ex: dígito extra) e exibe pop-up de confirmação antes de concluir',
      (tester) async {
        repository.recordeHistoricoMock = const RecordePessoal(
          exercicioNome: 'Rosca Direta',
          grupo: 'BÍCEPS',
          cargaMaxima: 30.0,
          repsCargaMaxima: 10,
          umRepMaxEstimado: 40.0,
          peso1RM: 30.0,
          reps1RM: 10,
        );

        controller.iniciarNovoExercicio(
          'Rosca Direta',
          'BÍCEPS',
          quantidadeSeries: 1,
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          criarWidgetTestavel(
            SerieRowWidget(index: 0, controller: controller),
          ),
        );
        await tester.pumpAndSettle();

        // Atleta digita 300 kg em vez de 30 kg
        controller.atualizarPesoSerie(0, '300');
        controller.atualizarRepsSerie(0, '10');
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('btn-check-serie-0')));
        await tester.pumpAndSettle();

        expect(find.text('VALOR INCOMUM?'), findsOneWidget);
        expect(controller.exercicioAtual!.seriesDetalhes[0].concluida, isFalse);

        // Se escolher CORRIGIR, fecha o modal e mantém a série pendente
        await tester.tap(find.byKey(const Key('btn-editar-anomalia')));
        await tester.pumpAndSettle();
        expect(controller.exercicioAtual!.seriesDetalhes[0].concluida, isFalse);

        // Se tocar novamente e escolher CONFIRMAR ASSIM, conclui a série
        await tester.tap(find.byKey(const ValueKey('btn-check-serie-0')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('btn-confirmar-anomalia')));
        await tester.pumpAndSettle();

        expect(controller.exercicioAtual!.seriesDetalhes[0].concluida, isTrue);

        controller.dispose();
      },
    );

    testWidgets(
      'Calculadora de Anilhas decompõe carga alvo e aplica montagem na série [Proposta 5]',
      (tester) async {
        // 1. Verifica decomposição matemática pura (85 kg com barra de 20 kg = 32.5 kg/lado -> 25 + 5 + 2.5)
        final decomp = CalculadoraAnilhas.decomporCarga(
          pesoTotal: 85.0,
          pesoBarra: 20.0,
        );
        expect(decomp.pesoPorLado, 32.5);
        expect(decomp.anilhasPorLado, [25.0, 5.0, 2.5]);
        expect(decomp.pesoTotalMontado, 85.0);

        // 2. Verifica fluxo de UI a partir do botão ANILHAS na SerieRowWidget
        controller.iniciarNovoExercicio(
          'Supino Reto',
          'PEITO',
          quantidadeSeries: 1,
        );
        controller.atualizarPesoSerie(0, '60');
        await tester.pumpWidget(
          criarWidgetTestavel(
            SerieRowWidget(index: 0, controller: controller),
          ),
        );
        await tester.pumpAndSettle();

        // Abre a Calculadora de Anilhas
        await tester.tap(find.byKey(const ValueKey('btn-anilhas-0')));
        await tester.pumpAndSettle();

        expect(find.text('CALCULADORA DE ANILHAS'), findsOneWidget);
        // 60 kg (barra 20 + 20 kg cada lado)
        expect(find.byKey(const Key('anilha-montada-20')), findsOneWidget);

        // Adiciona +5 kg e depois +10 kg por lado (ordem crescente: 20 -> 5 -> 10) -> total passa para 90 kg
        await tester.ensureVisible(find.byKey(const Key('btn-add-anilha-5')));
        await tester.tap(find.byKey(const Key('btn-add-anilha-5')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('btn-add-anilha-10')));
        await tester.tap(find.byKey(const Key('btn-add-anilha-10')));
        await tester.pumpAndSettle();

        expect(find.text('90'), findsWidgets);
        expect(find.byKey(const Key('anilha-montada-5')), findsOneWidget);
        expect(find.byKey(const Key('anilha-montada-10')), findsOneWidget);

        // Aplica na série
        await tester.tap(find.byKey(const Key('btn-aplicar-anilhas')));
        await tester.pumpAndSettle();

        expect(controller.exercicioAtual!.seriesDetalhes[0].peso, 90.0);

        controller.dispose();
      },
    );
  });
}
