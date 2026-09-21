import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/treino_controller.dart';
import '../theme/app_colors.dart';

class ConfigTempoDescansoModal extends StatefulWidget {
  final TreinoController controller;

  const ConfigTempoDescansoModal({
    super.key,
    required this.controller,
  });

  @override
  State<ConfigTempoDescansoModal> createState() => _ConfigTempoDescansoModalState();
}

class _ConfigTempoDescansoModalState extends State<ConfigTempoDescansoModal> {
  // Presets clássicos e ergonômicos de academia (Grade 3x2)
  static const List<int> _temposPreDefinidos = [45, 60, 90, 120, 180, 240];

  late int _tempoSelecionado;

  @override
  void initState() {
    super.initState();
    _tempoSelecionado = widget.controller.tempoDescansoPadrao;
  }

  void _ajustarTempo(int delta) {
    HapticFeedback.lightImpact();
    setState(() {
      final novo = _tempoSelecionado + delta;
      if (novo >= 15 && novo <= 600) {
        _tempoSelecionado = novo;
      }
    });
  }

  void _selecionarPreset(int tempo) {
    HapticFeedback.selectionClick();
    setState(() {
      _tempoSelecionado = tempo;
    });
  }

  String _formatarLabelPreset(int totalSegundos) {
    final minutos = totalSegundos ~/ 60;
    final segundos = totalSegundos % 60;
    if (minutos == 0) {
      return '00:${segundos.toString().padLeft(2, '0')}';
    }
    return '$minutos:${segundos.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Título do Modal
            const Text(
              'TEMPO DE DESCANSO',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.0,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 20),

            // Visor Central com botões satélites -15s e +15s
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botão Decrementar -15s
                  _buildStepperButton(
                    icon: Icons.remove,
                    label: '-15s',
                    enabled: _tempoSelecionado > 15,
                    onTap: () => _ajustarTempo(-15),
                  ),

                  // Display Central do Tempo
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.controller.formatarSegundos(_tempoSelecionado),
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accent,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const Text(
                          'MIN : SEG',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDimmed,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Botão Incrementar +15s
                  _buildStepperButton(
                    icon: Icons.add,
                    label: '+15s',
                    enabled: _tempoSelecionado < 600,
                    onTap: () => _ajustarTempo(15),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Rótulo de Atalhos Rápidos
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ATALHOS RÁPIDOS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppColors.textDimmed,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Grade Simétrica 3x2 de Presets Rápidos
            Column(
              children: [
                Row(
                  children: [
                    _buildPresetItem(_temposPreDefinidos[0]),
                    const SizedBox(width: 8),
                    _buildPresetItem(_temposPreDefinidos[1]),
                    const SizedBox(width: 8),
                    _buildPresetItem(_temposPreDefinidos[2]),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPresetItem(_temposPreDefinidos[3]),
                    const SizedBox(width: 8),
                    _buildPresetItem(_temposPreDefinidos[4]),
                    const SizedBox(width: 8),
                    _buildPresetItem(_temposPreDefinidos[5]),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Botões de Ação
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textDimmed,
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'CANCELAR',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        widget.controller.atualizarTempoDescanso(_tempoSelecionado);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.background,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'SALVAR',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: enabled ? AppColors.surface : AppColors.surface.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled ? AppColors.primary.withValues(alpha: 0.4) : AppColors.cardBorder,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: enabled ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: enabled ? AppColors.textLight : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetItem(int tempo) {
    final bool isSelecionado = _tempoSelecionado == tempo;

    return Expanded(
      child: Material(
        color: isSelecionado ? AppColors.primary : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _selecionarPreset(tempo),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelecionado ? AppColors.primary : AppColors.cardBorder,
                width: 1.2,
              ),
            ),
            child: Text(
              _formatarLabelPreset(tempo),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelecionado ? AppColors.background : AppColors.textLight,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
