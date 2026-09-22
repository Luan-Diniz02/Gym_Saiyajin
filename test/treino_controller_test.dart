import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/controllers/treino_controller.dart';
import 'package:gym_saiyajin/models/ficha_treino.dart';
import 'package:gym_saiyajin/models/serie.dart';
import 'package:gym_saiyajin/models/sessao_treino.dart';
import 'package:gym_saiyajin/repositories/treino_repository.dart';
import 'package:gym_saiyajin/services/notification_service.dart';
import 'package:gym_saiyajin/services/preferences_service.dart';

class FakeTreinoRepository extends Fake implements TreinoRepository {
  final List<FichaTreino> fichasCadastradas = [];
  final Map<String, List<Serie>> seriesHistoricas = {};
  SessaoTreino? ultimaSessaoSalva;

  @override
  Future<List<Map<String, String>>> buscarExerciciosUnicosRegistrados() async => [];

  @override
  Future<List<Serie>> buscarUltimasSeriesExercicio(String nomeExercicio) async {
    return seriesHistoricas[nomeExercicio.toLowerCase().trim()] ?? [];
  }

  @override
  Future<List<FichaTreino>> buscarFichas() async => List.from(fichasCadastradas);

  @override
  Future<int> salvarFicha(FichaTreino ficha) async {
    final int id = ficha.id ?? (fichasCadastradas.length + 1);
    fichasCadastradas.removeWhere((f) => f.id == id);
    fichasCadastradas.add(ficha.copyWith(id: id));
    return id;
  }

  @override
  Future<void> excluirFicha(int fichaId) async {
    fichasCadastradas.removeWhere((f) => f.id == fichaId);
  }

  @override
  Future<void> salvarSessaoTreino(SessaoTreino sessao) async {
    ultimaSessaoSalva = sessao;
  }
}

class FakePreferencesService extends Fake implements PreferencesService {
  @override
  Future<int?> lerInt(String key) async => null;
  @override
  Future<String?> lerString(String key) async => null;
}

class FakeNotificationService extends Fake implements NotificationService {
  @override
  Future<void> cancelarNotificacao() async {}
  @override
  Future<void> agendarNotificacaoDescanso(int segundos) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('TreinoController - Gerenciamento de Séries', () {
    test('Deve permitir adicionar e remover séries individuais mantendo ao menos uma', () {
      controller.iniciarNovoExercicio('Supino Reto', 'PEITO');
      expect(controller.exercicioAtual?.seriesDetalhes.length, equals(1));

      controller.adicionarSerie();
      controller.adicionarSerie();
      expect(controller.exercicioAtual?.seriesDetalhes.length, equals(3));

      controller.removerSerie(1);
      expect(controller.exercicioAtual?.seriesDetalhes.length, equals(2));

      controller.removerSerie(0);
      expect(controller.exercicioAtual?.seriesDetalhes.length, equals(1));

      controller.removerSerie(0);
      expect(controller.exercicioAtual?.seriesDetalhes.length, equals(1));
    });
  });

  group('TreinoController - Nome / Divisão do Treino', () {
    test('Deve definir nome do treino e persistir ao encerrar sessão', () async {
      controller.definirNomeTreino('Treino A - Peito e Tríceps');
      expect(controller.nomeTreino, equals('Treino A - Peito e Tríceps'));

      controller.iniciarNovoExercicio('Supino Reto', 'PEITO');
      controller.atualizarPesoSerie(0, '80');
      controller.atualizarRepsSerie(0, '10');

      final sessao = await controller.encerrarTreino(descartarAtual: false);
      expect(sessao, isNotNull);
      expect(sessao?.nomeTreino, equals('Treino A - Peito e Tríceps'));
      expect(repository.ultimaSessaoSalva?.nomeTreino, equals('Treino A - Peito e Tríceps'));
      expect(controller.nomeTreino, isNull); // Reseta após encerrar
    });
  });

