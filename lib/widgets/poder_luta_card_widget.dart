import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/progresso_controller.dart';
import '../models/poder_luta.dart';
import '../models/recorde_pessoal.dart';
import '../theme/app_colors.dart';
import 'dragon_ball_icon.dart';
import 'ki_aura_icon.dart';
import 'scouter_icon.dart';

/// Card interativo do Poder de Luta e Patamar de Transformação Saiyajin.
class PoderLutaCardWidget extends StatefulWidget {
  final ProgressoController controller;

  const PoderLutaCardWidget({super.key, required this.controller});

  @override
  State<PoderLutaCardWidget> createState() => _PoderLutaCardWidgetState();
}

class _PoderLutaCardWidgetState extends State<PoderLutaCardWidget> {
  bool _detalhesExpandidos = false;

  @override
  Widget build(BuildContext context) {
    final poder = widget.controller.poderLuta;
    final transformacao = poder.transformacao;
    final proxima = transformacao.proxima;
    final corAura = transformacao.corAura;
    final corSecundaria = transformacao.corSecundaria;
    final isSSJ2 = transformacao == TransformacaoSaiyajin.superSaiyajin2;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: transformacao.gradiente
              .map((c) => c.withValues(alpha: isSSJ2 ? 0.95 : 0.70))
              .toList(),
        ),
        boxShadow: [
          BoxShadow(
            color: transformacao.corBadge.withValues(alpha: isSSJ2 ? 0.35 : 0.20),
            blurRadius: isSSJ2 ? 20 : 16,
            spreadRadius: isSSJ2 ? 2 : 1,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: corAura.withValues(alpha: 0.16),
            blurRadius: 26,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Área Superior Principal (Clicável para expandir)
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _detalhesExpandidos = !_detalhesExpandidos;
                });
              },
              borderRadius: BorderRadius.circular(18.2),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho: Título + Badge de Patente
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            ScouterIcon(
                              size: 22,
                              lensColor: isSSJ2 ? corSecundaria : corAura,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'PODER DE LUTA',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: AppColors.textDimmed,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: transformacao.corBadge.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: transformacao.corBadge.withValues(alpha: 0.65),
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            transformacao.titulo.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: transformacao.corBadge,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Leitura Numérica de Poder
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          PoderLuta.formatarPoder(poder.poderTotal),
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textLight,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Ki',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: transformacao.corBadge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      transformacao.subtituloLore,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textDimmed,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Barra de Progresso da Próxima Transformação
                    if (proxima != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RUMO A ${proxima.titulo.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.textDimmed,
                            ),
                          ),
                          Text(
                            '${(poder.progressoProxima * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: transformacao.corBadge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 8,
                          color: AppColors.cardBorder,
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: poder.progressoProxima,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    corAura,
                                    proxima.corAura,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Faltam ${PoderLuta.formatarPoder(poder.pontosFaltantes)} Ki para a próxima evolução',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textDimmed,
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: corAura.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: corAura.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.stars_rounded, size: 16, color: corAura),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Patamar supremo conquistado! Seu poder é lendário.',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),
                    // Botão de Alternância de Detalhes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _detalhesExpandidos
                              ? 'Ocultar Origem do Ki'
                              : 'Ver Origem do Ki',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: transformacao.corBadge,
                          ),
                        ),
                        Icon(
                          _detalhesExpandidos
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: transformacao.corBadge,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Seção Expansível com o Detalhamento dos 3 Pilares
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _detalhesExpandidos
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  const Text(
                    'COMPOSIÇÃO DO PODER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: AppColors.textDimmed,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Pilar 1: Força Base
                  _buildLinhaPilar(
                    icone: Icons.fitness_center_rounded,
                    titulo: 'Força Base (1RM Grupos)',
                    subtitulo: 'Soma dos maiores 1RM por grupo × 10',
                    valor: '${PoderLuta.formatarPoder(poder.forcaBase)} Ki',
                    cor: AppColors.primary,
                  ),
                  const SizedBox(height: 8),

                  // Pilar 2: Vigor Saiyajin
                  _buildLinhaPilar(
                    iconeWidget: KiAuraIcon(
                      size: 16,
                      primaryColor: corAura,
                      secondaryColor: corSecundaria,
                      showGlow: false,
                      showSparks: false,
                    ),
                    titulo: 'Vigor Saiyajin (Volume)',
                    subtitulo: 'Volume histórico de repetições / 100',
                    valor: '${PoderLuta.formatarPoder(poder.vigorSaiyajin)} Ki',
                    cor: corAura,
                  ),
                  const SizedBox(height: 8),

                  // Pilar 3: Bônus de PRs
                  _buildLinhaPilar(
                    iconeWidget: const DragonBallIcon(size: 16, stars: 4),
                    titulo: 'Limites Superados (PRs)',
                    subtitulo: '${widget.controller.totalRecordes} recordes registrados × 150',
                    valor: '${PoderLuta.formatarPoder(poder.bonusPRs)} Ki',
                    cor: AppColors.accent,
                  ),

                  // Chips dos 1RMs considerados
                  if (poder.maiores1RMPorGrupo.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'MAIORES 1RMs CONSIDERADOS:',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.textDimmed,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: poder.maiores1RMPorGrupo.entries.map((e) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Text(
                            '${e.key}: ${RecordePessoal.formatarPeso(e.value)} kg',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textLight,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildLinhaPilar({
    IconData? icone,
    Widget? iconeWidget,
    required String titulo,
    required String subtitulo,
    required String valor,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: iconeWidget ?? Icon(icone, size: 16, color: cor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textLight,
                  ),
                ),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textDimmed,
                  ),
                ),
              ],
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}
