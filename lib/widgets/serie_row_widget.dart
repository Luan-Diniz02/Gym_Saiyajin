import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/treino_controller.dart';
import '../models/serie.dart';
import '../theme/app_colors.dart';
import 'dragon_ball_icon.dart';

class SerieRowWidget extends StatefulWidget {
  final int index;
  final TreinoController controller;

  const SerieRowWidget({
    super.key,
    required this.index,
    required this.controller,
  });

  @override
  State<SerieRowWidget> createState() => _SerieRowWidgetState();
}

class _SerieRowWidgetState extends State<SerieRowWidget> {
  late final TextEditingController _pesoController;
  late final TextEditingController _repsController;
  late final FocusNode _pesoFocusNode;
  late final FocusNode _repsFocusNode;

  Serie? _obterSerieAtual() {
    final exercicio = widget.controller.exercicioAtual;
    if (exercicio != null && widget.index < exercicio.seriesDetalhes.length) {
      return exercicio.seriesDetalhes[widget.index];
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final serie = _obterSerieAtual();
    final pesoStr = serie?.peso != null
        ? (serie!.peso! % 1 == 0
            ? serie.peso!.toInt().toString()
            : serie.peso!.toString())
        : '';
    final repsStr = serie?.reps != null ? serie!.reps.toString() : '';

    _pesoController = TextEditingController(text: pesoStr);
    _repsController = TextEditingController(text: repsStr);
    _pesoFocusNode = FocusNode();
    _repsFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant SerieRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final serie = _obterSerieAtual();
    if (serie != null) {
      final pesoStr = serie.peso != null
          ? (serie.peso! % 1 == 0
              ? serie.peso!.toInt().toString()
              : serie.peso!.toString())
          : '';
      final repsStr = serie.reps != null ? serie.reps.toString() : '';

      // Só sincroniza valores caso o campo não esteja com foco ativo de digitação
      if (!_pesoFocusNode.hasFocus && _pesoController.text != pesoStr) {
        _pesoController.text = pesoStr;
      }
      if (!_repsFocusNode.hasFocus && _repsController.text != repsStr) {
        _repsController.text = repsStr;
      }
    }
  }

  @override
  void dispose() {
    _pesoController.dispose();
    _repsController.dispose();
    _pesoFocusNode.dispose();
    _repsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final exercicioAtual = widget.controller.exercicioAtual;
        if (exercicioAtual == null ||
            widget.index >= exercicioAtual.seriesDetalhes.length) {
          return const SizedBox.shrink();
        }

        final serie = exercicioAtual.seriesDetalhes[widget.index];
        final bool isConcluida = serie.concluida;
        final String nomeExercicioAtual = exercicioAtual.nome;
        final bool podeExcluir = exercicioAtual.seriesDetalhes.length > 1;

        final serieAnterior =
            widget.controller.obterSerieAnterior(nomeExercicioAtual, widget.index);
        final String? hintPeso = serieAnterior?.peso != null
            ? (serieAnterior!.peso! % 1 == 0
                ? serieAnterior.peso!.toInt().toString()
                : serieAnterior.peso!.toString())
            : null;
        final String? hintReps = serieAnterior?.reps != null
            ? serieAnterior!.reps.toString()
            : null;

        final isPR = widget.controller.isSerieRecorde(nomeExercicioAtual, widget.index);

        final cardConteudo = Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPR
                  ? (isConcluida ? AppColors.primary : AppColors.accent.withValues(alpha: 0.6))
                  : AppColors.cardBorder,
              width: isPR ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
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
                        '${widget.index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: isConcluida
                              ? AppColors.background
                              : AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                  if (isPR)
                    Positioned(
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.accent,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'PR',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const DragonBallIcon(
                              size: 10,
                              stars: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
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
                      chave: 'peso-$nomeExercicioAtual-${widget.index}',
                      textController: _pesoController,
                      focusNode: _pesoFocusNode,
                      hintText: hintPeso,
                      isConcluida: isConcluida,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                      inputFormatters: [widget.controller.pesoInputFormatter],
                      onChanged: (valor) =>
                          widget.controller.atualizarPesoSerie(widget.index, valor),
                      onSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_repsFocusNode);
                      },
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
                      chave: 'reps-$nomeExercicioAtual-${widget.index}',
                      textController: _repsController,
                      focusNode: _repsFocusNode,
                      hintText: hintReps,
                      isConcluida: isConcluida,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [widget.controller.repsInputFormatter],
                      onChanged: (valor) =>
                          widget.controller.atualizarRepsSerie(widget.index, valor),
                      onSubmitted: (_) {
                        _concluirSeriePeloTeclado();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.controller.toggleConcluidaSerie(widget.index);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isConcluida
                        ? AppColors.primary
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isConcluida
                          ? AppColors.primary
                          : AppColors.cardBorder,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.check,
                    size: 24,
                    color: isConcluida
                        ? AppColors.background
                        : AppColors.textDimmed,
                  ),
                ),
              ),
            ],
          ),
        );

        if (!podeExcluir) {
          return cardConteudo;
        }

        return Dismissible(
          key: ValueKey(
              'serie_${nomeExercicioAtual}_${serie.hashCode}_${widget.index}'),
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
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text('Remover Série ${widget.index + 1}?'),
                  content: const Text(
                    'Tem certeza que deseja remover esta série do treino atual?',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Remover',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (_) {
            widget.controller.removerSerie(widget.index);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Série ${widget.index + 1} removida.'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: cardConteudo,
        );
      },
    );
  }

  void _concluirSeriePeloTeclado() {
    HapticFeedback.selectionClick();
    widget.controller.toggleConcluidaSerie(widget.index);
  }

  Widget _buildCustomTextField({
    required String chave,
    required TextEditingController textController,
    required FocusNode focusNode,
    String? hintText,
    required bool isConcluida,
    required TextInputType keyboardType,
    TextInputAction? textInputAction,
    required List<TextInputFormatter> inputFormatters,
    required ValueChanged<String> onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    return SizedBox(
      height: 44,
      child: TextField(
        key: ValueKey(chave),
        controller: textController,
        focusNode: focusNode,
        readOnly: isConcluida,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: isConcluida ? null : inputFormatters,
        onChanged: isConcluida ? null : onChanged,
        onSubmitted: isConcluida ? null : onSubmitted,
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
