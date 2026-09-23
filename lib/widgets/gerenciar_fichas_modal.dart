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
  final Set<int> _fichasExpandidas = {};

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

  void _abrirEditorFicha([FichaTreino? ficha]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FichaEditorBottomSheet(
        controller: _controller,
        fichaParaEditar: ficha,
      ),
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
                      final int totalExercicios = ficha.exercicios.length;
                      final bool isExpandida = _fichasExpandidas.contains(ficha.id ?? index);

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
                            // Cabeçalho da Ficha com Ações
                            Row(
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
                                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                                  hoverColor: AppColors.primary.withValues(alpha: 0.15),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _abrirEditorFicha(ficha),
                                  tooltip: 'Editar ficha',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textDimmed),
                                  hoverColor: AppColors.danger.withValues(alpha: 0.15),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _confirmarExclusaoFicha(ficha),
                                  tooltip: 'Excluir ficha',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Listagem de Exercícios (Até 2 no modo recolhido, completa no modo expandido)
                            if (totalExercicios > 0) ...[
                              Builder(
                                builder: (context) {
                                  final itensExibidos = isExpandida
                                      ? ficha.exercicios
                                      : ficha.exercicios.take(2).toList();

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ...itensExibidos.map((ex) => Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 5,
                                              height: 5,
                                              decoration: const BoxDecoration(
                                                color: AppColors.primary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                ex.nome,
                                                maxLines: isExpandida ? 2 : 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: AppColors.textLight,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.surface,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: AppColors.cardBorder),
                                              ),
                                              child: Text(
                                                '${ex.seriesPadrao}x',
                                                style: const TextStyle(
                                                  color: AppColors.accent,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),

                                      // Botão de alternar expansão se houver mais de 2 exercícios
                                      if (totalExercicios > 2) ...[
                                        const SizedBox(height: 2),
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              if (isExpandida) {
                                                _fichasExpandidas.remove(ficha.id ?? index);
                                              } else {
                                                _fichasExpandidas.add(ficha.id ?? index);
                                              }
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(8),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  isExpandida
                                                      ? 'Recolher lista'
                                                      : 'Ver todos os $totalExercicios exercícios (+${totalExercicios - 2})',
                                                  style: TextStyle(
                                                    color: isExpandida ? AppColors.textDimmed : AppColors.accent,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  isExpandida
                                                      ? Icons.keyboard_arrow_up_rounded
                                                      : Icons.keyboard_arrow_down_rounded,
                                                  size: 16,
                                                  color: isExpandida ? AppColors.textDimmed : AppColors.accent,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            ],

                            const SizedBox(height: 12),
                            // Rodapé do Card com Contador e Botão Carregar
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
                                        '$totalExercicios ${totalExercicios == 1 ? 'EXERCÍCIO' : 'EXERCÍCIOS'}',
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
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.background,
                                    elevation: 0,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
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
                onPressed: () => _abrirEditorFicha(),
                icon: const Icon(Icons.add_rounded, size: 22),
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

class _FichaEditorBottomSheet extends StatefulWidget {
  final TreinoController controller;
  final FichaTreino? fichaParaEditar;

  const _FichaEditorBottomSheet({
    required this.controller,
    this.fichaParaEditar,
  });

  @override
  State<_FichaEditorBottomSheet> createState() => _FichaEditorBottomSheetState();
}

class _FichaEditorBottomSheetState extends State<_FichaEditorBottomSheet> {
  late final TextEditingController _nomeController;
  late final List<FichaExercicioItem> _itens;

  bool get isEdicao => widget.fichaParaEditar != null;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.fichaParaEditar?.nome ?? '');
    _itens = widget.fichaParaEditar != null
        ? widget.fichaParaEditar!.exercicios.map((e) => e.copyWith()).toList()
        : [];
  }

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

    final nova = FichaTreino(
      id: widget.fichaParaEditar?.id,
      nome: nome,
      exercicios: _itens,
    );
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
                isEdicao ? 'Ficha "$nome" atualizada com sucesso!' : 'Ficha "$nome" criada com sucesso!',
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: bottomInset + systemBottomPadding + 16,
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
          maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isEdicao ? Icons.edit_note_rounded : Icons.post_add_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEdicao ? 'EDITAR FICHA DE TREINO' : 'NOVA FICHA DE TREINO',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textDimmed, size: 20),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.background,
                    padding: const EdgeInsets.all(6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
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
                filled: true,
                fillColor: AppColors.background,
                isDense: true,
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
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _importarDoHistorico,
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: const Text('DO HISTÓRICO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _adicionarExercicio,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('ADICIONAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'EXERCÍCIOS E SÉRIES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDimmed,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  '${_itens.length} selecionados',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _itens.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fitness_center_rounded, size: 36, color: AppColors.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          const Text(
                            'Nenhum exercício na ficha.',
                            style: TextStyle(color: AppColors.textDimmed, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Toque em "Adicionar" ou "Do Histórico" acima.',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _itens.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _itens[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
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
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.grupo.toUpperCase(),
                                      style: const TextStyle(color: AppColors.textDimmed, fontSize: 10, letterSpacing: 0.5),
                                    ),
                                  ],
                                ),
                              ),

                              // Controles táteis de quantidade de séries [-] X [+]
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                    icon: Icon(
                                      Icons.remove_circle_outline_rounded,
                                      size: 18,
                                      color: item.seriesPadrao > 1 ? AppColors.accent : AppColors.textMuted,
                                    ),
                                    onPressed: item.seriesPadrao > 1
                                        ? () {
                                            setState(() {
                                              _itens[index] = item.copyWith(
                                                seriesPadrao: item.seriesPadrao - 1,
                                              );
                                            });
                                          }
                                        : null,
                                    tooltip: 'Diminuir séries',
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.cardBorder),
                                    ),
                                    child: Text(
                                      '${item.seriesPadrao}x',
                                      style: const TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                    icon: Icon(
                                      Icons.add_circle_outline_rounded,
                                      size: 18,
                                      color: item.seriesPadrao < 10 ? AppColors.accent : AppColors.textMuted,
                                    ),
                                    onPressed: item.seriesPadrao < 10
                                        ? () {
                                            setState(() {
                                              _itens[index] = item.copyWith(
                                                seriesPadrao: item.seriesPadrao + 1,
                                              );
                                            });
                                          }
                                        : null,
                                    tooltip: 'Aumentar séries',
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),

                              // Excluir exercício da ficha
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                hoverColor: AppColors.danger.withValues(alpha: 0.15),
                                onPressed: () {
                                  setState(() {
                                    _itens.removeAt(index);
                                  });
                                },
                                tooltip: 'Remover da ficha',
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
                child: Text(
                  isEdicao ? 'SALVAR ALTERAÇÕES' : 'SALVAR FICHA',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
