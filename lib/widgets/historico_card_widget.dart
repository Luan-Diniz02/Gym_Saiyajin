import 'package:flutter/material.dart';

import '../models/exercicio.dart';
import '../models/serie.dart';
import '../theme/app_colors.dart';
import 'dragon_ball_icon.dart';
import 'exercicio_midia_widget.dart';
import 'kinto_un_icon.dart';

class HistoricoCardWidget extends StatefulWidget {
  final Exercicio exercicio;
  final int? indiceSeriePR;

  const HistoricoCardWidget({
    super.key,
    required this.exercicio,
    this.indiceSeriePR,
  });

  @override
  State<HistoricoCardWidget> createState() => _HistoricoCardWidgetState();
}

class _HistoricoCardWidgetState extends State<HistoricoCardWidget> {
  bool _isExpanded = false;

  bool get _temPR => widget.indiceSeriePR != null;

  Color _corPorTipo(TipoSerie tipo) {
    switch (tipo) {
      case TipoSerie.normal:
        return AppColors.accent;
      case TipoSerie.warmup:
        return const Color(0xFFFFD700);
      case TipoSerie.dropset:
        return AppColors.primary;
      case TipoSerie.falha:
        return AppColors.danger;
    }
  }

  Widget _buildBadgePR({Key? badgeKey}) {
    return Container(
      key: badgeKey,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9800).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFFFB300).withValues(alpha: 0.5),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DragonBallIcon(size: 10, stars: 1),
          SizedBox(width: 4),
          Text(
            'PR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFB300),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicadorCircularSerie(Serie serie, int numeroSerieTrabalho) {
    final tipo = serie.tipoEnum;
    final cor = _corPorTipo(tipo);

    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(color: cor, width: 1.5),
      ),
      alignment: Alignment.center,
      child: tipo == TipoSerie.warmup
          ? const KintoUnIcon(size: 14, showGlow: false, showTrail: false)
          : Text(
              tipo == TipoSerie.normal ? '$numeroSerieTrabalho' : tipo.sigla,
              style: TextStyle(
                color: cor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }

  Widget _buildTagRir(Serie serie) {
    if (serie.rir == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        serie.rirLabel!,
        style: const TextStyle(
          color: AppColors.textDimmed,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercicio = widget.exercicio;
    final List<Serie> detalhes = exercicio.seriesDetalhes;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _temPR
              ? const Color(0xFFFFB300).withValues(alpha: 0.35)
              : AppColors.cardBorder,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textDimmed,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
          },
          leading: ExercicioThumbnailWidget(
            nomeExercicio: exercicio.nome,
            grupo: exercicio.grupo,
            size: 44,
            borderRadius: 11,
            abrirModalAoTocar: true,
            exibirIndicadorGif: true,
          ),
          title: Text(
            exercicio.nome,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    exercicio.grupo,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${detalhes.length} SÉRIES',
                  style: const TextStyle(
                    color: AppColors.textDimmed,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Alternativa A: exibe o badge PR no cabeçalho apenas quando recolhido
                if (_temPR && !_isExpanded)
                  _buildBadgePR(
                    badgeKey: Key('badge-pr-exercicio-${exercicio.nome}'),
                  ),
              ],
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: detalhes.asMap().entries.map((entry) {
                  final Serie serieData = entry.value;
                  final bool isSeriePR = widget.indiceSeriePR == entry.key;
                  final int numTrabalho = Serie.calcularNumeroSerieTrabalho(
                    detalhes,
                    entry.key,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildIndicadorCircularSerie(
                              serieData,
                              numTrabalho,
                            ),
                            Text(
                              serieData.obterRotuloHistorico(numTrabalho),
                              style: TextStyle(
                                color: isSeriePR
                                    ? AppColors.textLight
                                    : AppColors.textDimmed,
                                fontWeight: isSeriePR
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                            if (isSeriePR) ...[
                              const SizedBox(width: 8),
                              _buildBadgePR(
                                badgeKey: Key(
                                  'badge-pr-serie-${exercicio.nome}-${entry.key}',
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            _buildTagRir(serieData),
                            Text(
                              '${serieData.reps ?? '-'} reps',
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${serieData.peso ?? '-'} kg',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
