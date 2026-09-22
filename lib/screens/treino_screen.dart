import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../theme/app_colors.dart';
import '../controllers/treino_controller.dart';
import '../models/exercicio.dart';
import '../models/ficha_treino.dart';
import '../models/serie.dart';
import '../controllers/progresso_controller.dart';
import '../widgets/celebracao_transformacao_modal.dart';
import '../widgets/config_tempo_descanso_modal.dart';
import '../widgets/cronometro_widget.dart';
import '../widgets/compartilhar_card_modal.dart';
import '../widgets/gerenciar_fichas_modal.dart';
import '../widgets/modal_encerrar_treino.dart';
import '../widgets/selecao_exercicio_modal.dart';
import '../widgets/serie_row_widget.dart';

class TreinoScreen extends StatefulWidget {
  final VoidCallback onEncerrarTreino;
  final TreinoController controller;
  final ProgressoController? progressoController;

  const TreinoScreen({
    super.key,
    required this.onEncerrarTreino,
    required this.controller,
    this.progressoController,
  });

  @override
  State<TreinoScreen> createState() => _TreinoScreenState();
}

class _TreinoScreenState extends State<TreinoScreen> {
  late final TreinoController _controller;
  int _ultimoEventoDescanso = 0;
  bool _proximosFichaExpandido = false;

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
      FlutterRingtonePlayer().playNotification(asAlarm: true);
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.timer, color: AppColors.accent, size: 28),
              SizedBox(width: 8),
              Text(
                'DESCANSO FINALIZADO!',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'BORA!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
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
        return ConfigTempoDescansoModal(controller: _controller);
      },
    );
  }

  void _abrirListaExercicios() {
    showDialog(
      context: context,
      builder: (context) {
        return SelecaoExercicioModal(
          controller: _controller,
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

  void _abrirGerenciarFichas() {
    showDialog(
      context: context,
      builder: (context) => GerenciarFichasModal(controller: _controller),
    );
  }

  Future<void> _tocarIniciarExercicioPendente(int index, FichaExercicioItem item) async {
    final atual = _controller.exercicioAtual;
    if (atual != null) {
      final temSerieFeita = atual.seriesDetalhes
          .any((s) => s.concluida || (s.peso != null && s.reps != null));
      if (temSerieFeita) {
        final bool? salvarAtual = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            title: const Text('Exercício em andamento', style: TextStyle(color: AppColors.textLight)),
            content: Text(
              'Você tem séries em "${atual.nome}". Deseja salvá-lo antes de iniciar "${item.nome}"?',
              style: const TextStyle(color: AppColors.textDimmed),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancelar', style: TextStyle(color: AppColors.textDimmed)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Descartar atual', style: TextStyle(color: AppColors.danger)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                ),
                child: const Text('Salvar e Iniciar'),
              ),
            ],
          ),
        );

        if (salvarAtual == null) return;
        if (salvarAtual == true) {
          final erro = _controller.finalizarExercicioAtual();
          if (erro != null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(erro), backgroundColor: AppColors.danger),
            );
            return;
          }
        }
      }
    }

    _controller.iniciarExercicioPendente(index);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Iniciando ${item.nome}!')),
    );
  }

  void _substituirExercicioAtual() {
    final atual = _controller.exercicioAtual;
    if (atual == null) return;
    showDialog(
      context: context,
      builder: (context) => SelecaoExercicioModal(
        controller: _controller,
        onSelecionarExercicio: (nome, grupo) {
          _controller.substituirExercicioAtual(nome, grupo);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Exercício substituído por $nome!')),
          );
        },
      ),
    );
  }

  void _substituirExercicioPendente(int index) {
    showDialog(
      context: context,
      builder: (context) => SelecaoExercicioModal(
        controller: _controller,
        onSelecionarExercicio: (nome, grupo) {
          _controller.substituirExercicioPendente(index, nome, grupo);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Exercício da ficha substituído por $nome!')),
          );
        },
      ),
    );
  }

  Future<bool> _confirmarRemocaoExercicio(Exercicio exercicio) async {
    final confirmarRemocao = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Remover Exercício?'),
          content: Text(
            'Tem certeza que deseja remover ${exercicio.nome} do treino atual?',
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

    if (confirmarRemocao != true) return false;

    _controller.removerExercicio(exercicio);
    if (!mounted) return true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${exercicio.nome} removido do treino atual.'),
        duration: const Duration(seconds: 2),
      ),
    );

    return true;
  }

  Future<void> _confirmarEncerramentoTreino() async {
    final resultado = await showDialog<ResultadoEncerrarTreino>(
      context: context,
      builder: (context) => ModalEncerrarTreinoDialog(
        controller: _controller,
        progressoController: widget.progressoController,
      ),
    );

    if (resultado == null) return;

    try {
      if (resultado.nomeTreino != null && resultado.nomeTreino!.trim().isNotEmpty) {
        _controller.definirNomeTreino(resultado.nomeTreino!.trim());
      }

      final transAntes = widget.progressoController?.poderLuta.transformacao;

      final sessaoSalva = await _controller.encerrarTreino(
        descartarAtual: resultado.descartarAtual,
      );

      if (resultado.salvarComoFicha &&
          resultado.nomeFicha != null &&
          resultado.nomeFicha!.trim().isNotEmpty) {
        await _controller.salvarTreinoAtualComoFicha(resultado.nomeFicha!.trim());
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Treino salvo com sucesso!')),
      );
      widget.onEncerrarTreino();

      if (widget.progressoController != null) {
        await widget.progressoController!.carregarDados();
      }

      final transDepois = widget.progressoController?.poderLuta.transformacao;
      if (transDepois != null && transAntes != null && transDepois.index > transAntes.index) {
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => CelebracaoTransformacaoModal(novaTransformacao: transDepois),
          );
        }
      }

      if (sessaoSalva != null && mounted) {
        showDialog(
          context: context,
          builder: (context) => CompartilharCardModal(
            sessao: sessaoSalva,
            progressoController: widget.progressoController,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao salvar treino. Tente novamente.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Widget _buildBarraTempoTreino() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Duração do Treino
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TEMPO TOTAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDimmed,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        _controller.duracaoTreinoFormatada,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_controller.isTreinoEmAndamento)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _controller.isTreinoPausado ? Icons.play_arrow : Icons.pause,
                      size: 20,
                      color: _controller.isTreinoPausado ? AppColors.accent : AppColors.textDimmed,
                    ),
                    onPressed: _controller.alternarPausaTreinoGeral,
                    tooltip: _controller.isTreinoPausado ? 'Retomar treino' : 'Pausar treino',
                  ),
              ],
            ),
          ),
          Container(width: 1, height: 28, color: AppColors.cardBorder, margin: const EdgeInsets.symmetric(horizontal: 12)),
          // Descanso Acumulado
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.pause_circle_outline, size: 20, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DESCANSO TOTAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDimmed,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        _controller.descansoTotalFormatado,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                _buildBarraTempoTreino(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: _selecionarDataSessao,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _controller.dataSessaoFormatada,
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_drop_down,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_controller.nomeTreino != null)
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bookmark_outline, size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _controller.nomeTreino!,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_controller.exercicioAtual != null ||
                        _controller.exerciciosConcluidosHoje.isNotEmpty ||
                        _controller.exerciciosFichaPendentes.isNotEmpty)
                      InkWell(
                        onTap: _abrirGerenciarFichas,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 16,
                                color: AppColors.accent,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'FICHAS',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_controller.exerciciosConcluidosHoje.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'JÁ REALIZADOS:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDimmed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._controller.exerciciosConcluidosHoje.asMap().entries.map(
                    (entry) => _buildCardLogExercicio(entry.value, entry.key),
                  ),
                  const SizedBox(height: 32),
                ],
                if (_controller.exerciciosFichaPendentes.isNotEmpty)
                  _buildSecaoExerciciosFichaPendentes(),
                if (_controller.exercicioAtual == null)
                  _buildTelaLimpa()
                else
                  _buildExercicioAtual(),
                const SizedBox(height: 48),
                if (_controller.exerciciosConcluidosHoje.isNotEmpty ||
                    _controller.exercicioAtual != null) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _confirmarEncerramentoTreino,
                      icon: const Icon(Icons.sports_score, size: 20),
                      label: Text(
                        textoEncerrarTreino,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: AppColors.textLight,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecaoExerciciosFichaPendentes() {
    final pendentes = _controller.exerciciosFichaPendentes;
    if (pendentes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _proximosFichaExpandido = !_proximosFichaExpandido),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _proximosFichaExpandido
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.cardBorder,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.playlist_play, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'PRÓXIMOS DA FICHA (${pendentes.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  _proximosFichaExpandido ? 'Ocultar' : 'Ver lista',
                  style: TextStyle(
                    color: _proximosFichaExpandido ? AppColors.primary : AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _proximosFichaExpandido ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: _proximosFichaExpandido ? AppColors.primary : AppColors.accent,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_proximosFichaExpandido) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Toque para iniciar • Arraste para reordenar',
                  style: TextStyle(color: AppColors.textDimmed, fontSize: 11),
                ),
                Text(
                  'Aparelho ocupado? Troque',
                  style: TextStyle(color: AppColors.textDimmed.withValues(alpha: 0.7), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: pendentes.length,
            onReorder: (oldIndex, newIndex) {
              _controller.reordenarExerciciosPendentes(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final item = pendentes[index];
              return Container(
                key: ValueKey('${item.nome}_${item.grupo}_$index'),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _tocarIniciarExercicioPendente(index, item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              child: Icon(
                                Icons.drag_indicator,
                                size: 18,
                                color: AppColors.textDimmed,
                              ),
                            ),
                          ),
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.background,
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.nome,
                                  style: const TextStyle(
                                    color: AppColors.textLight,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${item.grupo} • ${item.seriesPadrao} séries sugeridas',
                                  style: const TextStyle(color: AppColors.textDimmed, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.play_arrow_rounded, size: 22, color: AppColors.accent),
                            tooltip: 'Iniciar este exercício agora',
                            onPressed: () => _tocarIniciarExercicioPendente(index, item),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.swap_horiz, size: 20, color: AppColors.primary),
                            tooltip: 'Substituir exercício',
                            onPressed: () => _substituirExercicioPendente(index),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.close, size: 18, color: AppColors.textDimmed),
                            tooltip: 'Remover do treino de hoje',
                            onPressed: () {
                              _controller.removerExercicioPendente(index);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${item.nome} removido do treino de hoje.')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTelaLimpa() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surface, width: 2),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.fitness_center,
            size: 64,
            color: AppColors.textDimmed,
          ),
          const SizedBox(height: 16),
          const Text(
            'PRONTO PARA DESTRUIR?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
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
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _abrirListaExercicios,
              icon: const Icon(Icons.add, size: 22),
              label: const Text(
                'INICIAR TREINO LIVRE',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _abrirGerenciarFichas,
              icon: const Icon(Icons.assignment, size: 20, color: AppColors.primary),
              label: const Text(
                'CARREGAR FICHA DE TREINO',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 1.0,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
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
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: Column(
                children: [
                  Text(
                    exercicioAtual.nome,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: AppColors.textLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      exercicioAtual.grupo.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textDimmed),
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
                tooltip: 'Opções do exercício',
                onSelected: (value) {
                  if (value == 'trocar') {
                    _substituirExercicioAtual();
                  } else if (value == 'excluir') {
                    _confirmarRemocaoExercicio(exercicioAtual);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'trocar',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz, size: 18, color: AppColors.accent),
                        SizedBox(width: 10),
                        Text(
                          'Trocar exercício',
                          style: TextStyle(color: AppColors.textLight, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'excluir',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                        SizedBox(width: 10),
                        Text(
                          'Remover do treino',
                          style: TextStyle(color: AppColors.danger, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'SÉRIES',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: exercicioAtual.seriesDetalhes.length,
          itemBuilder: (context, index) {
            return SerieRowWidget(index: index, controller: _controller);
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _controller.adicionarSerie,
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'ADICIONAR NOVA SÉRIE',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                    content: Text(
                      erro,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: const Text(
              'FINALIZAR EXERCÍCIO',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardLogExercicio(Exercicio exercicio, int index) {
    final List<Serie> detalhes = exercicio.seriesDetalhes;

    return Dismissible(
      key: ValueKey('${exercicio.nome}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmarRemocaoExercicio(exercicio),
      child: Container(
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
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exercicio.nome,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 28),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      exercicio.grupo,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${detalhes.length} SÉRIES',
                    style: const TextStyle(
                      color: AppColors.textDimmed,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
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
                          Text(
                            'Série $serieIndex',
                            style: const TextStyle(
                              color: AppColors.textDimmed,
                              fontSize: 14,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${serieData.reps ?? '-'} reps',
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '${serieData.peso ?? '-'} kg',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
