import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';

class ProgressoScreen extends StatefulWidget {
  const ProgressoScreen({super.key});

  @override
  State<ProgressoScreen> createState() => _ProgressoScreenState();
}

class _ProgressoScreenState extends State<ProgressoScreen> {
  // Dados para o IMC e Meta
  double pesoAtual = 69.0;
  double altura = 1.70;
  int diasTreinadosNaSemana = 2;
  int metaDiasSemana = 3;

  // Mock de dados para o gráfico (Data vs Carga Máxima no Supino)
  final List<FlSpot> dadosGrafico = [
    const FlSpot(0, 50), // 08/11
    const FlSpot(1, 60), // 09/11
    const FlSpot(2, 64), // 10/11
  ];

  double calcularIMC() {
    return pesoAtual / (altura * altura);
  }

  @override
  Widget build(BuildContext context) {
    double imc = calcularIMC();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'SEU PROGRESSO',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
            const SizedBox(height: 30),

            // --- BLOCO 1: META SEMANAL E IMC ---
            Row(
              children: [
                Expanded(child: _buildMetaCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildIMCCard(imc)),
              ],
            ),
            const SizedBox(height: 24),

            // --- BLOCO 2: GRÁFICO DE CARGA ---
            _buildChartSection(),
            
            const SizedBox(height: 24),
            
            // --- BLOCO 3: PESO CORPORAL ---
            _buildPesoCorporalCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Icon(Icons.calendar_today, color: AppColors.primary, size: 30),
          const SizedBox(height: 12),
          const Text('META SEMANAL', style: TextStyle(fontSize: 10, color: AppColors.textDimmed)),
          Text('$diasTreinadosNaSemana / $metaDiasSemana', 
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.accent)),
          const Text('DIAS ATIVOS', style: TextStyle(fontSize: 10, color: AppColors.textDimmed)),
        ],
      ),
    );
  }

  Widget _buildIMCCard(double imc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Icon(Icons.monitor_weight, color: AppColors.primary, size: 30),
          const SizedBox(height: 12),
          const Text('MEU IMC', style: TextStyle(fontSize: 10, color: AppColors.textDimmed)),
          Text(imc.toStringAsFixed(1), 
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.accent)),
          Text(imc < 25 ? 'PESO NORMAL' : 'SOBREPESO', 
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PROGRESSÃO DE CARGA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('SUPINO RETO (KG)', style: TextStyle(fontSize: 12, color: AppColors.textDimmed)),
          const SizedBox(height: 30),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: dadosGrafico,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.15), // Efeito de aura/glow
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPesoCorporalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PESO ATUAL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text('Última atualização: Hoje', style: TextStyle(fontSize: 12, color: AppColors.textDimmed)),
            ],
          ),
          Text('$pesoAtual kg', 
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.accent)),
        ],
      ),
    );
  }
}