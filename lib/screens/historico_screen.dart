import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/historico_controller.dart';
import '../controllers/progresso_controller.dart';
import '../models/sessao_treino.dart';
import '../theme/app_colors.dart';
import '../widgets/caminho_serpente_progress_bar.dart';
import '../widgets/compartilhar_card_modal.dart';
import '../widgets/dragon_ball_icon.dart';
import '../widgets/historico_card_widget.dart';
import '../widgets/modal_editar_sessao.dart';
import '../widgets/modal_importar_backup.dart';

class HistoricoScreen extends StatefulWidget {
  final HistoricoController controller;
  final ProgressoController? progressoController;
  final VoidCallback? onHistoricoAtualizado;

  const HistoricoScreen({
    super.key,
    required this.controller,
    this.progressoController,
    this.onHistoricoAtualizado,
  });

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  late final HistoricoController _controller;
  bool _caminhoSerpenteExpandido = false;
  bool _modoCalendario = false;
  late DateTime _mesCalendario;
  DateTime? _diaSelecionadoCalendario;

  static const List<String> _nomesMeses = [
    'JANEIRO',
    'FEVEREIRO',
    'MARÇO',
    'ABRIL',
    'MAIO',
    'JUNHO',
    'JULHO',
    'AGOSTO',
    'SETEMBRO',
    'OUTUBRO',
    'NOVEMBRO',
    'DEZEMBRO',
  ];

