import 'package:flutter/material.dart';
import '../controllers/historico_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/historico_card_widget.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  late final HistoricoController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HistoricoController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text(
                  'HISTÓRICO',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
                const SizedBox(height: 4),
                const Text(
                  'TODOS OS SEUS TREINOS',
                  style: TextStyle(fontSize: 12, color: AppColors.textDimmed, letterSpacing: 1.2),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView.builder(
                    itemCount: _controller.historicoTreinos.length,
                    itemBuilder: (context, index) {
                      final diaTreino = _controller.historicoTreinos[index];
                      final isUltimo = index == _controller.historicoTreinos.length - 1;
                      return _buildTimelineItem(diaTreino, isUltimo);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineItem(HistoricoDia diaTreino, bool isUltimo) {
    final exercicios = diaTreino.sessao.exerciciosConcluidosHoje;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.calendar_month, color: AppColors.background, size: 20),
              ),
              if (!isUltimo)
                Expanded(child: Container(width: 2, color: AppColors.primary.withValues(alpha: 0.5))),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diaTreino.dataLabel,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight),
                ),
                Text(
                  '${exercicios.length} EXERCÍCIOS',
                  style: const TextStyle(fontSize: 12, color: AppColors.textDimmed),
                ),
                const SizedBox(height: 12),
                ...exercicios.map((exercicio) => HistoricoCardWidget(exercicio: exercicio)),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}