import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/controllers/historico_controller.dart';
import 'package:gym_saiyajin/controllers/treino_controller.dart';
import 'package:gym_saiyajin/models/exercicio.dart';
import 'package:gym_saiyajin/models/serie.dart';
import 'package:gym_saiyajin/models/sessao_treino.dart';
import 'package:gym_saiyajin/repositories/treino_repository.dart';
import 'package:gym_saiyajin/services/notification_service.dart';
import 'package:gym_saiyajin/services/preferences_service.dart';

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
}
