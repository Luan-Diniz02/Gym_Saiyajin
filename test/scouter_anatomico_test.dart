import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/controllers/progresso_controller.dart';
import 'package:gym_saiyajin/models/exercicio.dart';
import 'package:gym_saiyajin/models/poder_luta.dart';
import 'package:gym_saiyajin/models/serie.dart';
import 'package:gym_saiyajin/models/sessao_treino.dart';
import 'package:gym_saiyajin/repositories/treino_repository.dart';
import 'package:gym_saiyajin/services/preferences_service.dart';
import 'package:gym_saiyajin/widgets/scouter_anatomico_widget.dart';
import 'package:muscle_mapper/muscle_mapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeTreinoRepository extends TreinoRepository {}

void main() {
  late ProgressoController controller;
  final dataReferencia = DateTime(2026, 10, 27, 12, 0);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    controller = ProgressoController(
      repository: _FakeTreinoRepository(),
      preferencesService: PreferencesService(),
    );
  });

  group('ProgressoController - Telemetria do Mapa de Calor Muscular', () {
    test('normalizarGrupoMuscular mapeia sinônimos para os 7 grupos canônicos', () {
      expect(ProgressoController.normalizarGrupoMuscular('Peitoral'), 'PEITO');
      expect(ProgressoController.normalizarGrupoMuscular('Dorsal'), 'COSTAS');
      expect(ProgressoController.normalizarGrupoMuscular('Quadríceps'), 'PERNAS');
      expect(ProgressoController.normalizarGrupoMuscular('Glúteos'), 'PERNAS');
      expect(ProgressoController.normalizarGrupoMuscular('Deltoides'), 'OMBROS');
      expect(ProgressoController.normalizarGrupoMuscular('Biceps'), 'BÍCEPS');
      expect(ProgressoController.normalizarGrupoMuscular('Triceps'), 'TRÍCEPS');
      expect(ProgressoController.normalizarGrupoMuscular('Core'), 'ABDÔMEN');
    });

    test(
      'calcularTelemetriaMuscular contabiliza séries de trabalho (normal/drop/falha) e ignora aquecimento (warmup)',
      () {
        final sessaoRecente = SessaoTreino(
          nomeTreino: 'Push Saiyajin',
          data: dataReferencia.subtract(const Duration(days: 2)),
          duracaoSegundos: 3600,
          exerciciosConcluidosHoje: [
            Exercicio(
              nome: 'Supino Reto',
              grupo: 'Peito',
              seriesDetalhes: [
                // Aquecimento: deve ser ignorado!
                Serie(
                  peso: 40,
                  reps: 15,
                  concluida: true,
                  tipo: TipoSerie.warmup.codigo,
                ),
                // 6 séries válidas (Zona Ideal em 7 dias: 6 a 12 séries)
                Serie(peso: 80, reps: 10, concluida: true, tipo: TipoSerie.normal.codigo),
                Serie(peso: 80, reps: 10, concluida: true, tipo: TipoSerie.normal.codigo),
                Serie(peso: 80, reps: 10, concluida: true, tipo: TipoSerie.normal.codigo),
                Serie(peso: 80, reps: 10, concluida: true, tipo: TipoSerie.normal.codigo),
                Serie(peso: 70, reps: 10, concluida: true, tipo: TipoSerie.dropset.codigo),
                Serie(peso: 70, reps: 8, concluida: true, tipo: TipoSerie.falha.codigo),
                // Série não concluída: ignorada
                Serie(peso: 90, reps: 8, concluida: false, tipo: TipoSerie.normal.codigo),
              ],
            ),
            Exercicio(
              nome: 'Tríceps Pulley',
              grupo: 'Tríceps',
              seriesDetalhes: [
                // 3 séries válidas (Manutenção / Ativado em 7 dias: 1 a 5 séries)
                Serie(peso: 30, reps: 12, concluida: true),
                Serie(peso: 30, reps: 12, concluida: true),
                Serie(peso: 30, reps: 12, concluida: true),
              ],
            ),
          ],
        );

        final sessaoMaisAntiga = SessaoTreino(
          nomeTreino: 'Leg Day',
          data: dataReferencia.subtract(const Duration(days: 15)),
          duracaoSegundos: 4000,
          exerciciosConcluidosHoje: [
            Exercicio(
              nome: 'Agachamento Livre',
              grupo: 'Pernas',
              seriesDetalhes: List.generate(
                14,
                (_) => Serie(peso: 100, reps: 10, concluida: true),
              ),
            ),
          ],
        );

        controller.definirHistoricoParaTeste(
          [sessaoRecente, sessaoMaisAntiga],
          poderLuta: const PoderLuta(
            poderTotal: 4500,
            forcaBase: 2400,
            bonusPRs: 300,
            transformacao: TransformacaoSaiyajin.eliteSaiyajin,
            progressoProxima: 0.5,
            pontosFaltantes: 3500,
            maiores1RMPorGrupo: {'PEITO': 106.7, 'PERNAS': 133.3},
          ),
        );

        // Na janela de 7 dias:
        final mapa7d = controller.calcularTelemetriaMuscular(
          dataReferencia: dataReferencia,
        );
        expect(mapa7d['PEITO']!.seriesValidas, 6);
        expect(
          mapa7d['PEITO']!.volumeTotalKg,
          (80 * 10 * 4) + (70 * 10) + (70 * 8), // 3200 + 700 + 560 = 4460
        );
        expect(mapa7d['PEITO']!.nivel, NivelAtivacaoMuscular.ideal);
        expect(mapa7d['PEITO']!.maior1RM, 106.7);

        expect(mapa7d['TRÍCEPS']!.seriesValidas, 3);
        expect(mapa7d['TRÍCEPS']!.nivel, NivelAtivacaoMuscular.manutencao);

        // Pernas foi há 15 dias -> inativo na janela de 7 dias
        expect(mapa7d['PERNAS']!.seriesValidas, 0);
        expect(mapa7d['PERNAS']!.nivel, NivelAtivacaoMuscular.inativo);

        // Pontos fracos na janela de 7 dias
        final pontosFracos = controller.obterPontosFracosMusculares(
          telemetria: mapa7d,
        );
        expect(
          pontosFracos,
          containsAll(['COSTAS', 'PERNAS', 'OMBROS', 'BÍCEPS', 'ABDÔMEN']),
        );
        expect(pontosFracos, isNot(contains('PEITO')));

        // Alternando para 30 dias: Pernas entra na contagem
        controller.mudarPeriodoMapaMuscular(PeriodoMapaMuscular.trintaDias);
        final mapa30d = controller.calcularTelemetriaMuscular(
          dataReferencia: dataReferencia,
        );
        expect(mapa30d['PERNAS']!.seriesValidas, 14);
        expect(mapa30d['PERNAS']!.nivel, NivelAtivacaoMuscular.manutencao);
      },
    );
  });

  group('Integração muscle_mapper e ScouterAnatomicoWidget', () {
    test('mapearMuscleParaGrupoCanonico mapeia feixes do muscle_mapper corretamente', () {
      expect(
        ScouterAnatomicoWidget.mapearMuscleParaGrupoCanonico(Muscle.upperPectoralis),
        'PEITO',
      );
      expect(
        ScouterAnatomicoWidget.mapearMuscleParaGrupoCanonico(Muscle.lats),
        'COSTAS',
      );
      expect(
        ScouterAnatomicoWidget.mapearMuscleParaGrupoCanonico(Muscle.longHeadBicep),
        'BÍCEPS',
      );
      expect(
        ScouterAnatomicoWidget.mapearMuscleParaGrupoCanonico(Muscle.longHeadTriceps),
        'TRÍCEPS',
      );
      expect(
        ScouterAnatomicoWidget.mapearMuscleParaGrupoCanonico(Muscle.rectusFemoris),
        'PERNAS',
      );
      expect(
        ScouterAnatomicoWidget.mapearMuscleParaGrupoCanonico(Muscle.upperAbdominals),
        'ABDÔMEN',
      );
      expect(
        ScouterAnatomicoWidget.mapearMuscleParaGrupoCanonico(Muscle.lateralDeltoid),
        'OMBROS',
      );
      expect(
        ScouterAnatomicoWidget.mapearMuscleParaGrupoCanonico(Muscle.hands),
        isNull,
      );
    });

    testWidgets('renderiza Mapa de Calor Muscular (Opção A), alterna período e inspeciona grupo', (
      tester,
    ) async {
      controller.definirHistoricoParaTeste([
        SessaoTreino(
          nomeTreino: 'Treino Peito Pesado',
          data: DateTime.now().subtract(const Duration(days: 1)),
          duracaoSegundos: 3000,
          exerciciosConcluidosHoje: [
            Exercicio(
              nome: 'Supino Reto',
              grupo: 'Peito',
              seriesDetalhes: List.generate(
                8,
                (_) => Serie(peso: 100, reps: 10, concluida: true),
              ),
            ),
          ],
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ScouterAnatomicoWidget(controller: controller),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('MAPA DE CALOR MUSCULAR'), findsOneWidget);
      expect(find.byKey(const Key('canvas-heatmap-frontal')), findsOneWidget);
      expect(find.byKey(const Key('canvas-heatmap-dorsal')), findsOneWidget);
      expect(find.byType(MuscleMapper), findsNWidgets(2));

      // Seleciona o chip de PEITO
      await tester.tap(find.byKey(const Key('chip-musculo-PEITO')));
      await tester.pump();

      expect(controller.grupoMuscularSelecionado, 'PEITO');
      expect(find.text('8'), findsOneWidget);
      expect(find.text('SÉRIES'), findsOneWidget);
      expect(find.text('ZONA IDEAL'), findsWidgets);

      // Alterna para 30 DIAS
      await tester.tap(find.byKey(const Key('periodo-mapa-30')));
      await tester.pump();

      expect(controller.periodoMapaMuscular, PeriodoMapaMuscular.trintaDias);
    });
  });
}
