import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/controllers/treino_controller.dart';
import 'package:gym_saiyajin/repositories/treino_repository.dart';
import 'package:gym_saiyajin/services/notification_service.dart';
import 'package:gym_saiyajin/services/preferences_service.dart';

class FakeTreinoRepository extends Fake implements TreinoRepository {
  @override
  Future<List<Map<String, String>>> buscarExerciciosUnicosRegistrados() async => [];
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

  group('TreinoController - Gerenciamento de Séries', () {
    late TreinoController controller;

    setUp(() {
      controller = TreinoController(
        repository: FakeTreinoRepository(),
        preferencesService: FakePreferencesService(),
        notificationService: FakeNotificationService(),
      );
    });

    test('Deve permitir adicionar e remover séries individuais mantendo ao menos uma', () {
      controller.iniciarNovoExercicio('Supino Reto', 'PEITO');
      expect(controller.exercicioAtual?.seriesDetalhes.length, equals(1));

      // Adicionar mais duas séries
      controller.adicionarSerie();
      controller.adicionarSerie();
      expect(controller.exercicioAtual?.seriesDetalhes.length, equals(3));

      // Remover a série do meio (índice 1)
      controller.removerSerie(1);
      expect(controller.exercicioAtual?.seriesDetalhes.length, equals(2));

      // Remover outra série
      controller.removerSerie(0);
      expect(controller.exercicioAtual?.seriesDetalhes.length, equals(1));

      // Tentar remover a última série restante - não deve remover pois deve haver ao menos 1
      controller.removerSerie(0);
      expect(controller.exercicioAtual?.seriesDetalhes.length, equals(1));
    });
  });
}
