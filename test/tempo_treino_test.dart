import 'package:flutter/widgets.dart';
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
      expect(controller.formatarTempoLegivel(5400), '01:30:00');
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

    test('Simulação de salto temporal com tela desligada / background (1h30m sem ticks periódicos)', () {
      controller.iniciarTreinoSeNecessario();

      // Simula início há 90 minutos (1h 30m)
      final noventaMinAtras = DateTime.now().subtract(const Duration(minutes: 90));
      controller.setInicioTreinoParaTeste(noventaMinAtras);

      // Deve calcular exatamente 5400 segundos (90 min), mesmo sem ticks de timer intermediários
      expect(controller.duracaoTreinoSegundos, closeTo(5400, 2));
      expect(controller.duracaoTreinoFormatada, '01:30:00');
    });

    test('Simulação de salto temporal com pausa acumulada', () {
      controller.iniciarTreinoSeNecessario();

      // Treino iniciado há 90 minutos, com 15 minutos de pausa acumulada
      final inicio = DateTime.now().subtract(const Duration(minutes: 90));
      controller.setInicioTreinoParaTeste(inicio);
      controller.setTempoPausadoTotalParaTeste(const Duration(minutes: 15));

      // Duração = 90min - 15min = 75min = 4500s
      expect(controller.duracaoTreinoSegundos, closeTo(4500, 2));
      expect(controller.duracaoTreinoFormatada, '01:15:00');
    });

    test('Simulação de salto temporal enquanto o treino está pausado (não conta tempo de pausa)', () {
      controller.iniciarTreinoSeNecessario();

      // Treino iniciado há 60 minutos
      final inicio = DateTime.now().subtract(const Duration(minutes: 60));
      controller.setInicioTreinoParaTeste(inicio);

      // Pausa acionada há 30 minutos (portanto após 30 minutos de treino)
      controller.alternarPausaTreinoGeral();
      final momentoPausa = DateTime.now().subtract(const Duration(minutes: 30));
      controller.setInicioPausaAtualParaTeste(momentoPausa);

      expect(controller.isTreinoPausado, true);
      // Deve congelar em exatamente 30 minutos (1800s) decorridos antes da pausa
      expect(controller.duracaoTreinoSegundos, closeTo(1800, 2));
      expect(controller.duracaoTreinoFormatada, '30:00');
    });

    test('didChangeAppLifecycleState resumed dispara notifyListeners e recalcula tempo', () {
      controller.iniciarTreinoSeNecessario();
      controller.setInicioTreinoParaTeste(DateTime.now().subtract(const Duration(minutes: 45)));

      bool notified = false;
      controller.addListener(() => notified = true);

      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(notified, true);
      expect(controller.duracaoTreinoSegundos, closeTo(2700, 2));
      expect(controller.duracaoTreinoFormatada, '45:00');
    });

    test('Descanso em background que expira com a tela desligada finaliza corretamente', () {
      controller.iniciarTimer(); // padrão 90s

      // Simula que o descanso iniciou há 120s e atingiu o fim há 30s
      final inicioDescanso = DateTime.now().subtract(const Duration(seconds: 120));
      final fimDescanso = DateTime.now().subtract(const Duration(seconds: 30));
      controller.setInicioDescansoParaTeste(inicioDescanso, endTime: fimDescanso);

      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(controller.isTimerRodando, false);
      expect(controller.tempoAtual, 0);
      expect(controller.descansoTotalSegundos, 90);
    });

    test('Descanso em background ainda em andamento atualiza tempo restante e descanso acumulado', () {
      controller.iniciarTimer(); // padrão 90s

      // Simula que o descanso iniciou há 30s e terminará em 60s
      final inicioDescanso = DateTime.now().subtract(const Duration(seconds: 30));
      final fimDescanso = DateTime.now().add(const Duration(seconds: 60));
      controller.setInicioDescansoParaTeste(inicioDescanso, endTime: fimDescanso);

      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(controller.isTimerRodando, true);
      expect(controller.tempoAtual, closeTo(60, 2));
      expect(controller.descansoTotalSegundos, closeTo(30, 2));
    });

    test('Encerrar treino deve retornar SessaoTreino com duração exata e resetar o estado', () async {
      controller.iniciarNovoExercicio('Agachamento', 'PERNAS');
      controller.atualizarPesoSerie(0, '100');
      controller.atualizarRepsSerie(0, '10');
      controller.finalizarExercicioAtual();

      // Simula treino de 1h30m
      final inicio = DateTime.now().subtract(const Duration(minutes: 90));
      controller.setInicioTreinoParaTeste(inicio);

      final sessaoConcluida = await controller.encerrarTreino(descartarAtual: false);

      expect(sessaoConcluida, isNotNull);
      expect(sessaoConcluida!.duracaoSegundos, closeTo(5400, 2));
      expect(repository.sessaoSalva, isNotNull);
      expect(repository.sessaoSalva!.duracaoSegundos, closeTo(5400, 2));
      expect(controller.isTreinoEmAndamento, false);
      expect(controller.duracaoTreinoSegundos, 0);
      expect(controller.descansoTotalSegundos, 0);
      expect(controller.exerciciosConcluidosHoje.isEmpty, true);
      expect(controller.duracaoTreinoNotifier.value, 0);
      expect(controller.tempoDescansoNotifier.value, controller.tempoDescansoPadrao);
    });

    test('duracaoTreinoNotifier e tempoDescansoNotifier devem sincronizar valores sem rebuild geral', () {
      expect(controller.tempoDescansoNotifier.value, 90);

      controller.atualizarTempoDescanso(120);
      expect(controller.tempoDescansoNotifier.value, 120);

      controller.iniciarTimer();
      expect(controller.tempoDescansoNotifier.value, 120);

      controller.pausarTimer();
      expect(controller.tempoDescansoNotifier.value, closeTo(120, 2));

      controller.reiniciarTimer();
      expect(controller.tempoDescansoNotifier.value, 120);

      controller.iniciarTreinoSeNecessario();
      expect(controller.isTreinoEmAndamento, isTrue);
      expect(controller.duracaoTreinoNotifier.value, isNonNegative);
    });
  });
}
