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
import 'package:gym_saiyajin/widgets/serie_row_widget.dart';

class FakeTreinoRepository extends Fake implements TreinoRepository {
  @override
  Future<List<Map<String, String>>> buscarExerciciosUnicosRegistrados() async => [];
  @override
  Future<List<Serie>> buscarUltimasSeriesExercicio(String nomeExercicio) async => [];
  @override
  Future<RecordePessoal?> buscarRecordeHistoricoExercicio(String nomeExercicio) async => null;
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
}
