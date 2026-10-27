import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/treino_controller.dart';
import '../models/serie.dart';
import '../theme/app_colors.dart';
import 'dragon_ball_icon.dart';
import 'kinto_un_icon.dart';

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
  bool _seletorRirAberto = false;

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

  Color _corPorTipo(TipoSerie tipo) {
    switch (tipo) {
      case TipoSerie.normal:
        return AppColors.accent;
      case TipoSerie.warmup:
        return const Color(0xFFFFD700); // Dourado Aquecimento
      case TipoSerie.dropset:
        return AppColors.primary; // Laranja Vibrante (#FF8C00)
      case TipoSerie.falha:
        return AppColors.danger; // Vermelho Falha Total (#FF5252)
    }
  }

  Color _corPorRir(int rir) {
    if (rir <= 0) return AppColors.danger;
    if (rir == 1) return AppColors.primary;
    if (rir == 2) return AppColors.accent;
    return const Color(0xFF4FC3F7);
  }

  void _abrirModalTipoSerie(TipoSerie tipoAtual, int numeroSerieTrabalho) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const KintoUnIcon(size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'CLASSIFICAÇÃO DA SÉRIE ${widget.index + 1}',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Toque rápido no círculo alterna automaticamente; segure para abrir este menu.',
                  style: TextStyle(color: AppColors.textDimmed, fontSize: 12),
                ),
                const SizedBox(height: 14),
                ...TipoSerie.values.map((tipo) {
                  final selecionado = tipo == tipoAtual;
                  final cor = _corPorTipo(tipo);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        widget.controller.atualizarTipoSerie(
                          widget.index,
                          tipo.codigo,
                        );
                        Navigator.pop(sheetContext);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selecionado
                              ? cor.withValues(alpha: 0.14)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selecionado ? cor : AppColors.cardBorder,
                            width: selecionado ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cor.withValues(alpha: 0.15),
                                border: Border.all(color: cor, width: 1.5),
                              ),
                              alignment: Alignment.center,
                              child: tipo == TipoSerie.warmup
                                  ? const KintoUnIcon(size: 20, showGlow: false)
                                  : Text(
                                      tipo == TipoSerie.normal
                                          ? '$numeroSerieTrabalho'
                                          : tipo.sigla,
                                      style: TextStyle(
                                        color: cor,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tipo.label,
                                    style: TextStyle(
                                      color: selecionado
                                          ? cor
                                          : AppColors.textLight,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tipo.descricao,
                                    style: const TextStyle(
                                      color: AppColors.textDimmed,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selecionado)
                              Icon(Icons.check_circle, color: cor, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConteudoIndicadorSerie({
    required TipoSerie tipoSerie,
    required bool isConcluida,
    required Color corTipo,
    required int numeroSerieTrabalho,
  }) {
    if (tipoSerie == TipoSerie.warmup) {
      return KintoUnIcon(
        size: 24,
        primaryColor: const Color(0xFFFFD700),
        secondaryColor: const Color(0xFFFFA000),
        showGlow: isConcluida,
      );
    }

    final textoIndicador = tipoSerie == TipoSerie.normal
        ? '$numeroSerieTrabalho'
        : tipoSerie.sigla;

    return Text(
      textoIndicador,
      style: TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 18,
        color: isConcluida ? AppColors.background : corTipo,
      ),
    );
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
        final TipoSerie tipoSerie = serie.tipoEnum;
        final Color corTipo = _corPorTipo(tipoSerie);
        final String nomeExercicioAtual = exercicioAtual.nome;
        final bool podeExcluir = exercicioAtual.seriesDetalhes.length > 1;
        final int numeroSerieTrabalho = Serie.calcularNumeroSerieTrabalho(
          exercicioAtual.seriesDetalhes,
          widget.index,
        );

        final serieAnterior = widget.controller.obterSerieAnterior(
          nomeExercicioAtual,
          widget.index,
        );
        final String? hintPeso = serieAnterior?.peso != null
            ? (serieAnterior!.peso! % 1 == 0
                ? serieAnterior.peso!.toInt().toString()
                : serieAnterior.peso!.toString())
            : null;
        final String? hintReps = serieAnterior?.reps != null
            ? serieAnterior!.reps.toString()
            : null;

        final isPR = widget.controller.isSerieRecorde(
          nomeExercicioAtual,
          widget.index,
        );

        final cardConteudo = Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPR
                  ? (isConcluida
                      ? AppColors.primary
                      : AppColors.accent.withValues(alpha: 0.6))
                  : (tipoSerie != TipoSerie.normal
                      ? corTipo.withValues(alpha: 0.45)
                      : AppColors.cardBorder),
              width: (isPR || tipoSerie != TipoSerie.normal) ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        key: ValueKey('badge-tipo-serie-${widget.index}'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          widget.controller.alternarTipoSerie(widget.index);
                        },
                        onLongPress: () => _abrirModalTipoSerie(
                          tipoSerie,
                          numeroSerieTrabalho,
                        ),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isConcluida
                                ? (tipoSerie == TipoSerie.warmup
                                    ? corTipo.withValues(alpha: 0.18)
                                    : corTipo)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(color: corTipo, width: 2),
                          ),
                          child: Center(
                            child: _buildConteudoIndicadorSerie(
                              tipoSerie: tipoSerie,
                              isConcluida: isConcluida,
                              corTipo: corTipo,
                              numeroSerieTrabalho: numeroSerieTrabalho,
                            ),
                          ),
                        ),
                      ),
                      if (isPR)
                        Positioned(
                          top: -8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
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
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'PR',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: 3),
                                DragonBallIcon(
                                  size: 10,
                                  stars: 1,
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (tipoSerie != TipoSerie.normal)
                        Positioned(
                          top: -7,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: corTipo, width: 1),
                            ),
                            child: Text(
                              tipoSerie.sigla,
                              style: TextStyle(
                                color: corTipo,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
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
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            widget.controller.pesoInputFormatter,
                          ],
                          onChanged: (valor) => widget.controller
                              .atualizarPesoSerie(widget.index, valor),
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
                          inputFormatters: [
                            widget.controller.repsInputFormatter,
                          ],
                          onChanged: (valor) => widget.controller
                              .atualizarRepsSerie(widget.index, valor),
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
              const SizedBox(height: 8),
              // Barra compacta de classificação + botão retrátil de RIR / RPE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    key: ValueKey('label-tipo-serie-${widget.index}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _abrirModalTipoSerie(
                      tipoSerie,
                      numeroSerieTrabalho,
                    ),
                    onLongPress: () => _abrirModalTipoSerie(
                      tipoSerie,
                      numeroSerieTrabalho,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (tipoSerie == TipoSerie.warmup) ...[
                            const KintoUnIcon(
                              size: 14,
                              showGlow: false,
                              showTrail: false,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'AQUECIMENTO',
                              style: TextStyle(
                                color: corTipo,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ] else if (tipoSerie == TipoSerie.dropset) ...[
                            Icon(Icons.bolt_rounded, size: 13, color: corTipo),
                            const SizedBox(width: 3),
                            Text(
                              'DROP-SET',
                              style: TextStyle(
                                color: corTipo,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ] else if (tipoSerie == TipoSerie.falha) ...[
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 13,
                              color: corTipo,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'FALHA TOTAL',
                              style: TextStyle(
                                color: corTipo,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ] else ...[
                            const Text(
                              'SÉRIE DE TRABALHO',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 15,
                            color: tipoSerie == TipoSerie.normal
                                ? AppColors.textMuted
                                : corTipo,
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    key: ValueKey('btn-rir-${widget.index}'),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _seletorRirAberto = !_seletorRirAberto;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: serie.rir != null
                            ? _corPorRir(serie.rir!).withValues(alpha: 0.14)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: serie.rir != null
                              ? _corPorRir(serie.rir!).withValues(alpha: 0.6)
                              : AppColors.cardBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.speed_rounded,
                            size: 12,
                            color: serie.rir != null
                                ? _corPorRir(serie.rir!)
                                : AppColors.textDimmed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            serie.rir != null
                                ? '${serie.rirLabel} • ${serie.rpeLabel}'
                                : 'RIR / RPE',
                            style: TextStyle(
                              color: serie.rir != null
                                  ? _corPorRir(serie.rir!)
                                  : AppColors.textDimmed,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_seletorRirAberto) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [0, 1, 2, 3, 4].map((valorRir) {
                      final isSel = serie.rir == valorRir;
                      final corRir = _corPorRir(valorRir);
                      final rpeEq = 10 - valorRir;
                      final labelRir = valorRir >= 4 ? '4+' : '$valorRir';
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: valorRir < 4 ? 4.0 : 0.0,
                          ),
                          child: GestureDetector(
                            key: ValueKey('chip-rir-${widget.index}-$valorRir'),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              final novoValor = isSel ? null : valorRir;
                              widget.controller.atualizarRirSerie(
                                widget.index,
                                novoValor,
                              );
                              setState(() {
                                _seletorRirAberto = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? corRir.withValues(alpha: 0.18)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: isSel ? corRir : AppColors.cardBorder,
                                  width: isSel ? 1.3 : 1.0,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'RIR $labelRir',
                                    style: TextStyle(
                                      color: isSel
                                          ? corRir
                                          : AppColors.textLight,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'RPE $rpeEq',
                                    style: TextStyle(
                                      color: isSel
                                          ? corRir.withValues(alpha: 0.9)
                                          : AppColors.textDimmed,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
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
