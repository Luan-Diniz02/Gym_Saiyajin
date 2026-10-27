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
      expect(find.text('Remover Série 1?'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Remover'), findsOneWidget);

      // Toca em Cancelar
      await tester.tap(find.text('Cancelar'));
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

      expect(find.text('Remover Série 1?'), findsOneWidget);

      // Toca em Remover
      await tester.tap(find.text('Remover'));
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
  });
}
