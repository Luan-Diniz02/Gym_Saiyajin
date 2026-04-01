import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/treino_controller.dart';
import '../theme/app_colors.dart';

class SerieRowWidget extends StatelessWidget {
  final int index;
  final TreinoController controller;

  const SerieRowWidget({
    super.key,
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final exercicioAtual = controller.exercicioAtual;
        if (exercicioAtual == null || index >= exercicioAtual.seriesDetalhes.length) {
          return const SizedBox.shrink();
        }

        final serie = exercicioAtual.seriesDetalhes[index];
        final bool isConcluida = serie.concluida;
        final double? peso = serie.peso;
        final int? reps = serie.reps;
        final String nomeExercicioAtual = exercicioAtual.nome;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isConcluida ? AppColors.accent : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isConcluida ? AppColors.background : AppColors.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PESO (KG)', style: TextStyle(fontSize: 10, color: AppColors.textDimmed)),
                    const SizedBox(height: 4),
                    _buildCustomTextField(
                      chave: 'peso-$nomeExercicioAtual-$index',
                      valorInicial: peso?.toStringAsFixed(peso % 1 == 0 ? 0 : 1) ?? '',
                      isConcluida: isConcluida,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [controller.pesoInputFormatter],
                      onChanged: (valor) => controller.atualizarPesoSerie(index, valor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('REPS', style: TextStyle(fontSize: 10, color: AppColors.textDimmed)),
                    const SizedBox(height: 4),
                    _buildCustomTextField(
                      chave: 'reps-$nomeExercicioAtual-$index',
                      valorInicial: reps?.toString() ?? '',
                      isConcluida: isConcluida,
                      keyboardType: TextInputType.number,
                      inputFormatters: [controller.repsInputFormatter],
                      onChanged: (valor) => controller.atualizarRepsSerie(index, valor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => controller.toggleConcluidaSerie(index),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isConcluida ? AppColors.primary : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isConcluida ? AppColors.primary : AppColors.surface),
                  ),
                  child: Icon(Icons.check, color: isConcluida ? AppColors.background : AppColors.textDimmed),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomTextField({
    required String chave,
    required String valorInicial,
    required bool isConcluida,
    required TextInputType keyboardType,
    required List<TextInputFormatter> inputFormatters,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      key: ValueKey(chave),
      initialValue: valorInicial,
      readOnly: isConcluida,
      keyboardType: keyboardType,
      inputFormatters: isConcluida ? null : inputFormatters,
      onChanged: isConcluida ? null : onChanged,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: isConcluida ? AppColors.textDimmed : AppColors.textLight,
      ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
