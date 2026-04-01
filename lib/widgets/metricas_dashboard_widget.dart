import 'package:flutter/material.dart';

import '../controllers/progresso_controller.dart';
import '../theme/app_colors.dart';

class MetricasDashboardWidget extends StatelessWidget {
  final ProgressoController controller;
  final VoidCallback onEditarMeta;

  const MetricasDashboardWidget({
    super.key,
    required this.controller,
    required this.onEditarMeta,
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
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                  child: Stack(
                    children: [
                      const Align(
                        alignment: Alignment.topRight,
                        child: Icon(Icons.edit, color: AppColors.textDimmed, size: 16),
                      ),
                      Column(
                        children: [
                          const Icon(Icons.calendar_today, color: AppColors.primary, size: 30),
                          const SizedBox(height: 12),
                          const Text('META SEMANAL', style: TextStyle(fontSize: 10, color: AppColors.textDimmed)),
                          Text(
                            '${controller.diasTreinadosNaSemana} / ${controller.metaDiasSemana}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.accent),
                          ),
                          const Text('DIAS ATIVOS', style: TextStyle(fontSize: 10, color: AppColors.textDimmed)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    const Icon(Icons.monitor_weight, color: AppColors.primary, size: 30),
                    const SizedBox(height: 12),
                    const Text('MEU IMC', style: TextStyle(fontSize: 10, color: AppColors.textDimmed)),
                    Text(
                      controller.imc.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.accent),
                    ),
                    Text(
                      controller.classificacaoImc,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
