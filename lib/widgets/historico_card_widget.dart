import 'package:flutter/material.dart';

import '../models/exercicio.dart';
import '../models/serie.dart';
import '../theme/app_colors.dart';
import 'exercicio_midia_widget.dart';
import 'kinto_un_icon.dart';

class HistoricoCardWidget extends StatelessWidget {
  final Exercicio exercicio;

  const HistoricoCardWidget({
    super.key,
    required this.exercicio,
  });

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
    final List<Serie> detalhes = exercicio.seriesDetalhes;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textDimmed,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
            child: Row(
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
                const SizedBox(width: 10),
                Text(
                  '${detalhes.length} SÉRIES',
                  style: const TextStyle(
                    color: AppColors.textDimmed,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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
                  final int serieIndex = entry.key + 1;
                  final Serie serieData = entry.value;
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
                              'Série $serieIndex',
                              style: const TextStyle(
                                color: AppColors.textDimmed,
                                fontSize: 14,
                              ),
                            ),
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
