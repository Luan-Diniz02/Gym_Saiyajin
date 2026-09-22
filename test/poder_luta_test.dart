import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/models/exercicio.dart';
import 'package:gym_saiyajin/models/poder_luta.dart';
import 'package:gym_saiyajin/models/recorde_pessoal.dart';
import 'package:gym_saiyajin/models/serie.dart';
import 'package:gym_saiyajin/models/sessao_treino.dart';

void main() {
  group('PoderLuta - Cálculo Híbrido e Patamares Saiyajin', () {
    test('Estado inicial com dados vazios deve retornar Poder Zero e Classe Baixa', () {
      final poder = PoderLuta.calcular(recordes: [], historico: []);

      expect(poder.poderTotal, 0);
      expect(poder.forcaBase, 0);
      expect(poder.bagagemBatalha, 0);
      expect(poder.bonusPRs, 0);
      expect(poder.transformacao, TransformacaoSaiyajin.classeBaixa);
      expect(poder.progressoProxima, 0.0);
      expect(poder.pontosFaltantes, 1000);
      expect(poder.maiores1RMPorGrupo, isEmpty);
    });

    test('Deve consolidar apenas o maior 1RM por grupo muscular para a Força Base', () {
      final recordes = [
        const RecordePessoal(
          exercicioNome: 'Supino Reto',
          grupo: 'PEITO',
          cargaMaxima: 100,
          repsCargaMaxima: 1,
          umRepMaxEstimado: 100.0,
          peso1RM: 100,
          reps1RM: 1,
        ),
        const RecordePessoal(
          exercicioNome: 'Crucifixo',
          grupo: 'PEITO',
          cargaMaxima: 40,
          repsCargaMaxima: 10,
          umRepMaxEstimado: 53.3,
          peso1RM: 40,
          reps1RM: 10,
        ),
        const RecordePessoal(
          exercicioNome: 'Agachamento Livre',
          grupo: 'PERNAS',
          cargaMaxima: 150,
          repsCargaMaxima: 1,
          umRepMaxEstimado: 150.0,
          peso1RM: 150,
          reps1RM: 1,
        ),
      ];

      final poder = PoderLuta.calcular(recordes: recordes, historico: []);

      // PEITO: maior 1RM = 100.0
      // PERNAS: maior 1RM = 150.0
      // Soma 1RMs = 250.0 -> Forca Base = 250.0 * 10 = 2500
      expect(poder.forcaBase, 2500);
      expect(poder.maiores1RMPorGrupo['PEITO'], 100.0);
      expect(poder.maiores1RMPorGrupo['PERNAS'], 150.0);

      // Bônus de 3 PRs = 3 * 150 = 450
      expect(poder.bonusPRs, 450);

      // Poder total = 2500 + 0 + 450 = 2950
      expect(poder.poderTotal, 2950);
      expect(poder.transformacao, TransformacaoSaiyajin.guerreiroZ);
    });

    test('Deve converter o volume histórico de treinos em Bagagem de Batalha (Volume / 100)', () {
      final sessoes = [
        SessaoTreino(
          duracaoSegundos: 3600,
          exerciciosConcluidosHoje: [
            Exercicio(
              nome: 'Leg Press',
              grupo: 'PERNAS',
              seriesDetalhes: [
                Serie(peso: 200, reps: 10, concluida: true), // 2000 kg
                Serie(peso: 200, reps: 10, concluida: true), // 2000 kg
                Serie(peso: 150, reps: 10, concluida: false), // Desconsiderada por não concluída
              ],
            ),
          ],
        ),
        SessaoTreino(
          duracaoSegundos: 3600,
          exerciciosConcluidosHoje: [
            Exercicio(
              nome: 'Supino',
              grupo: 'PEITO',
              seriesDetalhes: [
                Serie(peso: 100, reps: 10, concluida: true), // 1000 kg
              ],
            ),
          ],
        ),
      ];

      // Volume total concluído = 2000 + 2000 + 1000 = 5000 kg
      // Bagagem de batalha = 5000 / 100 = 50 Ki
      final poder = PoderLuta.calcular(recordes: [], historico: sessoes);

      expect(poder.bagagemBatalha, 50);
      expect(poder.poderTotal, 50);
      expect(poder.transformacao, TransformacaoSaiyajin.classeBaixa);
      expect(poder.pontosFaltantes, 950);
      expect(poder.progressoProxima, 0.05); // 50 / 1000
    });

    test('Deve enquadrar corretamente em todos os patamares de transformação', () {
      expect(TransformacaoSaiyajin.obterPorPoder(500), TransformacaoSaiyajin.classeBaixa);
      expect(TransformacaoSaiyajin.obterPorPoder(1000), TransformacaoSaiyajin.guerreiroZ);
      expect(TransformacaoSaiyajin.obterPorPoder(3999), TransformacaoSaiyajin.guerreiroZ);
      expect(TransformacaoSaiyajin.obterPorPoder(4000), TransformacaoSaiyajin.eliteSaiyajin);
      expect(TransformacaoSaiyajin.obterPorPoder(7999), TransformacaoSaiyajin.eliteSaiyajin);
      expect(TransformacaoSaiyajin.obterPorPoder(8000), TransformacaoSaiyajin.superSaiyajin1);
      expect(TransformacaoSaiyajin.obterPorPoder(14999), TransformacaoSaiyajin.superSaiyajin1);
      expect(TransformacaoSaiyajin.obterPorPoder(15000), TransformacaoSaiyajin.superSaiyajin2);
      expect(TransformacaoSaiyajin.obterPorPoder(29999), TransformacaoSaiyajin.superSaiyajin2);
      expect(TransformacaoSaiyajin.obterPorPoder(30000), TransformacaoSaiyajin.superSaiyajin3);
      expect(TransformacaoSaiyajin.obterPorPoder(49999), TransformacaoSaiyajin.superSaiyajin3);
      expect(TransformacaoSaiyajin.obterPorPoder(50000), TransformacaoSaiyajin.instintoSuperior);
      expect(TransformacaoSaiyajin.obterPorPoder(120000), TransformacaoSaiyajin.instintoSuperior);
    });

    test('Instinto Superior deve ter progresso 100% e 0 pontos faltantes', () {
      final transformacao = TransformacaoSaiyajin.instintoSuperior;
      expect(transformacao.proxima, isNull);

      final recordeSupremo = [
        const RecordePessoal(
          exercicioNome: 'Agachamento dos Deuses',
          grupo: 'PERNAS',
          cargaMaxima: 5500,
          repsCargaMaxima: 1,
          umRepMaxEstimado: 5500.0,
          peso1RM: 5500,
          reps1RM: 1,
        ),
      ];

      final poder = PoderLuta.calcular(recordes: recordeSupremo, historico: []);
      expect(poder.poderTotal, greaterThanOrEqualTo(50000));
      expect(poder.transformacao, TransformacaoSaiyajin.instintoSuperior);
      expect(poder.progressoProxima, 1.0);
      expect(poder.pontosFaltantes, 0);
    });

    test('formatarPoder deve pontuar milhares corretamente', () {
      expect(PoderLuta.formatarPoder(0), '0');
      expect(PoderLuta.formatarPoder(950), '950');
      expect(PoderLuta.formatarPoder(1000), '1.000');
      expect(PoderLuta.formatarPoder(8450), '8.450');
      expect(PoderLuta.formatarPoder(50230), '50.230');
      expect(PoderLuta.formatarPoder(1250000), '1.250.000');
    });
  });
}
