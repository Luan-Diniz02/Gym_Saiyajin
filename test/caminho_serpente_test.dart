import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/controllers/historico_controller.dart';
import 'package:gym_saiyajin/controllers/treino_controller.dart';
import 'package:gym_saiyajin/models/exercicio.dart';
import 'package:gym_saiyajin/models/serie.dart';
import 'package:gym_saiyajin/models/sessao_treino.dart';
import 'package:gym_saiyajin/repositories/treino_repository.dart';
import 'package:gym_saiyajin/screens/historico_screen.dart';
import 'package:gym_saiyajin/services/notification_service.dart';
import 'package:gym_saiyajin/services/preferences_service.dart';
import 'package:gym_saiyajin/widgets/caminho_serpente_progress_bar.dart';
import 'package:gym_saiyajin/widgets/modal_ajuste_tempo_sessao.dart';

class FakeTreinoRepository extends Fake implements TreinoRepository {
  List<SessaoTreino> sessoes = [];
  SessaoTreino? sessaoSalva;
  SessaoTreino? sessaoAtualizada;

  @override
  Future<List<Map<String, String>>> buscarExerciciosUnicosRegistrados() async => [];

  @override
  Future<void> salvarSessaoTreino(SessaoTreino sessao) async {
    sessaoSalva = sessao;
    sessoes.add(sessao);
  }

  @override
  Future<List<SessaoTreino>> buscarHistoricoTreinos() async {
    return List.from(sessoes);
  }

  @override
  Future<void> atualizarSessaoTreino(SessaoTreino sessao) async {
    sessaoAtualizada = sessao;
    final index = sessoes.indexWhere((s) => s.id == sessao.id);
    if (index >= 0) {
      sessoes[index] = sessao;
    }
  }

  @override
  Future<void> excluirSessaoTreino(int id) async {
    sessoes.removeWhere((s) => s.id == id);
  }
}

class FakePreferencesService extends Fake implements PreferencesService {
  @override
  Future<int?> lerInt(String key) async => null;
  @override
  Future<String?> lerString(String key) async => null;
  @override
  Future<void> salvarInt(String key, int value) async {}
}

class FakeNotificationService extends Fake implements NotificationService {
  @override
  Future<void> cancelarNotificacao() async {}
  @override
  Future<void> agendarNotificacaoDescanso(int segundos) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Caminho da Serpente - Métricas e Progressão', () {
    late FakeTreinoRepository repository;
    late HistoricoController controller;

    setUp(() {
      repository = FakeTreinoRepository();
      controller = HistoricoController(repository: repository);
    });

    tearDown(() {
      controller.dispose();
    });

    test('Histórico vazio deve ter 0 km e marco inicial', () async {
      await controller.carregarHistorico();

      expect(controller.volumeTotalGeral, 0.0);
      expect(controller.tempoTotalMinutosGeral, 0);
      expect(controller.distanciaCaminhoSerpenteKm, 0.0);
      expect(controller.progressoCaminhoSerpente, 0.0);
      expect(controller.marcoCaminhoSerpente, contains('Cauda da Serpente'));
    });

    test('Cálculo da distância do Caminho da Serpente com sessões registradas', () async {
      // Cria sessão com 2.000 kg de volume e 60 minutos (3600s) de treino
      final sessao1 = SessaoTreino(
        id: 1,
        data: DateTime(2026, 3, 10),
        nomeTreino: 'Push',
        duracaoSegundos: 3600,
        descansoTotalSegundos: 600,
        exerciciosConcluidosHoje: [
          Exercicio(
            nome: 'Supino Reto',
            grupo: 'PEITO',
            seriesDetalhes: [
              Serie(reps: 10, peso: 100, concluida: true), // 1000 kg
              Serie(reps: 10, peso: 100, concluida: true), // 1000 kg
            ],
          ),
        ],
      );

      // Volume = 2000 kg. Minutos = 60.
      // km = (2000 / 10) + (60 * 2) = 200 + 120 = 320 km.
      repository.sessoes = [sessao1];
      await controller.carregarHistorico();

      expect(controller.volumeTotalGeral, 2000.0);
      expect(controller.tempoTotalMinutosGeral, 60);
      expect(controller.distanciaCaminhoSerpenteKm, 320.0);
      expect(controller.progressoCaminhoSerpente, closeTo(320.0 / 1000000.0, 0.00001));
      expect(controller.marcoCaminhoSerpente, contains('Cauda da Serpente'));
    });

