import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';

class ProgressoScreen extends StatefulWidget {
  const ProgressoScreen({super.key});

  @override
  State<ProgressoScreen> createState() => _ProgressoScreenState();
}

class _ProgressoScreenState extends State<ProgressoScreen> {
  // --- ESTADO FÍSICO ---
  double pesoAtual = 69.0;
  double altura = 1.70;
  int diasTreinadosNaSemana = 2;
  int metaDiasSemana = 3;

  // --- ESTADO DO GRÁFICO ---
  String exercicioFiltro = 'SUPINO RETO';
  final List<String> exerciciosDisponiveis = ['SUPINO RETO', 'AGACHAMENTO', 'REMADA CURVADA'];
  
  // Dados mockados simulando o banco de dados para diferentes exercícios
  final Map<String, List<FlSpot>> historicoGrafico = {
    'SUPINO RETO': [const FlSpot(0, 50), const FlSpot(1, 60), const FlSpot(2, 64)],
    'AGACHAMENTO': [const FlSpot(0, 70), const FlSpot(1, 80), const FlSpot(2, 84)],
    'REMADA CURVADA': [const FlSpot(0, 40), const FlSpot(1, 45), const FlSpot(2, 50)],
  };

  double calcularIMC() {
    return pesoAtual / (altura * altura);
  }

  // --- MODAL DE MEDIDAS ---
  void _abrirModalAtualizarMedidas() {
    final pesoController = TextEditingController(text: pesoAtual.toString());
    final alturaController = TextEditingController(text: altura.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('ATUALIZAR MEDIDAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pesoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Peso (kg)',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: alturaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Altura (m)',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
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
                setState(() {
                  pesoAtual = double.tryParse(pesoController.text.replaceAll(',', '.')) ?? pesoAtual;
                  altura = double.tryParse(alturaController.text.replaceAll(',', '.')) ?? altura;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.background),
              child: const Text('SALVAR', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _abrirModalAtualizarMeta() {
    int metaTemporaria = metaDiasSemana;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Center(
                child: Text('META SEMANAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Quantos dias você quer treinar?',
                    style: TextStyle(color: AppColors.textDimmed, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (metaTemporaria > 1) setStateModal(() => metaTemporaria--);
                        },
                        icon: const Icon(Icons.remove_circle_outline, size: 32, color: AppColors.primary),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        '$metaTemporaria',
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.accent),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        onPressed: () {
                          if (metaTemporaria < 7) setStateModal(() => metaTemporaria++);
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 32, color: AppColors.primary),
                      ),
                    ],
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
                    setState(() => metaDiasSemana = metaTemporaria);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                  ),
                  child: const Text('SALVAR', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
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

            Row(
              children: [
                Expanded(child: _buildMetaCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildIMCCard(imc)),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildChartSection(),
            
            const SizedBox(height: 24),
            _buildPesoCorporalCard(),
          ],
        ),
      ),
    );
  }

  // ... (Mantenha _buildMetaCard e _buildIMCCard iguais ao que você já tinha)
  Widget _buildMetaCard() {
    return GestureDetector(
      onTap: _abrirModalAtualizarMeta, // <--- Chama o modal ao tocar no card
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface, 
          borderRadius: BorderRadius.circular(16)
        ),
        child: Stack(
          children: [
            // Ícone de edição no canto superior direito
            const Align(
              alignment: Alignment.topRight,
              child: Icon(Icons.edit, color: AppColors.textDimmed, size: 16),
            ),
            // Conteúdo principal
            Column(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.primary, size: 30),
                const SizedBox(height: 12),
                const Text('META SEMANAL', style: TextStyle(fontSize: 10, color: AppColors.textDimmed)),
                Text(
                  '$diasTreinadosNaSemana / $metaDiasSemana', 
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.accent)
                ),
                const Text('DIAS ATIVOS', style: TextStyle(fontSize: 10, color: AppColors.textDimmed)),
              ],
            ),
          ],
        ),
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

  // --- SEÇÃO DO GRÁFICO ATUALIZADA COM FILTRO ---
  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PROGRESSÃO DE CARGA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Icon(Icons.filter_list, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          
          // O Dropdown de Filtro
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: DropdownButton<String>(
              value: exercicioFiltro,
              dropdownColor: AppColors.surface,
              isExpanded: true,
              underline: const SizedBox(), // Remove a linha feia padrão do dropdown
              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
              items: exerciciosDisponiveis.map((ex) => DropdownMenuItem(value: ex, child: Text(ex))).toList(),
              onChanged: (novoExercicio) {
                if (novoExercicio != null) {
                  setState(() => exercicioFiltro = novoExercicio);
                }
              },
            ),
          ),
          
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
                    spots: historicoGrafico[exercicioFiltro] ?? [], // Puxa os dados baseados no filtro!
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.15),
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

  // --- CARD DE PESO COM BOTÃO DE EDITAR ---
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
          Row(
            children: [
              Text('${pesoAtual.toStringAsFixed(1)} kg', 
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.accent)),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.textDimmed, size: 20),
                onPressed: _abrirModalAtualizarMedidas, // Abre o modal
              )
            ],
          ),
        ],
      ),
    );
  }
}