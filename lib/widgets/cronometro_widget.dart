import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class CronometroWidget extends StatelessWidget {
  final String tempoFormatado;
  final int tempoAtual;
  final int tempoDescansoPadrao;
  final bool isTimerRodando;
  final VoidCallback onTapConfig;
  final VoidCallback onPausar;
  final VoidCallback onReiniciar;
  final VoidCallback onIniciarOuContinuar;

  const CronometroWidget({
    super.key,
    required this.tempoFormatado,
    required this.tempoAtual,
    required this.tempoDescansoPadrao,
    required this.isTimerRodando,
    required this.onTapConfig,
    required this.onPausar,
    required this.onReiniciar,
    required this.onIniciarOuContinuar,
  });

  @override
  Widget build(BuildContext context) {
    final double progresso = tempoDescansoPadrao > 0 ? (tempoAtual / tempoDescansoPadrao).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        GestureDetector(
          onTap: onTapConfig,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: progresso,
                  strokeWidth: 10,
                  color: isTimerRodando ? AppColors.accent : AppColors.primary,
                  backgroundColor: AppColors.surface.withValues(alpha: 0.5),
                ),
              ),
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 30, spreadRadius: 10),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tempoFormatado,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: isTimerRodando ? AppColors.accent : AppColors.textLight,
                      ),
                    ),
                    const Text(
                      'TOQUE PARA AJUSTAR',
                      style: TextStyle(fontSize: 10, color: AppColors.textDimmed, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: isTimerRodando ? onPausar : null,
              icon: const Icon(Icons.pause, size: 16),
              label: const Text('PAUSAR', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
            OutlinedButton.icon(
              onPressed: tempoAtual != tempoDescansoPadrao || isTimerRodando ? onReiniciar : null,
              icon: const Icon(Icons.restart_alt, size: 16),
              label: const Text('REINICIAR', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
            ElevatedButton.icon(
              onPressed: !isTimerRodando ? onIniciarOuContinuar : null,
              icon: const Icon(Icons.play_arrow, size: 16),
              label: Text(
                tempoAtual == tempoDescansoPadrao ? 'INICIAR' : 'CONTINUAR',
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
  }
}
