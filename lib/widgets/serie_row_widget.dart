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
        final bool podeExcluir = exercicioAtual.seriesDetalhes.length > 1;

        final serieAnterior = controller.obterSerieAnterior(nomeExercicioAtual, index);
        final String? hintPeso = serieAnterior?.peso != null
            ? (serieAnterior!.peso! % 1 == 0
                ? serieAnterior.peso!.toInt().toString()
                : serieAnterior.peso!.toString())
            : null;
        final String? hintReps =
            serieAnterior?.reps != null ? serieAnterior!.reps.toString() : null;

        final cardConteudo = Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isConcluida ? AppColors.accent : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: isConcluida ? AppColors.background : AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'PESO (KG)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDimmed,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildCustomTextField(
                          chave: 'peso-$nomeExercicioAtual-$index',
                          valorInicial: peso?.toStringAsFixed(peso % 1 == 0 ? 0 : 1) ?? '',
                          hintText: hintPeso,
                          isConcluida: isConcluida,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textInputAction: TextInputAction.next,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'REPS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDimmed,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildCustomTextField(
                          chave: 'reps-$nomeExercicioAtual-$index',
                          valorInicial: reps?.toString() ?? '',
                          hintText: hintReps,
                          isConcluida: isConcluida,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [controller.repsInputFormatter],
                          onChanged: (valor) => controller.atualizarRepsSerie(index, valor),
                        ),
                      ],
                    ),
                  ),
                  if (serieAnterior != null &&
                      (serieAnterior.peso != null || serieAnterior.reps != null)) ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message:
                          'Preencher com anterior (${hintPeso ?? '-'} kg × ${hintReps ?? '-'} reps)',
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          controller.preencherSerieComAnterior(index);
                        },
                        child: Container(
                          width: 40,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.cardBorder,
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => controller.toggleConcluidaSerie(index),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isConcluida ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isConcluida ? AppColors.primary : AppColors.cardBorder,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.check,
                        size: 24,
                        color: isConcluida ? AppColors.background : AppColors.textDimmed,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        if (!podeExcluir) {
          return cardConteudo;
        }

        return Dismissible(
          key: ValueKey('serie_${nomeExercicioAtual}_${serie.hashCode}_$index'),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.delete_outline, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'EXCLUIR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          onDismissed: (_) {
            controller.removerSerie(index);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Série ${index + 1} removida.'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: cardConteudo,
        );
      },
    );
  }

  Widget _buildCustomTextField({
    required String chave,
    required String valorInicial,
    String? hintText,
    required bool isConcluida,
    required TextInputType keyboardType,
    TextInputAction? textInputAction,
    required List<TextInputFormatter> inputFormatters,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      height: 44,
      child: TextFormField(
        key: ValueKey('$chave-$valorInicial'),
        initialValue: valorInicial,
        readOnly: isConcluida,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: isConcluida ? null : inputFormatters,
        onChanged: isConcluida ? null : onChanged,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: isConcluida ? AppColors.textDimmed : AppColors.textLight,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 15,
            fontWeight: FontWeight.normal,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
