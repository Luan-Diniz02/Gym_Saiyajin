import 'package:flutter/material.dart';

import '../models/exercicio.dart';
import '../models/serie.dart';
import '../theme/app_colors.dart';

class HistoricoCardWidget extends StatelessWidget {
  final Exercicio exercicio;

  const HistoricoCardWidget({
    super.key,
    required this.exercicio,
  });

  @override
  Widget build(BuildContext context) {
    final List<Serie> detalhes = exercicio.seriesDetalhes;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textDimmed,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Row(
            children: [
              const Icon(Icons.fitness_center, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                exercicio.nome,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 28),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    exercicio.grupo,
                    style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${detalhes.length} SÉRIES', style: const TextStyle(color: AppColors.textDimmed, fontSize: 12)),
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
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Série $serieIndex', style: const TextStyle(color: AppColors.textDimmed, fontSize: 14)),
                        Row(
                          children: [
                            Text('${serieData.reps} reps', style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 16),
                            Text('${serieData.peso} kg', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