  group('TreinoController - Carga Anterior nos Inputs', () {
    test('Deve carregar e disponibilizar série anterior para o exercício atual', () async {
      repository.seriesHistoricas['supino reto'] = [
        Serie(peso: 75.0, reps: 10, concluida: true),
        Serie(peso: 80.0, reps: 8, concluida: true),
      ];

      controller.iniciarNovoExercicio('Supino Reto', 'PEITO', quantidadeSeries: 2);
      await controller.carregarSeriesAnteriores('Supino Reto');

      final serie0 = controller.obterSerieAnterior('Supino Reto', 0);
      expect(serie0?.peso, equals(75.0));
      expect(serie0?.reps, equals(10));

      final serie1 = controller.obterSerieAnterior('Supino Reto', 1);
      expect(serie1?.peso, equals(80.0));
      expect(serie1?.reps, equals(8));

      // Se pedir uma série além da quantidade anterior, retorna a última de referência
      final serie2 = controller.obterSerieAnterior('Supino Reto', 2);
      expect(serie2?.peso, equals(80.0));
      expect(serie2?.reps, equals(8));
    });

    test('Deve preencher série com carga anterior via preencherSerieComAnterior', () async {
      repository.seriesHistoricas['supino reto'] = [
        Serie(peso: 75.0, reps: 10, concluida: true),
      ];

      controller.iniciarNovoExercicio('Supino Reto', 'PEITO', quantidadeSeries: 1);
      await controller.carregarSeriesAnteriores('Supino Reto');

      expect(controller.exercicioAtual?.seriesDetalhes[0].peso, isNull);
      expect(controller.exercicioAtual?.seriesDetalhes[0].reps, isNull);

      final sucesso = controller.preencherSerieComAnterior(0);
      expect(sucesso, isTrue);
      expect(controller.exercicioAtual?.seriesDetalhes[0].peso, equals(75.0));
      expect(controller.exercicioAtual?.seriesDetalhes[0].reps, equals(10));
    });

    test('toggleConcluidaSerie deve auto-preencher com série anterior se campos estiverem vazios', () async {
      repository.seriesHistoricas['supino reto'] = [
        Serie(peso: 90.0, reps: 6, concluida: true),
      ];

      controller.iniciarNovoExercicio('Supino Reto', 'PEITO', quantidadeSeries: 1);
      await controller.carregarSeriesAnteriores('Supino Reto');

      controller.toggleConcluidaSerie(0);
      expect(controller.exercicioAtual?.seriesDetalhes[0].concluida, isTrue);
      expect(controller.exercicioAtual?.seriesDetalhes[0].peso, equals(90.0));
      expect(controller.exercicioAtual?.seriesDetalhes[0].reps, equals(6));
    });
  });

  group('TreinoController - Fichas e Substituição de Exercícios', () {
    test('Deve carregar ficha, enfileirar exercícios e permitir substituição por aparelho ocupado', () async {
      final ficha = FichaTreino(
        id: 1,
        nome: 'Ficha A',
        exercicios: [
          FichaExercicioItem(nome: 'Supino Reto Barra', grupo: 'PEITO', seriesPadrao: 3),
          FichaExercicioItem(nome: 'Crucifixo Máquina', grupo: 'PEITO', seriesPadrao: 3),
        ],
      );
      await repository.salvarFicha(ficha);
      await controller.carregarFichas();

      controller.carregarFichaParaTreino(ficha);

      expect(controller.nomeTreino, equals('Ficha A'));
      expect(controller.exercicioAtual?.nome, equals('Supino Reto Barra'));
      expect(controller.exercicioAtual?.seriesDetalhes.length, equals(3));
      expect(controller.exerciciosFichaPendentes.length, equals(1));
      expect(controller.exerciciosFichaPendentes.first.nome, equals('Crucifixo Máquina'));

      // Simulação: Aparelho ocupado! Usuário substitui o exercício atual
      controller.substituirExercicioAtual('Supino Reto com Halteres', 'PEITO');
      expect(controller.exercicioAtual?.nome, equals('Supino Reto com Halteres'));
      expect(controller.exercicioAtual?.seriesDetalhes.length, equals(3));

      // Simulação: Aparelho ocupado no próximo exercício pendente da ficha!
      controller.substituirExercicioPendente(0, 'Crossover Polia', 'PEITO');
      expect(controller.exerciciosFichaPendentes.first.nome, equals('Crossover Polia'));

      // A ficha original cadastrada no banco/repositório permanece intacta!
      final fichasOriginais = await repository.buscarFichas();
      expect(fichasOriginais.first.exercicios.first.nome, equals('Supino Reto Barra'));
      expect(fichasOriginais.first.exercicios.last.nome, equals('Crucifixo Máquina'));
    });

    test('Deve salvar treino atual como uma nova ficha', () async {
      controller.iniciarNovoExercicio('Agachamento Livre', 'PERNAS', quantidadeSeries: 1);
      controller.atualizarPesoSerie(0, '100');
      controller.atualizarRepsSerie(0, '8');
      controller.finalizarExercicioAtual();

      controller.iniciarNovoExercicio('Leg Press 45', 'PERNAS', quantidadeSeries: 3);

      final novaFicha = await controller.salvarTreinoAtualComoFicha('Ficha Pernas');
      expect(novaFicha, isNotNull);
      expect(novaFicha?.nome, equals('Ficha Pernas'));
      expect(novaFicha?.exercicios.length, equals(2));
      expect(novaFicha?.exercicios[0].nome, equals('Agachamento Livre'));
      expect(novaFicha?.exercicios[1].nome, equals('Leg Press 45'));
    });
  });
}
