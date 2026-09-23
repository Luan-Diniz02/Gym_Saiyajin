import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class ModalAjusteTempoSessao extends StatefulWidget {
  final String titulo;
  final IconData icone;
  final Color corDestaque;
  final int tempoInicialSegundos;
  final int? limiteMaximoSegundos;
  final bool isDescanso;
  final List<int> presets;

  const ModalAjusteTempoSessao({
    super.key,
    required this.titulo,
    required this.icone,
    required this.corDestaque,
    required this.tempoInicialSegundos,
    this.limiteMaximoSegundos,
    this.isDescanso = false,
    required this.presets,
  });

  static Future<int?> show({
    required BuildContext context,
    required String titulo,
    required IconData icone,
    required Color corDestaque,
    required int tempoInicialSegundos,
    int? limiteMaximoSegundos,
    bool isDescanso = false,
    List<int>? presets,
  }) {
    final defaultPresets = isDescanso
        ? const [600, 900, 1200, 1800, 2700, 3600] // 10m, 15m, 20m, 30m, 45m, 1h
        : const [1800, 2700, 3600, 4500, 5400, 7200]; // 30m, 45m, 1h, 1h15, 1h30, 2h

    return showDialog<int>(
      context: context,
      builder: (context) => ModalAjusteTempoSessao(
        titulo: titulo,
        icone: icone,
        corDestaque: corDestaque,
        tempoInicialSegundos: tempoInicialSegundos,
        limiteMaximoSegundos: limiteMaximoSegundos,
        isDescanso: isDescanso,
        presets: presets ?? defaultPresets,
      ),
    );
  }

  @override
  State<ModalAjusteTempoSessao> createState() => _ModalAjusteTempoSessaoState();
}

class _ModalAjusteTempoSessaoState extends State<ModalAjusteTempoSessao> {
  late int _tempoSelecionado;

  @override
  void initState() {
    super.initState();
    _tempoSelecionado = widget.tempoInicialSegundos;
    if (widget.limiteMaximoSegundos != null && _tempoSelecionado > widget.limiteMaximoSegundos!) {
      _tempoSelecionado = widget.limiteMaximoSegundos!;
    }
  }

  void _ajustarTempo(int deltaSegundos) {
    HapticFeedback.lightImpact();
    setState(() {
      int novo = _tempoSelecionado + deltaSegundos;
      if (novo < 0) novo = 0;
      if (widget.limiteMaximoSegundos != null && novo > widget.limiteMaximoSegundos!) {
        novo = widget.limiteMaximoSegundos!;
      }
      _tempoSelecionado = novo;
    });
  }

  void _selecionarPreset(int tempo) {
    if (widget.limiteMaximoSegundos != null && tempo > widget.limiteMaximoSegundos!) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _tempoSelecionado = tempo;
    });
  }

  String _formatarVisorPrincipal(int segundos) {
    final h = segundos ~/ 3600;
    final m = (segundos % 3600) ~/ 60;
    final s = segundos % 60;

    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatarLabelPreset(int totalSegundos) {
    final horas = totalSegundos ~/ 3600;
    final minutos = (totalSegundos % 3600) ~/ 60;

    if (horas > 0) {
      if (minutos > 0) {
        return '${horas}h ${minutos}m';
      }
      return '${horas}h 00';
    }
    return '$minutos min';
  }

  @override
  Widget build(BuildContext context) {
    final bool temLimite = widget.limiteMaximoSegundos != null;
    final bool atingiuMaximo = temLimite && _tempoSelecionado >= widget.limiteMaximoSegundos!;
    final bool podeDecrementar = _tempoSelecionado >= 300; // passo de 5 min (300s)

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Cabeçalho com Ícone e Título
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.corDestaque.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icone,
                      size: 18,
                      color: widget.corDestaque,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1.0,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Visor Central com Steppers de 5 em 5 minutos
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
                    // Botão Decrementar -5m
                    _buildStepperButton(
                      icon: Icons.remove,
                      label: '-5m',
                      enabled: podeDecrementar,
                      onTap: () => _ajustarTempo(-300),
                    ),

                    // Display Central do Tempo
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatarVisorPrincipal(_tempoSelecionado),
                            style: TextStyle(
                              fontSize: _tempoSelecionado >= 3600 ? 36 : 42,
                              fontWeight: FontWeight.w900,
                              color: widget.corDestaque,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            _tempoSelecionado >= 3600 ? 'HORAS : MIN : SEG' : 'MIN : SEG',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDimmed,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Botão Incrementar +5m
                    _buildStepperButton(
                      icon: Icons.add,
                      label: '+5m',
                      enabled: !atingiuMaximo,
                      onTap: () => _ajustarTempo(300),
                    ),
                  ],
                ),
              ),

              // Aviso sutil caso atinja o limite máximo do descanso
              if (temLimite) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      atingiuMaximo ? Icons.lock_outline : Icons.info_outline,
                      size: 13,
                      color: atingiuMaximo ? AppColors.accent : AppColors.textDimmed,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        atingiuMaximo
                            ? 'Descanso limitado ao tempo de treino'
                            : 'Máx permitido: ${_formatarLabelPreset(widget.limiteMaximoSegundos!)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: atingiuMaximo ? FontWeight.w700 : FontWeight.normal,
                          color: atingiuMaximo ? AppColors.accent : AppColors.textDimmed,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

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

              // Grade Simétrica de Presets Rápidos
              Column(
                children: [
                  Row(
                    children: [
                      _buildPresetItem(widget.presets[0]),
                      const SizedBox(width: 8),
                      _buildPresetItem(widget.presets[1]),
                      const SizedBox(width: 8),
                      _buildPresetItem(widget.presets[2]),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPresetItem(widget.presets[3]),
                      const SizedBox(width: 8),
                      _buildPresetItem(widget.presets[4]),
                      const SizedBox(width: 8),
                      _buildPresetItem(widget.presets[5]),
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
                          Navigator.pop(context, _tempoSelecionado);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.corDestaque,
                          foregroundColor: AppColors.background,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'CONFIRMAR',
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
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedOpacity(
          opacity: enabled ? 1.0 : 0.25,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: 48,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.textLight, size: 20),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDimmed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetItem(int tempo) {
    final isSelected = _tempoSelecionado == tempo;
    final bool desabilitado = widget.limiteMaximoSegundos != null && tempo > widget.limiteMaximoSegundos!;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: desabilitado ? null : () => _selecionarPreset(tempo),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: isSelected
                  ? widget.corDestaque
                  : desabilitado
                      ? AppColors.surface.withValues(alpha: 0.3)
                      : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? widget.corDestaque
                    : desabilitado
                        ? AppColors.cardBorder.withValues(alpha: 0.3)
                        : AppColors.cardBorder,
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _formatarLabelPreset(tempo),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                color: isSelected
                    ? AppColors.background
                    : desabilitado
                        ? AppColors.textDimmed.withValues(alpha: 0.3)
                        : AppColors.textLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
