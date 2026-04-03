import 'package:flutter/material.dart';
import '../controllers/historico_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/historico_card_widget.dart';

class HistoricoScreen extends StatefulWidget {
  final HistoricoController controller;
  final VoidCallback? onHistoricoAtualizado;

  const HistoricoScreen({super.key, required this.controller, this.onHistoricoAtualizado});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  late final HistoricoController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.carregarHistorico();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> _confirmarExclusaoSessao() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir Treino?'),
          content: const Text(
            'Tem certeza que deseja apagar permanentemente este treino? Todo o progresso registrado nesta sessão será perdido.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir', style: TextStyle(color: Color(0xFFB71C1C))),
            ),
          ],
        );
      },
    );

    return confirmado == true;
  }

  Future<void> _onExcluirSessao(HistoricoDia diaTreino) async {
    final sessaoId = diaTreino.sessao.id;
    if (sessaoId == null) return;

    final confirmado = await _confirmarExclusaoSessao();
    if (!confirmado) return;

    await _controller.excluirSessao(sessaoId);
    widget.onHistoricoAtualizado?.call();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Treino excluido com sucesso.')),
    );
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        diaTreino.dataLabel,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _onExcluirSessao(diaTreino),
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.grey[600],
                      tooltip: 'Excluir treino',
                    ),
                  ],
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