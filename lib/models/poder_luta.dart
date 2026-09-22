import 'package:flutter/material.dart';

import 'recorde_pessoal.dart';
import 'sessao_treino.dart';

/// Patamares canônicos de evolução e transformação Saiyajin.
enum TransformacaoSaiyajin {
  classeBaixa(
    titulo: 'Classe Baixa',
    subtituloLore: 'Início da jornada do guerreiro',
    poderMinimo: 0,
    poderMaximo: 1000,
    corAura: Color(0xFF9E9E9E),
  ),
  guerreiroZ(
    titulo: 'Guerreiro Z',
    subtituloLore: 'Defensor em treinamento constante',
    poderMinimo: 1000,
    poderMaximo: 4000,
    corAura: Color(0xFF4FC3F7),
  ),
  eliteSaiyajin(
    titulo: 'Elite Saiyajin',
    subtituloLore: 'Aura vermelha de poder concentrado',
    poderMinimo: 4000,
    poderMaximo: 8000,
    corAura: Color(0xFFFF5252),
  ),
  superSaiyajin1(
    titulo: 'Super Saiyajin ⚡',
    subtituloLore: 'O lendário guerreiro dourado despertou',
    poderMinimo: 8000,
    poderMaximo: 15000,
    corAura: Color(0xFFFFD700),
  ),
  superSaiyajin2(
    titulo: 'Super Saiyajin 2 ⚡⚡',
    subtituloLore: 'Faíscas elétricas de fúria e intensidade',
    poderMinimo: 15000,
    poderMaximo: 30000,
    corAura: Color(0xFFFFC107),
  ),
  superSaiyajin3(
    titulo: 'Super Saiyajin 3 ⚡🔥',
    subtituloLore: 'Potencial cósmico levado ao extremo',
    poderMinimo: 30000,
    poderMaximo: 50000,
    corAura: Color(0xFFFF9800),
  ),
  instintoSuperior(
    titulo: 'Instinto Superior 🌌',
    subtituloLore: 'Movimento fluído além de todos os limites',
    poderMinimo: 50000,
    poderMaximo: 100000,
    corAura: Color(0xFFE0E0E0),
  );

  final String titulo;
  final String subtituloLore;
  final int poderMinimo;
  final int poderMaximo;
  final Color corAura;

  const TransformacaoSaiyajin({
    required this.titulo,
    required this.subtituloLore,
    required this.poderMinimo,
    required this.poderMaximo,
    required this.corAura,
  });

  /// Determina a transformação correspondente a partir do poder de luta numérico.
  static TransformacaoSaiyajin obterPorPoder(int poder) {
    if (poder >= 50000) return TransformacaoSaiyajin.instintoSuperior;
    if (poder >= 30000) return TransformacaoSaiyajin.superSaiyajin3;
    if (poder >= 15000) return TransformacaoSaiyajin.superSaiyajin2;
    if (poder >= 8000) return TransformacaoSaiyajin.superSaiyajin1;
    if (poder >= 4000) return TransformacaoSaiyajin.eliteSaiyajin;
    if (poder >= 1000) return TransformacaoSaiyajin.guerreiroZ;
    return TransformacaoSaiyajin.classeBaixa;
  }

  /// Retorna a próxima transformação na hierarquia, ou null se já estiver no ápice.
  TransformacaoSaiyajin? get proxima {
    final indexAtual = index;
    if (indexAtual < TransformacaoSaiyajin.values.length - 1) {
      return TransformacaoSaiyajin.values[indexAtual + 1];
    }
    return null;
  }
}

/// Entidade de domínio que calcula e consolida o Poder de Luta (Ki) do usuário.
class PoderLuta {
  final int poderTotal;
  final int forcaBase;
  final int bagagemBatalha;
  final int bonusPRs;
  final TransformacaoSaiyajin transformacao;
  final double progressoProxima;
  final int pontosFaltantes;
  final Map<String, double> maiores1RMPorGrupo;

