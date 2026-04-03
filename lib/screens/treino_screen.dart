import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../theme/app_colors.dart';
import '../controllers/treino_controller.dart';
import '../models/exercicio.dart';
import '../models/serie.dart';
import '../widgets/config_tempo_descanso_modal.dart';
import '../widgets/cronometro_widget.dart';
import '../widgets/selecao_exercicio_modal.dart';
import '../widgets/serie_row_widget.dart';

class TreinoScreen extends StatefulWidget {
  final VoidCallback onEncerrarTreino;
  final TreinoController controller;

  const TreinoScreen({super.key, required this.onEncerrarTreino, required this.controller});

  @override
  State<TreinoScreen> createState() => _TreinoScreenState();
}

class _TreinoScreenState extends State<TreinoScreen> {
  late final TreinoController _controller;
  int _ultimoEventoDescanso = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (!mounted) return;

    if (_controller.descansoFinalizadoEvento != _ultimoEventoDescanso) {
      _ultimoEventoDescanso = _controller.descansoFinalizadoEvento;
      _dispararVibracao(1000, 128);
      _mostrarDialogoDescansoFinalizado();
    }
  }

  Future<void> _dispararVibracao(int duration, int amplitude) async {
    final hasVibrator = await Vibration.hasVibrator();
    if (!hasVibrator) {
      await HapticFeedback.heavyImpact();
      return;
    }

    final hasAmplitudeControl = await Vibration.hasAmplitudeControl();
    if (hasAmplitudeControl) {
      await Vibration.vibrate(duration: duration, amplitude: amplitude);
      return;
    }

    await Vibration.vibrate(duration: duration);
  }

  void _mostrarDialogoDescansoFinalizado() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.timer, color: AppColors.accent, size: 28),
              SizedBox(width: 8),
              Text('DESCANSO FINALIZADO!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Hora de voltar pro ferro. Prepare-se para a próxima série!',
            style: TextStyle(color: AppColors.textLight),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('BORA!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _abrirConfigTempoDescanso() {
    showDialog(
      context: context,
      builder: (context) {
        return ConfigTempoDescansoModal(
          controller: _controller,
        );
      },
    );
  }

  void _abrirListaExercicios() {
    showDialog(
      context: context,
      builder: (context) {
        return SelecaoExercicioModal(
          onSelecionarExercicio: (nome, grupo) {
            _controller.iniciarNovoExercicio(nome, grupo);
          },
        );
      },
    );
  }

  Future<void> _selecionarDataSessao() async {
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _controller.dataSessao,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (dataEscolhida != null) {
      _controller.alterarDataSessao(dataEscolhida);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final textoEncerrarTreino = _controller.dataSessaoFormatada == 'Hoje'
          ? 'ENCERRAR TREINO (HOJE)'
          : 'ENCERRAR TREINO (${_controller.dataSessaoFormatada})';

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CronometroWidget(
                  tempoFormatado: _controller.tempoFormatado,
                  tempoAtual: _controller.tempoAtual,
                  tempoDescansoPadrao: _controller.tempoDescansoPadrao,
                  isTimerRodando: _controller.isTimerRodando,
                  onTapConfig: _abrirConfigTempoDescanso,
                  onPausar: _controller.pausarTimer,
                  onReiniciar: _controller.reiniciarTimer,
                  onIniciarOuContinuar: _controller.continuarTimer,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _selecionarDataSessao,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      _controller.dataSessaoFormatada,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (_controller.exerciciosConcluidosHoje.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('JÁ REALIZADOS HOJE:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDimmed)),
                  ),
                  const SizedBox(height: 12),
                  ..._controller.exerciciosConcluidosHoje.map((ex) => _buildCardLogExercicio(ex)),
                  const SizedBox(height: 32),
                ],
                if (_controller.exercicioAtual == null)
                  _buildTelaLimpa()
                else
                  _buildExercicioAtual(),
                const SizedBox(height: 48),
                if (_controller.exerciciosConcluidosHoje.isNotEmpty || _controller.exercicioAtual != null)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await _controller.encerrarTreino();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Treino salvo com sucesso!')),
                          );
                          widget.onEncerrarTreino();
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erro ao salvar treino. Tente novamente.'),
                              backgroundColor: Color(0xFFB71C1C),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.sports_score, size: 20),
                      label: Text(
                        textoEncerrarTreino,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB71C1C),
                        foregroundColor: AppColors.textLight,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTelaLimpa() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surface, width: 2)
      ),
      child: Column(
        children: [
          const Icon(Icons.fitness_center, size: 64, color: AppColors.textDimmed),
          const SizedBox(height: 16),
          const Text(
            'PRONTO PARA DESTRUIR?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textLight),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adicione o seu primeiro exercício do dia para começar a registrar as cargas.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textDimmed),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _abrirListaExercicios,
              icon: const Icon(Icons.add, size: 24),
              label: const Text('INICIAR TREINO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildExercicioAtual() {
    final exercicioAtual = _controller.exercicioAtual;
    if (exercicioAtual == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Text(
          exercicioAtual.nome,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
          child: Text(
            exercicioAtual.grupo,
            style: const TextStyle(color: AppColors.background, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const SizedBox(height: 32),

        const Align(
          alignment: Alignment.centerLeft,
          child: Text('SÉRIES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: exercicioAtual.seriesDetalhes.length,
          itemBuilder: (context, index) {
            return SerieRowWidget(
              index: index,
              controller: _controller,
            );
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _controller.adicionarSerie,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('ADICIONAR NOVA SÉRIE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent, foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              final erro = _controller.finalizarExercicioAtual();
              if (erro != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(erro, style: const TextStyle(color: Colors.white)),
                    backgroundColor: const Color(0xFFB71C1C),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: const Text('FINALIZAR EXERCÍCIO', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardLogExercicio(Exercicio exercicio) {
    final List<Serie> detalhes = exercicio.seriesDetalhes;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textDimmed,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                exercicio.nome,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 28),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text(exercicio.grupo, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Text('${detalhes.length} SÉRIES', style: const TextStyle(color: AppColors.textDimmed, fontSize: 12)),
              ],
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              ),
              child: Column(
                children: detalhes.asMap().entries.map((entry) {
                  int serieIndex = entry.key + 1;
                  final Serie serieData = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Série $serieIndex', style: const TextStyle(color: AppColors.textDimmed, fontSize: 14)),
                        Row(
                          children: [
                            Text('${serieData.reps ?? '-'} reps', style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 16),
                            Text('${serieData.peso ?? '-'} kg', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }

}