    test('Atualizar sessão via controller deve salvar no repositório e recarregar histórico', () async {
      final sessaoOriginal = SessaoTreino(
        id: 10,
        data: DateTime(2026, 3, 10),
        nomeTreino: 'Legs',
        duracaoSegundos: 1800,
        descansoTotalSegundos: 300,
        exerciciosConcluidosHoje: [],
      );

      repository.sessoes = [sessaoOriginal];
      await controller.carregarHistorico();

      final sessaoAtualizada = sessaoOriginal.copyWith(
        nomeTreino: 'Legs Super Saiyajin',
        duracaoSegundos: 3600,
      );

      await controller.atualizarSessao(sessaoAtualizada);

      expect(repository.sessaoAtualizada?.nomeTreino, 'Legs Super Saiyajin');
      expect(repository.sessaoAtualizada?.duracaoSegundos, 3600);
      expect(controller.historicoTreinos.first.sessao.nomeTreino, 'Legs Super Saiyajin');
    });
  });

  group('TreinoController - Edição de Tempos no Encerramento', () {
    late FakeTreinoRepository repository;
    late TreinoController controller;

    setUp(() {
      repository = FakeTreinoRepository();
      controller = TreinoController(
        repository: repository,
        preferencesService: FakePreferencesService(),
        notificationService: FakeNotificationService(),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('encerrarTreino deve respeitar duracaoSegundosPersonalizada e descansoTotalPersonalizado', () async {
      controller.iniciarNovoExercicio('Agachamento', 'PERNAS');
      controller.atualizarPesoSerie(0, '100');
      controller.atualizarRepsSerie(0, '10');

      // Encerra passando duração e descanso personalizados
      final sessao = await controller.encerrarTreino(
        descartarAtual: false,
        duracaoSegundosPersonalizada: 4500, // 1h 15m
        descansoTotalSegundosPersonalizado: 900, // 15m
      );

      expect(sessao, isNotNull);
      expect(sessao!.duracaoSegundos, 4500);
      expect(sessao.descansoTotalSegundos, 900);
      expect(repository.sessaoSalva?.duracaoSegundos, 4500);
      expect(repository.sessaoSalva?.descansoTotalSegundos, 900);
    });
  });

  group('CaminhoSerpenteProgressBar Widget Tests', () {
    testWidgets('Renderiza sem erros com progresso 0.0, 0.5 e 1.0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CaminhoSerpenteProgressBar(progresso: 0.0),
          ),
        ),
      );
      expect(find.byType(CaminhoSerpenteProgressBar), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CaminhoSerpenteProgressBar(progresso: 0.5),
          ),
        ),
      );
      expect(find.byType(CaminhoSerpenteProgressBar), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CaminhoSerpenteProgressBar(progresso: 1.0),
          ),
        ),
      );
      expect(find.byType(CaminhoSerpenteProgressBar), findsOneWidget);
    });
  });

  group('ModalAjusteTempoSessao Widget Tests', () {
    testWidgets('Steppers de 5 em 5 minutos e respeito ao limite máximo', (tester) async {
      int? tempoResultado;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                tempoResultado = await ModalAjusteTempoSessao.show(
                  context: context,
                  titulo: 'Ajustar Descanso',
                  icone: Icons.pause_circle_outline,
                  corDestaque: const Color(0xFF00E5FF),
                  tempoInicialSegundos: 600, // 10m
                  limiteMaximoSegundos: 900, // 15m limite
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Ajustar Descanso'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);

      // Clica em +5m -> deve ir para 15:00 (900s)
      await tester.tap(find.text('+5m'));
      await tester.pumpAndSettle();
      expect(find.text('15:00'), findsOneWidget);

      // Clica em +5m novamente -> não deve ultrapassar o limite de 15:00 (900s)
      await tester.tap(find.text('+5m'));
      await tester.pumpAndSettle();
      expect(find.text('15:00'), findsOneWidget);

      // Clica em -5m -> deve voltar para 10:00 (600s)
      await tester.tap(find.text('-5m'));
      await tester.pumpAndSettle();
      expect(find.text('10:00'), findsOneWidget);

      // Confirma e verifica resultado
      await tester.tap(find.text('CONFIRMAR'));
      await tester.pumpAndSettle();
      expect(tempoResultado, 600);
    });
  });

  group('HistoricoScreen - Colapso e Expansão', () {
    late FakeTreinoRepository repository;
    late HistoricoController controller;

    setUp(() {
      repository = FakeTreinoRepository();
      controller = HistoricoController(repository: repository);
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('Sessões devem iniciar colapsadas e expandir com toque', (tester) async {
      final sessao = SessaoTreino(
        id: 1,
        data: DateTime(2026, 3, 15),
        nomeTreino: 'Super Saiyajin Costas',
        duracaoSegundos: 2700,
        descansoTotalSegundos: 600,
        exerciciosConcluidosHoje: [
          Exercicio(
            nome: 'Puxada Frontal',
            grupo: 'COSTAS',
            seriesDetalhes: [
              Serie(reps: 12, peso: 70, concluida: true),
            ],
          ),
        ],
      );
      repository.sessoes = [sessao];
      await controller.carregarHistorico();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoricoScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Sessão está visível no resumo
      expect(find.text('SUPER SAIYAJIN COSTAS'), findsOneWidget);
      expect(find.text('1 EXERCÍCIOS'), findsOneWidget);

      // Porém os detalhes do exercício começam COLAPSADOS por padrão ("1 - Todos colapsados")
      expect(find.text('Puxada Frontal'), findsNothing);

      // Clica no header da sessão para expandir
      await tester.tap(find.text('SUPER SAIYAJIN COSTAS'));
      await tester.pumpAndSettle();

      // Agora o exercício detalhado deve estar visível
      expect(find.text('Puxada Frontal'), findsOneWidget);

      // Clica novamente para recolher
      await tester.tap(find.text('SUPER SAIYAJIN COSTAS'));
      await tester.pumpAndSettle();

      // Volta a ficar oculto
      expect(find.text('Puxada Frontal'), findsNothing);
    });

    testWidgets('Caminho da Serpente alterna entre compacto e expandido', (tester) async {
      await controller.carregarHistorico();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoricoScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header está visível
      expect(find.text('CAMINHO DA SERPENTE'), findsOneWidget);

      // Inicialmente compacto: a barra customizada com custom painter ainda não está expandida
      expect(find.byType(CaminhoSerpenteProgressBar), findsNothing);

      // Clica para expandir
      await tester.tap(find.text('CAMINHO DA SERPENTE'));
      await tester.pumpAndSettle();

      // Agora o CaminhoSerpenteProgressBar e a meta estão visíveis
      expect(find.byType(CaminhoSerpenteProgressBar), findsOneWidget);
      expect(find.text('Meta: 1.000.000 km'), findsOneWidget);

      // Clica para recolher novamente
      await tester.tap(find.text('CAMINHO DA SERPENTE'));
      await tester.pumpAndSettle();

      // Volta a ficar compacto
      expect(find.byType(CaminhoSerpenteProgressBar), findsNothing);
    });
  });
}