  const PoderLuta({
    required this.poderTotal,
    required this.forcaBase,
    required this.bagagemBatalha,
    required this.bonusPRs,
    required this.transformacao,
    required this.progressoProxima,
    required this.pontosFaltantes,
    required this.maiores1RMPorGrupo,
  });

  factory PoderLuta.zero() {
    return const PoderLuta(
      poderTotal: 0,
      forcaBase: 0,
      bagagemBatalha: 0,
      bonusPRs: 0,
      transformacao: TransformacaoSaiyajin.classeBaixa,
      progressoProxima: 0.0,
      pontosFaltantes: 1000,
      maiores1RMPorGrupo: {},
    );
  }

  /// Formata números inteiros com separadores de milhar no padrão brasileiro (ex: 8.450).
  static String formatarPoder(int valor) {
    final str = valor.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0 && str[i - 1] != '-') {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  /// Calcula o Poder de Luta usando a fórmula híbrida:
  /// - Força Base: Soma dos maiores 1RM estimados de cada grupo muscular x 10
  /// - Bagagem de Batalha: Volume total histórico / 100
  /// - Bônus PRs: Quantidade de recordes pessoais x 150
  static PoderLuta calcular({
    required List<RecordePessoal> recordes,
    required List<SessaoTreino> historico,
  }) {
    // 1. Agrupar os maiores 1RM por grupo muscular
    final Map<String, double> max1RMPorGrupo = {};
    for (final pr in recordes) {
      final grupo = pr.grupo.trim().toUpperCase();
      final grupoNormalizado = grupo.isEmpty ? 'OUTROS' : grupo;
      final umRM = pr.umRepMaxEstimado > 0 ? pr.umRepMaxEstimado : pr.peso1RM;

      if (!max1RMPorGrupo.containsKey(grupoNormalizado) ||
          umRM > max1RMPorGrupo[grupoNormalizado]!) {
        max1RMPorGrupo[grupoNormalizado] = umRM;
      }
    }

    double soma1RMs = 0.0;
    max1RMPorGrupo.forEach((_, v) => soma1RMs += v);
    final int forcaBaseCalculada = (soma1RMs * 10).round();

    // 2. Calcular o Volume Total Histórico (kg levantados)
    double volumeAcumulado = 0.0;
    for (final sessao in historico) {
      for (final ex in sessao.exerciciosConcluidosHoje) {
        for (final serie in ex.seriesDetalhes) {
          if (serie.concluida && (serie.peso ?? 0) > 0 && (serie.reps ?? 0) > 0) {
            volumeAcumulado += (serie.peso! * serie.reps!);
          }
        }
      }
    }
    final int bagagemCalculada = (volumeAcumulado / 100.0).round();

    // 3. Bônus por Recordes Pessoais batidos
    final int bonusCalculado = recordes.length * 150;

    final int poderTotalCalculado =
        forcaBaseCalculada + bagagemCalculada + bonusCalculado;

    // 4. Determinar patamar e progresso
    final transformacao =
        TransformacaoSaiyajin.obterPorPoder(poderTotalCalculado);

    double progresso = 0.0;
    int faltantes = 0;

    if (transformacao == TransformacaoSaiyajin.instintoSuperior) {
      progresso = 1.0;
      faltantes = 0;
    } else {
      final int baseFaixa = transformacao.poderMinimo;
      final int topoFaixa = transformacao.poderMaximo;
      final int deltaFaixa = topoFaixa - baseFaixa;

      if (deltaFaixa > 0) {
        final pontosNaFaixa = poderTotalCalculado - baseFaixa;
        progresso = (pontosNaFaixa / deltaFaixa).clamp(0.0, 1.0);
        faltantes = (topoFaixa - poderTotalCalculado).clamp(0, topoFaixa);
      }
    }

    return PoderLuta(
      poderTotal: poderTotalCalculado,
      forcaBase: forcaBaseCalculada,
      bagagemBatalha: bagagemCalculada,
      bonusPRs: bonusCalculado,
      transformacao: transformacao,
      progressoProxima: progresso,
      pontosFaltantes: faltantes,
      maiores1RMPorGrupo: max1RMPorGrupo,
    );
  }
}
