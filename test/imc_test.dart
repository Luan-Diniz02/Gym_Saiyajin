import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/controllers/progresso_controller.dart';
import 'package:gym_saiyajin/repositories/treino_repository.dart';
import 'package:gym_saiyajin/services/preferences_service.dart';

class FakeTreinoRepository extends Fake implements TreinoRepository {
  @override
  Future<List<Map<String, String>>> buscarExerciciosUnicosRegistrados() async => [];
}

class FakePreferencesService extends Fake implements PreferencesService {
  @override
  Future<double?> lerDouble(String key) async => null;
  @override
  Future<int?> lerInt(String key) async => null;
  @override
  Future<String?> lerString(String key) async => null;
  @override
  Future<void> salvarDouble(String key, double valor) async {}
  @override
  Future<void> salvarInt(String key, int valor) async {}
  @override
  @override
  Future<void> salvarString(String key, String valor) async {}
  @override
  Future<void> remover(String key) async {}
}

void main() {
  group('ProgressoController - Classificação de IMC (OMS)', () {
    late ProgressoController controller;

    setUp(() {
      controller = ProgressoController(
        repository: FakeTreinoRepository(),
        preferencesService: FakePreferencesService(),
      );
    });

    test('Deve classificar como ABAIXO DO PESO quando IMC < 18.5', () {
      controller.atualizarMedidas(peso: 50.0, altura: 1.75); // IMC ~ 16.3
      expect(controller.classificacaoImc, equals('ABAIXO DO PESO'));
    });

    test('Deve classificar como PESO NORMAL quando 18.5 <= IMC < 25.0', () {
      controller.atualizarMedidas(peso: 70.0, altura: 1.75); // IMC ~ 22.86
      expect(controller.classificacaoImc, equals('PESO NORMAL'));
    });

    test('Deve classificar como SOBREPESO quando 25.0 <= IMC < 30.0', () {
      controller.atualizarMedidas(peso: 85.0, altura: 1.75); // IMC ~ 27.76
      expect(controller.classificacaoImc, equals('SOBREPESO'));
    });

    test('Deve classificar como OBESIDADE GRAU I quando 30.0 <= IMC < 35.0', () {
      controller.atualizarMedidas(peso: 95.0, altura: 1.75); // IMC ~ 31.02
      expect(controller.classificacaoImc, equals('OBESIDADE GRAU I'));
    });

    test('Deve classificar como OBESIDADE GRAU II quando 35.0 <= IMC < 40.0', () {
      controller.atualizarMedidas(peso: 110.0, altura: 1.75); // IMC ~ 35.92
      expect(controller.classificacaoImc, equals('OBESIDADE GRAU II'));
    });

    test('Deve classificar como OBESIDADE GRAU III quando IMC >= 40.0', () {
      controller.atualizarMedidas(peso: 130.0, altura: 1.75); // IMC ~ 42.45
      expect(controller.classificacaoImc, equals('OBESIDADE GRAU III'));
    });
  });

  group('ProgressoController - Composição Corporal e Gordura (% BF)', () {
    late ProgressoController controller;

    setUp(() {
      controller = ProgressoController(
        repository: FakeTreinoRepository(),
        preferencesService: FakePreferencesService(),
      );
    });

    test('Sem percentual de gordura informado, deve retornar null', () {
      expect(controller.percentualGordura, isNull);
      expect(controller.classificacaoGordura, isNull);
    });

    test('Deve classificar corretamente as faixas esportivas de BF %', () {
      controller.atualizarMedidas(peso: 75.0, altura: 1.75, percentualGordura: 8.5);
      expect(controller.percentualGordura, 8.5);
      expect(controller.classificacaoGordura, 'MUITO DEFINIDO ⚡');

      controller.atualizarMedidas(peso: 75.0, altura: 1.75, percentualGordura: 12.0);
      expect(controller.classificacaoGordura, 'FÍSICO ATLÉTICO 💪');

      controller.atualizarMedidas(peso: 75.0, altura: 1.75, percentualGordura: 18.0);
      expect(controller.classificacaoGordura, 'MODERADO / EM FORMA');

      controller.atualizarMedidas(peso: 75.0, altura: 1.75, percentualGordura: 22.0);
      expect(controller.classificacaoGordura, 'ELEVADO');

      controller.atualizarMedidas(peso: 75.0, altura: 1.75, percentualGordura: 28.0);
      expect(controller.classificacaoGordura, 'ALTO');
    });
  });
}
