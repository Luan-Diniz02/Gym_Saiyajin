import 'package:flutter/material.dart';

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
  static const List<int> _temposPreDefinidos = [45, 60, 90, 120, 180, 240];
  late int _tempoSelecionado;

  @override
  void initState() {
    super.initState();
    _tempoSelecionado = widget.controller.tempoDescansoPadrao;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Center(
        child: Text('TEMPO DE DESCANSO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.controller.formatarSegundos(_tempoSelecionado),
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.accent),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  if (_tempoSelecionado > 15) {
                    setState(() => _tempoSelecionado -= 15);
                  }
                },
                icon: const Icon(Icons.remove_circle_outline, size: 32, color: AppColors.primary),
              ),
              const SizedBox(width: 20),
              IconButton(
                onPressed: () => setState(() => _tempoSelecionado += 15),
                icon: const Icon(Icons.add_circle_outline, size: 32, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _temposPreDefinidos.map((tempo) {
              final bool isSelecionado = _tempoSelecionado == tempo;
              return InkWell(
                onTap: () => setState(() => _tempoSelecionado = tempo),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelecionado ? AppColors.primary : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelecionado ? AppColors.primary : AppColors.surface),
                  ),
                  child: Text(
                    widget.controller.formatarSegundos(tempo),
                    style: TextStyle(
                      color: isSelecionado ? AppColors.background : AppColors.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR', style: TextStyle(color: AppColors.textDimmed)),
        ),
        ElevatedButton(
          onPressed: () {
            widget.controller.atualizarTempoDescanso(_tempoSelecionado);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.background),
          child: const Text('SALVAR', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
