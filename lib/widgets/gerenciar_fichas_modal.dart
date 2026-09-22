import 'package:flutter/material.dart';

import '../controllers/treino_controller.dart';
import '../models/ficha_treino.dart';
import '../models/sessao_treino.dart';
import '../theme/app_colors.dart';
import 'selecao_exercicio_modal.dart';

class GerenciarFichasModal extends StatefulWidget {
  final TreinoController controller;

  const GerenciarFichasModal({
    super.key,
    required this.controller,
  });

  @override
  State<GerenciarFichasModal> createState() => _GerenciarFichasModalState();
}

class _GerenciarFichasModalState extends State<GerenciarFichasModal> {
  late final TreinoController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.carregarFichas();
  }

  void _carregarFicha(FichaTreino ficha) {
    _controller.carregarFichaParaTreino(ficha);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ficha "${ficha.nome}" carregada com sucesso!',
                style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
    );
  }

  Future<void> _confirmarExclusaoFicha(FichaTreino ficha) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Excluir Ficha?',
              style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Text(
          'Deseja excluir a ficha "${ficha.nome}"? Esta ação não pode ser desfeita.',
          style: const TextStyle(color: AppColors.textDimmed, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textDimmed, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar == true && ficha.id != null) {
      await _controller.excluirFicha(ficha.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.delete_sweep_outlined, color: AppColors.danger, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ficha "${ficha.nome}" excluída.',
                  style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
        ),
      );
    }
  }

  void _abrirCriadorNovaFicha() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CriarFichaBottomSheet(controller: _controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: const Icon(Icons.assignment_outlined, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FICHAS DE TREINO',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: AppColors.textLight,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Selecione uma rotina pré-configurada para iniciar em 1 toque.',
                        style: TextStyle(fontSize: 12, color: AppColors.textDimmed, height: 1.2),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textDimmed, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.background,
                    padding: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 16),
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final fichas = _controller.fichas;

                  if (fichas.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: const Icon(
                              Icons.folder_open_rounded,
                              size: 36,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Nenhuma ficha criada ainda',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'Crie sua primeira ficha de treino ou salve seu treino atual como template.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textDimmed, fontSize: 13, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: fichas.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final ficha = fichas[index];
                      final nomesExercicios = ficha.exercicios.map((e) => e.nome).join(' • ');

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    ficha.nome,
                                    style: const TextStyle(
                                      color: AppColors.textLight,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textDimmed),
                                  hoverColor: AppColors.danger.withValues(alpha: 0.15),
                                  highlightColor: AppColors.danger.withValues(alpha: 0.25),
                                  splashColor: AppColors.danger.withValues(alpha: 0.25),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _confirmarExclusaoFicha(ficha),
                                  tooltip: 'Excluir ficha',
                                ),
                              ],
                            ),
                            if (nomesExercicios.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                nomesExercicios,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textDimmed,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.fitness_center, size: 13, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${ficha.exercicios.length} ${ficha.exercicios.length == 1 ? 'EXERCÍCIO' : 'EXERCÍCIOS'}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _carregarFicha(ficha),
                                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                                  label: const Text(
                                    'CARREGAR',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.background,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _abrirCriadorNovaFicha,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'CRIAR NOVA FICHA',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.8),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CriarFichaBottomSheet extends StatefulWidget {
  final TreinoController controller;

  const _CriarFichaBottomSheet({required this.controller});

  @override
  State<_CriarFichaBottomSheet> createState() => _CriarFichaBottomSheetState();
}

class _CriarFichaBottomSheetState extends State<_CriarFichaBottomSheet> {
  final TextEditingController _nomeController = TextEditingController();
  final List<FichaExercicioItem> _itens = [];

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  void _adicionarExercicio() {
    showDialog(
      context: context,
      builder: (context) => SelecaoExercicioModal(
        controller: widget.controller,
        onSelecionarExercicio: (nome, grupo) {
          setState(() {
            _itens.add(FichaExercicioItem(
              nome: nome,
              grupo: grupo,
              ordem: _itens.length,
              seriesPadrao: 3,
            ));
          });
        },
      ),
    );
  }

  Future<void> _importarDoHistorico() async {
    final historico = await widget.controller.buscarHistoricoParaFichas();
    if (!mounted) return;
    if (historico.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.accent, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nenhum treino encontrado no histórico para importar.',
                  style: TextStyle(color: AppColors.textLight, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
        ),
      );
      return;
    }

    final sessaoSelecionada = await showDialog<SessaoTreino>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Importar do Histórico',
              style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: ListView.separated(
            itemCount: historico.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final sessao = historico[index];
              final dataFormatada = sessao.data != null
                  ? '${sessao.data!.day.toString().padLeft(2, '0')}/${sessao.data!.month.toString().padLeft(2, '0')}/${sessao.data!.year}'
                  : 'Treino ${index + 1}';
              final titulo = (sessao.nomeTreino != null && sessao.nomeTreino!.trim().isNotEmpty)
                  ? '${sessao.nomeTreino} ($dataFormatada)'
                  : 'Treino de $dataFormatada';

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  title: Text(
                    titulo,
                    style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${sessao.exerciciosConcluidosHoje.length} exercícios • ${sessao.exerciciosConcluidosHoje.map((e) => e.nome).take(3).join(', ')}...',
                      style: const TextStyle(color: AppColors.textDimmed, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                  onTap: () => Navigator.pop(context, sessao),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textDimmed, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (sessaoSelecionada != null) {
      setState(() {
        if (_nomeController.text.trim().isEmpty) {
          _nomeController.text = sessaoSelecionada.nomeTreino ?? 'Ficha';
        }
        _itens.clear();
        for (int i = 0; i < sessaoSelecionada.exerciciosConcluidosHoje.length; i++) {
          final ex = sessaoSelecionada.exerciciosConcluidosHoje[i];
          _itens.add(FichaExercicioItem(
            nome: ex.nome,
            grupo: ex.grupo,
            ordem: i,
            seriesPadrao: ex.seriesDetalhes.isNotEmpty ? ex.seriesDetalhes.length : 3,
          ));
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${sessaoSelecionada.exerciciosConcluidosHoje.length} exercícios importados do histórico!',
                    style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
          ),
        );
      }
    }
  }

  Future<void> _salvarFicha() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Digite o nome da ficha (ex: Ficha A).',
                  style: TextStyle(color: AppColors.textLight, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
        ),
      );
      return;
    }
    if (_itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Adicione ao menos um exercício à ficha.',
                  style: TextStyle(color: AppColors.textLight, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
        ),
      );
      return;
    }

    final nova = FichaTreino(nome: nome, exercicios: _itens);
    await widget.controller.salvarFicha(nova);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ficha "$nome" criada com sucesso!',
                style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.cardBorder),
          left: BorderSide(color: AppColors.cardBorder),
          right: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(Icons.note_add_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'NOVA FICHA DE TREINO',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textDimmed, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.background,
                  padding: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nomeController,
            style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Ex: Ficha A - Peito & Tríceps',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              labelText: 'Nome da Ficha',
              labelStyle: const TextStyle(color: AppColors.primary, fontSize: 12),
              prefixIcon: const Icon(Icons.bookmark_outline_rounded, color: AppColors.primary, size: 20),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EXERCÍCIOS (${_itens.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDimmed,
                  letterSpacing: 0.8,
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _importarDoHistorico,
                    icon: const Icon(Icons.history_rounded, size: 15, color: AppColors.primary),
                    label: const Text(
                      'DO HISTÓRICO',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _adicionarExercicio,
                    icon: const Icon(Icons.add_rounded, size: 15, color: AppColors.accent),
                    label: const Text(
                      'MANUAL',
                      style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.accent.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _itens.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: const Icon(
                            Icons.fitness_center_rounded,
                            size: 28,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Nenhum exercício adicionado',
                          style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Importe do histórico ou adicione manualmente acima.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textDimmed.withValues(alpha: 0.7), fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _itens.length,
                    itemBuilder: (context, index) {
                      final item = _itens[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
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
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.grupo} • ${item.seriesPadrao} séries',
                                    style: const TextStyle(color: AppColors.textDimmed, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                              hoverColor: AppColors.danger.withValues(alpha: 0.15),
                              highlightColor: AppColors.danger.withValues(alpha: 0.25),
                              splashColor: AppColors.danger.withValues(alpha: 0.25),
                              onPressed: () {
                                setState(() {
                                  _itens.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _salvarFicha,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'SALVAR FICHA',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
