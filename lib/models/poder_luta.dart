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
    corSecundaria: Color(0xFF616161),
    corBadge: Color(0xFF9E9E9E),
    gradiente: [Color(0xFFBDBDBD), Color(0xFF757575)],
  ),
  guerreiroZ(
    titulo: 'Guerreiro Z',
    subtituloLore: 'Defensor em treinamento constante',
    poderMinimo: 1000,
    poderMaximo: 4000,
    corAura: Color(0xFF4FC3F7),
    corSecundaria: Color(0xFF0288D1),
    corBadge: Color(0xFF4FC3F7),
    gradiente: [Color(0xFF81D4FA), Color(0xFF0288D1)],
  ),
  eliteSaiyajin(
    titulo: 'Elite Saiyajin',
    subtituloLore: 'Aura vermelha de poder concentrado',
    poderMinimo: 4000,
    poderMaximo: 8000,
    corAura: Color(0xFFFF5252),
    corSecundaria: Color(0xFFD50000),
    corBadge: Color(0xFFFF5252),
    gradiente: [Color(0xFFFF5252), Color(0xFFD50000), Color(0xFFFF1744)],
  ),
  superSaiyajin1(
    titulo: 'Super Saiyajin',
    subtituloLore: 'O lendário guerreiro dourado despertou',
    poderMinimo: 8000,
    poderMaximo: 15000,
    corAura: Color(0xFFFFD700),
    corSecundaria: Color(0xFFFFA000),
    corBadge: Color(0xFFFFD700),
    gradiente: [Color(0xFFFFD700), Color(0xFFFFC107), Color(0xFFFFA000)],
  ),
  superSaiyajin2(
    titulo: 'Super Saiyajin 2',
    subtituloLore: 'A fúria que rompeu a barreira do Super Saiyajin',
    poderMinimo: 15000,
    poderMaximo: 30000,
    corAura: Color(0xFFFF9E00),
    corSecundaria: Color(0xFF00E5FF),
    corBadge: Color(0xFFFF9E00),
    gradiente: [Color(0xFFFFB300), Color(0xFFFF9E00), Color(0xFFFF8F00)],
  ),
  superSaiyajin3(
    titulo: 'Super Saiyajin 3',
    subtituloLore: 'A força colossal que faz o universo estremecer',
    poderMinimo: 30000,
    poderMaximo: 50000,
    corAura: Color(0xFFFF6D00),
    corSecundaria: Color(0xFFFFD600),
    corBadge: Color(0xFFFF6D00),
    gradiente: [Color(0xFFFF6D00), Color(0xFFFF3D00), Color(0xFFFFAB00)],
  ),
  instintoSuperior(
    titulo: 'Instinto Superior',
    subtituloLore: 'O estado divino onde o corpo age por puro instinto',
    poderMinimo: 50000,
    poderMaximo: 100000,
    corAura: Color(0xFFFFFFFF),
    corSecundaria: Color(0xFF80D8FF),
    corBadge: Color(0xFFFFFFFF),
    gradiente: [Color(0xFFFFFFFF), Color(0xFF80D8FF), Color(0xFFB0BEC5)],
  );

  final String titulo;
  final String subtituloLore;
  final int poderMinimo;
  final int poderMaximo;
  final Color corAura;
  final Color corSecundaria;
  final Color corBadge;
  final List<Color> gradiente;

  const TransformacaoSaiyajin({
    required this.titulo,
    required this.subtituloLore,
    required this.poderMinimo,
    required this.poderMaximo,
    required this.corAura,
    required this.corSecundaria,
    required this.corBadge,
    required this.gradiente,
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

  /// Cor da lente holográfica do visor Scouter para esta transformação.
  Color get corLenteScouter {
    switch (this) {
      case TransformacaoSaiyajin.superSaiyajin2:
        return const Color(0xFF00E5FF); // Ciano bioelétrico
      case TransformacaoSaiyajin.instintoSuperior:
        return const Color(0xFF80D8FF); // Azul celeste divino
      default:
        return corAura;
    }
  }
}

/// Entidade de domínio que calcula e consolida o Poder de Luta (Ki) do usuário.
class PoderLuta {
  final int poderTotal;
  final int forcaBase;
  final int vigorSaiyajin;
  int get bagagemBatalha => vigorSaiyajin;
  final int bonusPRs;
  final TransformacaoSaiyajin transformacao;
  final double progressoProxima;
  final int pontosFaltantes;
  final Map<String, double> maiores1RMPorGrupo;

  const PoderLuta({
    required this.poderTotal,
    required this.forcaBase,
    int? vigorSaiyajin,
    int? bagagemBatalha,
    required this.bonusPRs,
    required this.transformacao,
    required this.progressoProxima,
    required this.pontosFaltantes,
    required this.maiores1RMPorGrupo,
  }) : vigorSaiyajin = vigorSaiyajin ?? bagagemBatalha ?? 0;

  factory PoderLuta.zero() {
    return const PoderLuta(
      poderTotal: 0,
      forcaBase: 0,
      vigorSaiyajin: 0,
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
  /// - Vigor Saiyajin (Volume): Volume total histórico / 100
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

    // 2. Calcular o Vigor Saiyajin através do Volume Total Histórico (kg levantados)
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
    final int vigorCalculado = (volumeAcumulado / 100.0).round();

    // 3. Bônus por Recordes Pessoais batidos
    final int bonusCalculado = recordes.length * 150;

    final int poderTotalCalculado =
        forcaBaseCalculada + vigorCalculado + bonusCalculado;

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
      vigorSaiyajin: vigorCalculado,
      bonusPRs: bonusCalculado,
      transformacao: transformacao,
      progressoProxima: progresso,
      pontosFaltantes: faltantes,
      maiores1RMPorGrupo: max1RMPorGrupo,
    );
  }
}
