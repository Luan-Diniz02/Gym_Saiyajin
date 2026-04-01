import 'package:flutter/material.dart';

import '../controllers/treino_controller.dart';
import '../theme/app_colors.dart';

class CronometroWidget extends StatelessWidget {
  final TreinoController controller;
  final VoidCallback onTapConfig;

  const CronometroWidget({
    super.key,
    required this.controller,
    required this.onTapConfig,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Column(
          children: [
            GestureDetector(
              onTap: onTapConfig,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.surface, width: 8),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 30, spreadRadius: 10),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      controller.tempoFormatado,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: controller.isTimerRodando ? AppColors.accent : AppColors.textLight,
                      ),
                    ),
                    const Text(
                      'TOQUE PARA AJUSTAR',
                      style: TextStyle(fontSize: 10, color: AppColors.textDimmed, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: controller.isTimerRodando ? controller.pausarTimer : null,
                  icon: const Icon(Icons.pause, size: 16),
                  label: const Text('PAUSAR', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: controller.tempoAtual != controller.tempoDescansoPadrao || controller.isTimerRodando
                      ? controller.reiniciarTimer
                      : null,
                  icon: const Icon(Icons.restart_alt, size: 16),
                  label: const Text('REINICIAR', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: !controller.isTimerRodando ? controller.continuarTimer : null,
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: Text(
                    controller.tempoAtual == controller.tempoDescansoPadrao ? 'INICIAR' : 'CONTINUAR',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
