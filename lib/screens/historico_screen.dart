import 'package:flutter/material.dart';
import '../controllers/historico_controller.dart';
import '../models/sessao_treino.dart';
import '../theme/app_colors.dart';
import '../widgets/compartilhar_card_modal.dart';
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

  void _abrirCompartilharCard(SessaoTreino sessao) {
    showDialog(
      context: context,
      builder: (context) => CompartilharCardModal(sessao: sessao),
    );
  }

  Future<void> _exportarBackup() async {
    final res = await _controller.exportarBackup();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.mensagem),
        backgroundColor: res.sucesso ? AppColors.surface : AppColors.danger,
      ),
    );
  }

  Future<void> _importarBackup() async {
    final escolha = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: const Text(
          'Importar Backup',
          style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Como deseja importar os treinos do arquivo de backup?',
          style: TextStyle(color: AppColors.textDimmed),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textDimmed)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'substituir'),
            child: const Text('Substituir Tudo', style: TextStyle(color: AppColors.danger)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'mesclar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
            ),
            child: const Text('Mesclar Dados', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (escolha == null) return;
    final mesclar = escolha == 'mesclar';
    final res = await _controller.importarBackup(mesclar: mesclar);
    if (!mounted) return;
    widget.onHistoricoAtualizado?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.mensagem),
        backgroundColor: res.sucesso ? AppColors.surface : AppColors.danger,
      ),
    );
  }

  Future<bool> _confirmarExclusaoSessao() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: const Text(
            'Excluir Treino?',
            style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Tem certeza que deseja apagar permanentemente este treino? Todo o progresso registrado nesta sessão será perdido.',
            style: TextStyle(color: AppColors.textDimmed),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textDimmed)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
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
      const SnackBar(content: Text('Treino excluído com sucesso.')),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fitness_center,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'NENHUM TREINO REGISTRADO AINDA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'O caminho de um guerreiro começa com o primeiro ferro levantado. Vá para a aba Treino e inicie sua jornada!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textDimmed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final historico = _controller.historicoTreinos;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HISTÓRICO',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'TODOS OS SEUS TREINOS',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textDimmed,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    if (_controller.isProcessandoBackup)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    else
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: AppColors.primary),
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.cardBorder),
                        ),
                        onSelected: (val) {
                          if (val == 'exportar') _exportarBackup();
                          if (val == 'importar') _importarBackup();
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'exportar',
                            child: Row(
                              children: [
                                Icon(Icons.file_upload_outlined, color: AppColors.primary, size: 20),
                                SizedBox(width: 10),
                                Text('Exportar Backup (JSON)', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'importar',
                            child: Row(
                              children: [
                                Icon(Icons.file_download_outlined, color: AppColors.accent, size: 20),
                                SizedBox(width: 10),
                                Text('Importar Backup (JSON)', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: historico.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: historico.length,
                          itemBuilder: (context, index) {
                            final diaTreino = historico[index];
                            final isUltimo = index == historico.length - 1;
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

    int totalSeries = 0;
    double volumeTotal = 0.0;
    bool temSerieConcluida = false;

    for (final ex in exercicios) {
      totalSeries += ex.seriesDetalhes.length;
      for (final serie in ex.seriesDetalhes) {
        if (serie.concluida) {
          temSerieConcluida = true;
          final reps = serie.reps ?? 0;
          final peso = serie.peso ?? 0.0;
          volumeTotal += reps * peso;
        }
      }
    }

    if (!temSerieConcluida) {
      for (final ex in exercicios) {
        for (final serie in ex.seriesDetalhes) {
          final reps = serie.reps ?? 0;
          final peso = serie.peso ?? 0.0;
          if (reps > 0 && peso > 0) {
            volumeTotal += reps * peso;
          }
        }
      }
    }

    final volumeFormatado = volumeTotal % 1 == 0
        ? '${volumeTotal.toInt()} kg'
        : '${volumeTotal.toStringAsFixed(1)} kg';

    return Stack(
      children: [
        // Linha vertical da timeline que conecta ao próximo nó
        Positioned(
          left: 17, // Centralizada com a bolinha de 36px ((36 - 2) / 2 = 17)
          top: 18, // Começa no centro do nó do calendário
          bottom: isUltimo ? 18 : 0,
          child: Container(
            width: 2,
            color: AppColors.primary,
          ),
        ),
        // Conteúdo da sessão
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha com o nó do calendário, data e botões de ação (compartilhar e excluir)
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    color: AppColors.background,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    diaTreino.dataLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _abrirCompartilharCard(diaTreino.sessao),
                  icon: const Icon(Icons.share_outlined, size: 20),
                  color: AppColors.primary,
                  tooltip: 'Compartilhar card',
                ),
                IconButton(
                  onPressed: () => _onExcluirSessao(diaTreino),
                  icon: const Icon(Icons.delete_outline, size: 22),
                  color: AppColors.textDimmed,
                  tooltip: 'Excluir treino',
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Subtítulo com métricas resumidas do treino (exercícios, séries, volume, duração e descanso)
            Padding(
              padding: const EdgeInsets.only(left: 50.0, bottom: 12.0),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    '${exercicios.length} EXERCÍCIOS',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDimmed,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  Text(
                    '$totalSeries SÉRIES',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDimmed,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  Text(
                    'VOLUME: $volumeFormatado',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (diaTreino.sessao.duracaoSegundos > 0) ...[
                    const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: AppColors.textDimmed),
                        const SizedBox(width: 3),
                        Text(
                          diaTreino.sessao.duracaoFormatada,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDimmed,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (diaTreino.sessao.descansoTotalSegundos > 0) ...[
                    const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pause_circle_outline, size: 14, color: AppColors.textDimmed),
                        const SizedBox(width: 3),
                        Text(
                          diaTreino.sessao.descansoFormatado,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDimmed,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Cards dos exercícios da sessão
            Padding(
              padding: const EdgeInsets.only(left: 50.0, bottom: 28.0),
              child: Column(
                children: exercicios.map((ex) => HistoricoCardWidget(exercicio: ex)).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}