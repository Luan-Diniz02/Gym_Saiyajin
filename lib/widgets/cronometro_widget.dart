import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'escotilha_camara_painter.dart';

/// Widget do Cronômetro de Descanso estilizado como a
/// Escotilha da Câmara de Regeneração Médica (Namekusei / Freeza Force).
///
/// Apresenta:
/// - Janela circular de inspeção (escotilha) com aro metálico e 8 rebites.
/// - Fluido medicinal bioenergético ciano/esmeralda proporcional ao tempo restante.
/// - Micro-bolhas de oxigênio animadas procedurais no interior do líquido.
/// - Silhueta sutil da máscara de oxigênio submersa ao fundo.
/// - Dígitos digitais de alto contraste com telemetria médica.
class CronometroWidget extends StatefulWidget {
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
  State<CronometroWidget> createState() => _CronometroWidgetState();
}

class _CronometroWidgetState extends State<CronometroWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    if (widget.isTimerRodando) {
      _animController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant CronometroWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTimerRodando != oldWidget.isTimerRodando) {
      if (widget.isTimerRodando) {
        _animController.repeat();
      } else {
        _animController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double progresso = widget.tempoDescansoPadrao > 0
        ? (widget.tempoAtual / widget.tempoDescansoPadrao).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        GestureDetector(
          onTap: widget.onTapConfig,
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              return CustomPaint(
                size: const Size(184, 184),
                painter: EscotilhaCamaraPainter(
                  animationValue: _animController.value,
                  isAtivo: widget.isTimerRodando,
                  progresso: progresso,
                ),
                child: SizedBox(
                  width: 184,
                  height: 184,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Chip de Status / Telemetria Médica
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: widget.isTimerRodando
                                ? const Color(0xFFFFD700).withValues(alpha: 0.45)
                                : const Color(0xFFFF9E00).withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5.5,
                              height: 5.5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.isTimerRodando
                                    ? const Color(0xFFFFD700)
                                    : (widget.tempoAtual <
                                            widget.tempoDescansoPadrao
                                        ? const Color(0xFFFF8C00)
                                        : const Color(0xFFFFD54F)),
                                boxShadow: widget.isTimerRodando
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFFFD700)
                                              .withValues(alpha: 0.8),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 4.5),
                            Text(
                              widget.isTimerRodando
                                  ? 'REGENERAÇÃO'
                                  : (widget.tempoAtual <
                                          widget.tempoDescansoPadrao
                                      ? 'PAUSADO'
                                      : 'CÂMARA DE KI'),
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: widget.isTimerRodando
                                    ? const Color(0xFFFFD700)
                                    : (widget.tempoAtual <
                                            widget.tempoDescansoPadrao
                                        ? const Color(0xFFFF8C00)
                                        : const Color(0xFFFFD54F)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Tempo formatado em alta escala e nitidez
                      Text(
                        widget.tempoFormatado,
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: widget.isTimerRodando
                              ? const Color(0xFFFFF8E1)
                              : AppColors.textLight,
                          shadows: [
                            Shadow(
                              color: widget.isTimerRodando
                                  ? const Color(0xFFFFB300)
                                      .withValues(alpha: 0.7)
                                  : Colors.black87,
                              blurRadius: widget.isTimerRodando ? 12 : 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Rótulo de ajuste
                      Text(
                        'TOQUE P/ AJUSTAR',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: widget.isTimerRodando
                              ? const Color(0xFFFFD54F).withValues(alpha: 0.9)
                              : AppColors.textDimmed,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: widget.tempoAtual != widget.tempoDescansoPadrao ||
                      widget.isTimerRodando
                  ? widget.onReiniciar
                  : null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Icon(Icons.restart_alt, size: 22),
            ),
            ElevatedButton(
              onPressed: widget.isTimerRodando
                  ? widget.onPausar
                  : widget.onIniciarOuContinuar,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                backgroundColor: widget.isTimerRodando
                    ? AppColors.accent
                    : AppColors.primary,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: widget.isTimerRodando ? 4 : 1,
                shadowColor: const Color(0xFFFFB300).withValues(alpha: 0.5),
              ),
              child: Icon(
                widget.isTimerRodando ? Icons.pause : Icons.play_arrow,
                size: 22,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
