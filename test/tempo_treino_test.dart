import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/controllers/treino_controller.dart';
import 'package:gym_saiyajin/models/sessao_treino.dart';
import 'package:gym_saiyajin/repositories/treino_repository.dart';
import 'package:gym_saiyajin/services/notification_service.dart';
import 'package:gym_saiyajin/services/preferences_service.dart';

class FakeTreinoRepository extends Fake implements TreinoRepository {
  SessaoTreino? sessaoSalva;

  @override
  Future<List<Map<String, String>>> buscarExerciciosUnicosRegistrados() async => [];

  @override
  Future<void> salvarSessaoTreino(SessaoTreino sessao) async {
    sessaoSalva = sessao;
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TreinoController - Cronômetro de Treino e Descanso', () {
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

    test('formatarTempoLegivel deve formatar corretamente segundos em MM:SS e HH:MM:SS', () {
      expect(controller.formatarTempoLegivel(0), '00:00');
      expect(controller.formatarTempoLegivel(59), '00:59');
      expect(controller.formatarTempoLegivel(60), '01:00');
      expect(controller.formatarTempoLegivel(125), '02:05');
      expect(controller.formatarTempoLegivel(3600), '01:00:00');
      expect(controller.formatarTempoLegivel(3665), '01:01:05');
    });

    test('Iniciar novo exercício deve iniciar o treino geral automaticamente', () {
      expect(controller.isTreinoEmAndamento, false);

      controller.iniciarNovoExercicio('Supino Reto', 'PEITO');

      expect(controller.isTreinoEmAndamento, true);
      expect(controller.isTreinoPausado, false);
    });

    test('Deve permitir pausar e retomar o cronômetro do treino geral', () {
      controller.iniciarTreinoSeNecessario();
      expect(controller.isTreinoEmAndamento, true);
      expect(controller.isTreinoPausado, false);

      controller.alternarPausaTreinoGeral();
      expect(controller.isTreinoPausado, true);

      controller.alternarPausaTreinoGeral();
      expect(controller.isTreinoPausado, false);
    });

    test('Encerrar treino deve retornar SessaoTreino com duração e resetar o estado', () async {
      controller.iniciarNovoExercicio('Agachamento', 'PERNAS');
      controller.atualizarPesoSerie(0, '100');
      controller.atualizarRepsSerie(0, '10');
      controller.finalizarExercicioAtual();

      final sessaoConcluida = await controller.encerrarTreino(descartarAtual: false);

      expect(sessaoConcluida, isNotNull);
      expect(repository.sessaoSalva, isNotNull);
      expect(controller.isTreinoEmAndamento, false);
      expect(controller.duracaoTreinoSegundos, 0);
      expect(controller.descansoTotalSegundos, 0);
      expect(controller.exerciciosConcluidosHoje.isEmpty, true);
    });
  });
}
