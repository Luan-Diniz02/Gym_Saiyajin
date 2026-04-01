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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PROGRESSÃO DE CARGA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Icon(Icons.filter_list, color: AppColors.primary, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                child: DropdownButton<String>(
                  value: controller.exercicioFiltro,
                  dropdownColor: AppColors.surface,
                  isExpanded: true,
                  underline: const SizedBox(),
                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
                  items: controller.exerciciosDisponiveis
                      .map((ex) => DropdownMenuItem(value: ex, child: Text(ex)))
                      .toList(),
                  onChanged: (novoExercicio) {
                    if (novoExercicio != null) {
                      controller.mudarExercicioFiltro(novoExercicio);
                    }
                  },
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
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
                                  style: const TextStyle(color: AppColors.textDimmed, fontSize: 10, fontWeight: FontWeight.bold),
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
                              style: const TextStyle(color: AppColors.textDimmed, fontSize: 10, fontWeight: FontWeight.bold),
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
