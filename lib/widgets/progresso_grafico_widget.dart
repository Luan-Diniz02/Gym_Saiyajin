import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../controllers/progresso_controller.dart';
import '../theme/app_colors.dart';

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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          controller.exercicioFiltro,
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
              const SizedBox(height: 28),
              controller.pontosDoGraficoFiltrado.length < 2
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
                  : SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
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
                                reservedSize: 24,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 && value.toInt() < controller.datasDoGrafico.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        controller.datasDoGrafico[value.toInt()],
                                        style: const TextStyle(
                                          color: AppColors.textDimmed,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 36,
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
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: controller.pontosDoGraficoFiltrado,
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 4,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.primary.withValues(alpha: 0.15),
                              ),
                            ),
                          ],
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
