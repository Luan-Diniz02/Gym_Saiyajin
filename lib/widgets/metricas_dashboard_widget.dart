import 'package:flutter/material.dart';

import '../controllers/progresso_controller.dart';
import '../theme/app_colors.dart';
import 'dragon_radar_icon.dart';

class MetricasDashboardWidget extends StatelessWidget {
  final ProgressoController controller;
  final VoidCallback onEditarMeta;
  final VoidCallback onEditarMedidas;

  const MetricasDashboardWidget({
    super.key,
    required this.controller,
    required this.onEditarMeta,
    required this.onEditarMedidas,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onEditarMeta,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Stack(
                    children: [
                      const Positioned(
                        top: 0,
                        right: 0,
                        child: Icon(Icons.edit, color: AppColors.textDimmed, size: 16),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            DragonRadarIcon(
                              size: 32,
                              dots: controller.diasTreinadosNaSemana,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'META SEMANAL',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDimmed),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${controller.diasTreinadosNaSemana} / ${controller.metaDiasSemana}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.accent),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'DIAS ATIVOS',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDimmed),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: onEditarMedidas,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Stack(
                    children: [
                      const Positioned(
                        top: 0,
                        right: 0,
                        child: Icon(Icons.edit, color: AppColors.textDimmed, size: 16),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.monitor_weight_outlined, color: AppColors.primary, size: 30),
                            const SizedBox(height: 12),
                            Text(
                              controller.percentualGordura != null
                                  ? 'GORDURA (BF)'
                                  : 'MEU IMC',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDimmed),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.percentualGordura != null
                                  ? '${controller.percentualGordura!.toStringAsFixed(1)}%'
                                  : controller.imc.toStringAsFixed(1),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.accent),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.percentualGordura != null
                                  ? (controller.classificacaoGordura ?? '')
                                  : controller.classificacaoImc,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
