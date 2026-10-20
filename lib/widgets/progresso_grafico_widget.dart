import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../controllers/progresso_controller.dart';
import '../models/recorde_pessoal.dart';
import '../theme/app_colors.dart';
import 'exercicio_midia_widget.dart';

class ProgressoGraficoWidget extends StatelessWidget {
  final ProgressoController controller;

  const ProgressoGraficoWidget({
    super.key,
    required this.controller,
  });

  void _abrirModalSelecaoExercicio(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _ModalFiltroExercicioGrafico(controller: controller);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final exercicioAtual = controller.exercicioFiltro;
        final temExercicioValido =
            exercicioAtual.isNotEmpty && exercicioAtual != 'Nenhum exercício';
        final grupoAtual = controller.gruposExercicios[exercicioAtual] ?? '';
        final totalPontos = controller.pontosDoGraficoFiltrado.length;
        final indicesVisiveisX = ProgressoController.calcularIndicesVisiveisEixoX(
          totalPontos,
          maxLabels: 5,
        );

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PROGRESSÃO DE CARGA',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: AppColors.primary, size: 22),
                    onPressed: () => _abrirModalSelecaoExercicio(context),
                    tooltip: 'Filtrar exercício',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _abrirModalSelecaoExercicio(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      if (temExercicioValido)
                        ExercicioThumbnailWidget(
                          nomeExercicio: exercicioAtual,
                          grupo: grupoAtual,
                          size: 36,
                          borderRadius: 9,
                          abrirModalAoTocar: true,
                          exibirIndicadorGif: false,
                        )
                      else
                        const Icon(Icons.search, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          exercicioAtual,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: AppColors.textDimmed, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Seletor Rápido de Período (Últimos 10 / 3 Meses / Tudo)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: PeriodoGrafico.values.map((periodo) {
                    final isSel = controller.periodoGrafico == periodo;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => controller.mudarPeriodoGrafico(periodo),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.primary.withValues(alpha: 0.16)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: isSel
                                  ? AppColors.primary.withValues(alpha: 0.6)
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              periodo.label,
                              style: TextStyle(
                                color: isSel
                                    ? AppColors.primary
                                    : AppColors.textDimmed,
                                fontSize: 10,
                                fontWeight: isSel
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 22),
              totalPontos < 2
                  ? Container(
                      height: 200,
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.show_chart,
                            size: 44,
                            color: AppColors.textDimmed.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text(
                              'Registre pelo menos 2 treinos deste exercício para visualizar a curva de evolução de carga.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textDimmed,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(right: 12, top: 4),
                      child: SizedBox(
                        height: 205,
                        child: LineChart(
                          LineChartData(
                            lineTouchData: LineTouchData(
                              enabled: true,
                              handleBuiltInTouches: true,
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (_) => AppColors.background,
                                tooltipBorder: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1,
                                ),
                                tooltipBorderRadius: BorderRadius.circular(10),
                                tooltipPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    final idx = spot.x.toInt();
                                    final pesoFormatado =
                                        RecordePessoal.formatarPeso(spot.y);
                                    final reps = (idx >= 0 &&
                                            idx < controller.repsDoGrafico.length)
                                        ? controller.repsDoGrafico[idx]
                                        : null;
                                    final dataCompleta = (idx >= 0 &&
                                            idx <
                                                controller
                                                    .datasCompletasDoGrafico
                                                    .length)
                                        ? controller.datasCompletasDoGrafico[idx]
                                        : '';

                                    final textoCarga = (reps != null && reps > 0)
                                        ? '$pesoFormatado kg × $reps'
                                        : '$pesoFormatado kg';

                                    return LineTooltipItem(
                                      '$textoCarga\n',
                                      const TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: dataCompleta,
                                          style: const TextStyle(
                                            color: AppColors.textDimmed,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: AppColors.textDimmed.withValues(alpha: 0.1),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 26,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    if (value != value.roundToDouble()) {
                                      return const SizedBox.shrink();
                                    }
                                    final idx = value.toInt();
                                    if (idx < 0 ||
                                        idx >= controller.datasDoGrafico.length ||
                                        !indicesVisiveisX.contains(idx)) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        controller.datasDoGrafico[idx],
                                        style: const TextStyle(
                                          color: AppColors.textDimmed,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '${value.toInt()}kg',
                                      style: const TextStyle(
                                        color: AppColors.textDimmed,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: controller.pontosDoGraficoFiltrado,
                                isCurved: true,
                                preventCurveOverShooting: true,
                                color: AppColors.primary,
                                barWidth: 3.5,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: totalPontos > 18 ? 2.8 : 3.8,
                                      color: AppColors.primary,
                                      strokeWidth: 1.5,
                                      strokeColor: AppColors.background,
                                    );
                                  },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}

class _ModalFiltroExercicioGrafico extends StatefulWidget {
  final ProgressoController controller;

  const _ModalFiltroExercicioGrafico({required this.controller});

  @override
  State<_ModalFiltroExercicioGrafico> createState() => _ModalFiltroExercicioGraficoState();
}

class _ModalFiltroExercicioGraficoState extends State<_ModalFiltroExercicioGrafico> {
  String _termoBusca = '';
  String _grupoSelecionado = 'TODOS';

  static const List<String> _gruposFiltro = [
    'TODOS',
    'PEITO',
    'COSTAS',
    'PERNAS',
    'OMBROS',
    'BÍCEPS',
    'TRÍCEPS',
    'ABDÔMEN',
  ];

  String _normalizar(String valor) {
    return valor
        .trim()
        .toUpperCase()
        .replaceAll('Í', 'I')
        .replaceAll('Ô', 'O')
        .replaceAll('Ã', 'A')
        .replaceAll('É', 'E');
  }

  List<String> get _exerciciosFiltrados {
    final termo = _termoBusca.trim().toLowerCase();
    final disponiveis = widget.controller.exerciciosDisponiveis
        .where((e) => e != 'Nenhum exercício')
        .toList();

    return disponiveis.where((nome) {
      final grupo = widget.controller.gruposExercicios[nome] ?? '';
      final atendeGrupo = _grupoSelecionado == 'TODOS' ||
          _normalizar(grupo) == _normalizar(_grupoSelecionado);
      if (!atendeGrupo) return false;

      if (termo.isEmpty) return true;
      return nome.toLowerCase().contains(termo) || grupo.toLowerCase().contains(termo);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'FILTRAR EXERCÍCIO',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textDimmed),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (valor) {
                setState(() {
                  _termoBusca = valor;
                });
              },
              style: const TextStyle(color: AppColors.textLight),
              decoration: InputDecoration(
                hintText: 'Buscar exercício...',
                hintStyle: const TextStyle(color: AppColors.textDimmed),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _gruposFiltro.map((grupo) {
                  final bool isSelecionado = _grupoSelecionado == grupo;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _grupoSelecionado = grupo;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelecionado ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelecionado ? AppColors.primary : AppColors.cardBorder,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          grupo,
                          style: TextStyle(
                            color: isSelecionado ? AppColors.background : AppColors.textLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: _exerciciosFiltrados.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'Nenhum exercício encontrado',
                          style: TextStyle(color: AppColors.textDimmed),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _exerciciosFiltrados.length,
                      separatorBuilder: (context, index) => const Divider(color: AppColors.background),
                      itemBuilder: (context, index) {
                        final nome = _exerciciosFiltrados[index];
                        final grupo = widget.controller.gruposExercicios[nome] ?? '';
                        final isSelecionadoAtual = widget.controller.exercicioFiltro == nome;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          leading: ExercicioThumbnailWidget(
                            nomeExercicio: nome,
                            grupo: grupo,
                            size: 38,
                            borderRadius: 10,
                            abrirModalAoTocar: true,
                            exibirIndicadorGif: false,
                          ),
                          title: Text(
                            nome,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelecionadoAtual ? AppColors.accent : AppColors.textLight,
                            ),
                          ),
                          subtitle: grupo.isNotEmpty
                              ? Text(grupo, style: const TextStyle(color: AppColors.primary, fontSize: 12))
                              : null,
                          trailing: isSelecionadoAtual
                              ? const Icon(Icons.check_circle, color: AppColors.accent, size: 20)
                              : const Icon(Icons.arrow_forward_ios, color: AppColors.textDimmed, size: 14),
                          onTap: () {
                            widget.controller.mudarExercicioFiltro(nome);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