  static const List<String> _diasSemanaLabels = [
    'DOM',
    'SEG',
    'TER',
    'QUA',
    'QUI',
    'SEX',
    'SÁB',
  ];

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    final agora = DateTime.now();
    _mesCalendario = DateTime(agora.year, agora.month, 1);
    _controller.carregarHistorico().then((_) {
      if (!mounted) return;
      _sincronizarSelecaoInicialCalendario();
    });
  }

  void _sincronizarSelecaoInicialCalendario() {
    final sessoes = _controller.sessoesTreino;
    if (sessoes.isNotEmpty && sessoes.first.data != null) {
      final maisRecente = sessoes.first.data!;
      setState(() {
        _mesCalendario = DateTime(maisRecente.year, maisRecente.month, 1);
        _diaSelecionadoCalendario = DateTime(
          maisRecente.year,
          maisRecente.month,
          maisRecente.day,
        );
      });
    }
  }

  void _navegarMesCalendario(int deltaMeses) {
    HapticFeedback.selectionClick();
    final novoMes = DateTime(
      _mesCalendario.year,
      _mesCalendario.month + deltaMeses,
      1,
    );
    final diasTreinados = _controller.obterDiasTreinadosNoMes(
      novoMes.year,
      novoMes.month,
    );
    DateTime? novoDiaSelecionado;
    if (diasTreinados.isNotEmpty) {
      final ultimoDiaComTreino =
          diasTreinados.keys.reduce((a, b) => a > b ? a : b);
      novoDiaSelecionado = DateTime(
        novoMes.year,
        novoMes.month,
        ultimoDiaComTreino,
      );
    }
    setState(() {
      _mesCalendario = novoMes;
      _diaSelecionadoCalendario = novoDiaSelecionado;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _abrirCompartilharCard(SessaoTreino sessao) {
    showDialog(
      context: context,
      builder: (context) => CompartilharCardModal(
        sessao: sessao,
        progressoController: widget.progressoController,
      ),
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
    final escolha = await ModalImportarBackupDialog.show(context);

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
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'EXCLUIR TREINO?',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Tem certeza que deseja apagar permanentemente este treino? Todo o progresso registrado nesta sessão será perdido.',
            style: TextStyle(
              color: AppColors.textDimmed,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.background,
                        foregroundColor: AppColors.textLight,
                        side: const BorderSide(
                          color: AppColors.buttonBorder,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'CANCELAR',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'EXCLUIR',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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

  Future<void> _abrirEditarSessao(HistoricoDia diaTreino) async {
    final sessaoEditada = await showDialog<SessaoTreino>(
      context: context,
      builder: (context) => ModalEditarSessaoDialog(sessao: diaTreino.sessao),
    );

    if (sessaoEditada != null) {
      await _controller.atualizarSessao(sessaoEditada);
      widget.onHistoricoAtualizado?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Treino atualizado com sucesso!')),
      );
    }
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

  String _formatarKm(double km) {
    if (km >= 1000) {
      final partes = km.toStringAsFixed(1).split('.');
      final intPart = partes[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
      return '$intPart,${partes[1]}';
    }
    return km.toStringAsFixed(1).replaceAll('.', ',');
  }

  Widget _itemEstatisticaJornada({
    required IconData icon,
    required String rotulo,
    required String valor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textDimmed),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rotulo,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.textDimmed,
              ),
            ),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCaminhoSerpenteHeader() {
    final progresso = _controller.progressoCaminhoSerpente;
    final kmPercorridos = _controller.distanciaCaminhoSerpenteKm;
    final marco = _controller.marcoCaminhoSerpente;
    final volumeTon = (_controller.volumeTotalGeral / 1000.0);
    final tempoMin = _controller.tempoTotalMinutosGeral;
    final totalTreinos = _controller.historicoTreinos.length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _caminhoSerpenteExpandido = !_caminhoSerpenteExpandido;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.12),
                AppColors.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFF160E05),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '界王',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'CAMINHO DA SERPENTE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: AppColors.textLight,
                                ),
                              ),
                              Text(
                                'Jornada rumo ao Planeta do Sr. Kaioh',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textDimmed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${(progresso * 100).toStringAsFixed(2)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _caminhoSerpenteExpandido
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textDimmed,
                        size: 22,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Barra serpenteada temática SEMPRE VISÍVEL (com onda senoidal e Planeta do Sr. Kaioh)
              CaminhoSerpenteProgressBar(progresso: progresso, height: 52),
              if (_caminhoSerpenteExpandido) ...[
                const SizedBox(height: 12),
                // Distância e Meta
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${_formatarKm(kmPercorridos)} km',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'percorridos',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDimmed,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Meta: 1.000.000 km',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDimmed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Marco / Lore Dragon Ball
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        marco,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                          fontStyle: FontStyle.italic,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: AppColors.cardBorder, height: 1),
                const SizedBox(height: 8),
                // Estatísticas da travessia
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _itemEstatisticaJornada(
                      icon: Icons.fitness_center_rounded,
                      rotulo: 'Carga Total',
                      valor: '${volumeTon.toStringAsFixed(1)} ton',
                    ),
                    _itemEstatisticaJornada(
                      icon: Icons.timer_outlined,
                      rotulo: 'Tempo Total',
                      valor: '${tempoMin ~/ 60}h ${tempoMin % 60}m',
                    ),
                    _itemEstatisticaJornada(
                      icon: Icons.sports_martial_arts_rounded,
                      rotulo: 'Sessões',
                      valor: '$totalTreinos',
                    ),
                  ],
                ),
              ],
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
                const SizedBox(height: 16),
                _buildCaminhoSerpenteHeader(),
                const SizedBox(height: 12),
                _buildSeletorModoVisualizacao(),
                const SizedBox(height: 14),
                Expanded(
                  child: _controller.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : historico.isEmpty
                          ? _buildEmptyState()
                          : _modoCalendario
                              ? _buildCalendarioView()
                              : ListView.builder(
                                  itemCount: historico.length,
                                  itemBuilder: (context, index) {
                                    final diaTreino = historico[index];
                                    final isUltimo =
                                        index == historico.length - 1;
                                    return _buildTimelineItem(
                                      diaTreino,
                                      isUltimo,
                                    );
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

  Widget _buildSeletorModoVisualizacao() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              key: const Key('toggle-modo-lista'),
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (!_modoCalendario) return;
                HapticFeedback.selectionClick();
                setState(() => _modoCalendario = false);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: !_modoCalendario
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.format_list_bulleted_rounded,
                      size: 16,
                      color: !_modoCalendario
                          ? AppColors.background
                          : AppColors.textDimmed,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LISTA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: !_modoCalendario
                            ? AppColors.background
                            : AppColors.textDimmed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              key: const Key('toggle-modo-calendario'),
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_modoCalendario) return;
                HapticFeedback.selectionClick();
                if (_diaSelecionadoCalendario == null) {
                  _sincronizarSelecaoInicialCalendario();
                }
                setState(() => _modoCalendario = true);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _modoCalendario
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 16,
                      color: _modoCalendario
                          ? AppColors.background
                          : AppColors.textDimmed,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CALENDÁRIO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: _modoCalendario
                            ? AppColors.background
                            : AppColors.textDimmed,
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
  }

  Widget _buildCalendarioView() {
    final ano = _mesCalendario.year;
    final mes = _mesCalendario.month;
    final diasTreinados = _controller.obterDiasTreinadosNoMes(ano, mes);
    final sequenciaSemanas = _controller.calcularSequenciaSemanas();
    final diasDescanso = _controller.calcularDiasDescansoNoMes(ano, mes);
    final totalDiasNoMes = DateTime(ano, mes + 1, 0).day;
    final offsetPrimeiroDia = DateTime(ano, mes, 1).weekday % 7; // 0 = Dom .. 6 = Sáb
    final totalCelulas = offsetPrimeiroDia + totalDiasNoMes;
    final agora = DateTime.now();

    final sessoesDiaSelecionado = _diaSelecionadoCalendario != null &&
            _diaSelecionadoCalendario!.year == ano &&
            _diaSelecionadoCalendario!.month == mes
        ? (diasTreinados[_diaSelecionadoCalendario!.day] ??
            const <HistoricoDia>[])
        : const <HistoricoDia>[];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Resumo de Sequência, Treinos no Mês e Descanso
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildItemResumoCalendario(
                  icone: Icons.local_fire_department_rounded,
                  corIcone: AppColors.primary,
                  titulo: 'SEQUÊNCIA',
                  valor: sequenciaSemanas == 1
                      ? '1 SEMANA'
                      : '$sequenciaSemanas SEMANAS',
                ),
              ),
              Container(width: 1, height: 30, color: AppColors.cardBorder),
              Expanded(
                child: _buildItemResumoCalendario(
                  icone: Icons.fitness_center_rounded,
                  corIcone: AppColors.accent,
                  titulo: 'NO MÊS',
                  valor: diasTreinados.length == 1
                      ? '1 DIA'
                      : '${diasTreinados.length} DIAS',
                ),
              ),
              Container(width: 1, height: 30, color: AppColors.cardBorder),
              Expanded(
                child: _buildItemResumoCalendario(
                  icone: Icons.bedtime_outlined,
                  corIcone: AppColors.textDimmed,
                  titulo: 'DESCANSO',
                  valor: diasDescanso == 1 ? '1 DIA' : '$diasDescanso DIAS',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Grade Mensal do Calendário
        Container(
          key: const Key('card-calendario-mensal'),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    key: const Key('btn-mes-anterior'),
                    onPressed: () => _navegarMesCalendario(-1),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.primary,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    '${_nomesMeses[mes - 1]} $ano',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: AppColors.textLight,
                    ),
                  ),
                  IconButton(
                    key: const Key('btn-mes-proximo'),
                    onPressed: () => _navegarMesCalendario(1),
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: _diasSemanaLabels
                    .map(
                      (diaLabel) => Expanded(
                        child: Center(
                          child: Text(
                            diaLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDimmed,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalCelulas,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 6,
                  mainAxisExtent: 38,
                ),
                itemBuilder: (context, index) {
                  if (index < offsetPrimeiroDia) {
                    return const SizedBox.shrink();
                  }
                  final dia = index - offsetPrimeiroDia + 1;
                  final sessoesNoDia = diasTreinados[dia];
                  final treinado =
                      sessoesNoDia != null && sessoesNoDia.isNotEmpty;
                  final temPRNoDia = treinado &&
                      sessoesNoDia.any(
                        (d) =>
                            (widget.progressoController
                                    ?.obterPRsDaSessao(d.sessao) ??
                                0) >
                            0,
                      );
                  final isSelecionado = _diaSelecionadoCalendario != null &&
                      _diaSelecionadoCalendario!.year == ano &&
                      _diaSelecionadoCalendario!.month == mes &&
                      _diaSelecionadoCalendario!.day == dia;
                  final isHoje = agora.year == ano &&
                      agora.month == mes &&
                      agora.day == dia;

                  final Color corFundo =
                      treinado ? AppColors.primary : Colors.transparent;
                  final Color corTexto = treinado
                      ? AppColors.background
                      : (isHoje ? AppColors.primary : AppColors.textLight);

                  return GestureDetector(
                    key: Key('dia-calendario-$ano-$mes-$dia'),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _diaSelecionadoCalendario = DateTime(ano, mes, dia);
                      });
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: corFundo,
                            shape: BoxShape.circle,
                            border: isSelecionado
                                ? Border.all(
                                    color: Colors.white,
                                    width: 2.2,
                                  )
                                : (isHoje && !treinado
                                    ? Border.all(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.6,
                                        ),
                                        width: 1.2,
                                      )
                                    : null),
                            boxShadow: treinado && isSelecionado
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$dia',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: treinado || isHoje
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              color: corTexto,
                            ),
                          ),
                        ),
                        if (temPRNoDia)
                          Positioned(
                            top: -2,
                            right: 1,
                            child: Container(
                              key: Key('badge-pr-calendario-$ano-$mes-$dia'),
                              padding: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.accent,
                                  width: 1,
                                ),
                              ),
                              child: const DragonBallIcon(
                                size: 10,
                                stars: 1,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Treino Concluído',
                    style: TextStyle(fontSize: 11, color: AppColors.textDimmed),
                  ),
                  const SizedBox(width: 16),
                  const DragonBallIcon(size: 12, stars: 1),
                  const SizedBox(width: 5),
                  const Text(
                    'Recorde (PR)',
                    style: TextStyle(fontSize: 11, color: AppColors.textDimmed),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_diaSelecionadoCalendario != null &&
            _diaSelecionadoCalendario!.year == ano &&
            _diaSelecionadoCalendario!.month == mes) ...[
          if (sessoesDiaSelecionado.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.self_improvement_rounded,
                    color: AppColors.textDimmed,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dia de regeneração em ${_diaSelecionadoCalendario!.day.toString().padLeft(2, '0')}/${mes.toString().padLeft(2, '0')}/$ano',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Nenhum treino registrado nesta data.',
                    style: TextStyle(fontSize: 12, color: AppColors.textDimmed),
                  ),
                ],
              ),
            )
          else
            ...sessoesDiaSelecionado.asMap().entries.map((entry) {
              final isUltimo = entry.key == sessoesDiaSelecionado.length - 1;
              return _buildTimelineItem(entry.value, isUltimo);
            }),
        ],
      ],
      ),
    );
  }

  Widget _buildItemResumoCalendario({
    required IconData icone,
    required Color corIcone,
    required String titulo,
    required String valor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 13, color: corIcone),
            const SizedBox(width: 4),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textDimmed,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(HistoricoDia diaTreino, bool isUltimo) {
    final sessao = diaTreino.sessao;
    final exercicios = sessao.exerciciosConcluidosHoje;
    final mapaPRs =
        widget.progressoController?.obterMapaPRsDaSessao(sessao) ??
        const <String, int>{};
    final prsSessao = mapaPRs.length;
    final bool temPR = prsSessao > 0;
    final int totalSeries = sessao.totalSeries;
    final String volumeFormatado = sessao.volumeFormatado;

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
            // Linha com o nó do calendário, data, nome do treino, PRs e menu de ações
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    color: AppColors.background,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        diaTreino.dataLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                      if (diaTreino.sessao.nomeTreino != null &&
                          diaTreino.sessao.nomeTreino!.trim().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            diaTreino.sessao.nomeTreino!.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      if (temPR)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DragonBallIcon(size: 10, stars: prsSessao.clamp(1, 7)),
                              const SizedBox(width: 4),
                              Text(
                                prsSessao == 1 ? '1 PR' : '$prsSessao PRs',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFFFB300),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textDimmed),
                  color: AppColors.surface,
                  tooltip: 'Mais opções',
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                  onSelected: (val) {
                    if (val == 'compartilhar') _abrirCompartilharCard(diaTreino.sessao);
                    if (val == 'editar') _abrirEditarSessao(diaTreino);
                    if (val == 'excluir') _onExcluirSessao(diaTreino);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'compartilhar',
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined, color: AppColors.primary, size: 18),
                          SizedBox(width: 10),
                          Text('Compartilhar card', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, color: AppColors.textLight, size: 18),
                          SizedBox(width: 10),
                          Text('Editar treino', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'excluir',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                          SizedBox(width: 10),
                          Text('Excluir treino', style: TextStyle(fontSize: 13, color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ],
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
            // Cards dos exercícios da sessão (sempre expandidos)
            Padding(
              padding: const EdgeInsets.only(left: 50.0, bottom: 28.0),
              child: Column(
                children: exercicios
                    .map(
                      (ex) => HistoricoCardWidget(
                        exercicio: ex,
                        indiceSeriePR: mapaPRs[ex.nome.trim().toLowerCase()],
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}