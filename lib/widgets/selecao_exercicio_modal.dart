import 'package:flutter/material.dart';

import '../controllers/treino_controller.dart';
import '../models/catalogo_exercicios.dart';
import '../theme/app_colors.dart';
import 'exercicio_midia_widget.dart';

class SelecaoExercicioModal extends StatefulWidget {
  final TreinoController controller;
  final void Function(String nome, String grupo) onSelecionarExercicio;

  const SelecaoExercicioModal({
    super.key,
    required this.controller,
    required this.onSelecionarExercicio,
  });

  @override
  State<SelecaoExercicioModal> createState() => _SelecaoExercicioModalState();
}

class _SelecaoExercicioModalState extends State<SelecaoExercicioModal> {
  String _termoBusca = '';
  String _grupoSelecionado = 'TODOS';

  static const List<String> _gruposFiltro = [
    'TODOS',
    'PEITO',
    'COSTAS',
    'PERNAS',
    'OMBROS',
    'BÍCEPS',
    'TRÍCEPS',
    'ABDÔMEN',
  ];

  final List<Map<String, String>> _exerciciosPadrao =
      CatalogoExercicios.listaPadraoMap;

  String _normalizarGrupo(String valor) {
    return valor
        .trim()
        .toUpperCase()
        .replaceAll('Í', 'I')
        .replaceAll('Ô', 'O')
        .replaceAll('Ã', 'A')
        .replaceAll('É', 'E');
  }

  List<Map<String, String>> get _exerciciosFiltrados {
    final termo = _termoBusca.trim().toLowerCase();

    final Map<String, Map<String, String>> merged = {};
    for (final ex in _exerciciosPadrao) {
      final nome = ex['nome'] ?? '';
      if (nome.isNotEmpty) {
        merged[nome.toLowerCase()] = ex;
      }
    }
    for (final ex in widget.controller.exerciciosCustomizados) {
      final nome = ex['nome'] ?? '';
      if (nome.isNotEmpty && !merged.containsKey(nome.toLowerCase())) {
        merged[nome.toLowerCase()] = ex;
      }
    }

    final todosExercicios = merged.values.toList();

    return todosExercicios.where((exercicio) {
      final grupo = (exercicio['grupo'] ?? '').trim().toUpperCase();

      final atendeGrupo = _grupoSelecionado == 'TODOS' ||
          _normalizarGrupo(grupo) == _normalizarGrupo(_grupoSelecionado);
      if (!atendeGrupo) return false;

      if (termo.isEmpty) return true;
      final nome = (exercicio['nome'] ?? '').toLowerCase();
      final info = CatalogoExercicios.buscarPorNome(nome);
      final equipamento = info?.equipamento.toLowerCase() ?? '';
      final musculo = info?.musculoAlvo.toLowerCase() ?? '';
      return nome.contains(termo) ||
          grupo.toLowerCase().contains(termo) ||
          equipamento.contains(termo) ||
          musculo.contains(termo);
    }).toList();
  }

  bool get _deveExibirCriarNovo {
    final termo = _termoBusca.trim();
    if (termo.isEmpty) return false;

    final termoNormalizado = termo.toLowerCase();
    final temResultadoExato = _exerciciosPadrao.any(
          (ex) => (ex['nome'] ?? '').toLowerCase() == termoNormalizado,
        ) ||
        widget.controller.exerciciosCustomizados.any(
          (ex) => (ex['nome'] ?? '').toLowerCase() == termoNormalizado,
        );

    return !temResultadoExato;
  }

  Future<void> _abrirDialogGrupoMuscular() async {
    final String nomeNovoExercicio = _termoBusca.trim();
    if (nomeNovoExercicio.isEmpty) return;

    final grupos = [
      'PEITO',
      'COSTAS',
      'PERNAS',
      'BÍCEPS',
      'TRÍCEPS',
      'OMBROS',
      'ABDÔMEN',
      'OUTROS',
    ];

    final grupoSelecionado = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder, width: 1),
          ),
          title: const Text(
            'Qual o grupo muscular?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: grupos.map((grupo) {
              return InkWell(
                onTap: () => Navigator.pop(dialogContext, grupo),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    grupo,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR', style: TextStyle(color: AppColors.textDimmed)),
            ),
          ],
        );
      },
    );

    if (!mounted || grupoSelecionado == null) return;

    await widget.controller.salvarNovoExercicioCustomizado(nomeNovoExercicio, grupoSelecionado);

    if (!mounted) return;
    Navigator.pop(context);
    widget.onSelecionarExercicio(nomeNovoExercicio, grupoSelecionado);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      insetPadding: const EdgeInsets.all(20),
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          return Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SELECIONE O EXERCÍCIO',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textDimmed),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (valor) {
                    setState(() {
                      _termoBusca = valor;
                    });
                  },
                  style: const TextStyle(color: AppColors.textLight),
                  decoration: InputDecoration(
                    hintText: 'Buscar exercício...',
                    hintStyle: const TextStyle(color: AppColors.textDimmed),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _gruposFiltro.map((grupo) {
                      final bool isSelecionado = _grupoSelecionado == grupo;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _grupoSelecionado = grupo;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelecionado ? AppColors.primary : AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelecionado ? AppColors.primary : AppColors.cardBorder,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              grupo,
                              style: TextStyle(
                                color: isSelecionado ? AppColors.background : AppColors.textLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: _exerciciosFiltrados.isEmpty && !_deveExibirCriarNovo
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'Nenhum exercício encontrado',
                              style: TextStyle(color: AppColors.textDimmed),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _exerciciosFiltrados.length + (_deveExibirCriarNovo ? 1 : 0),
                          separatorBuilder: (context, index) => const Divider(color: AppColors.background),
                          itemBuilder: (context, index) {
                            if (_deveExibirCriarNovo && index == _exerciciosFiltrados.length) {
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.add_circle, color: AppColors.accent),
                                title: Text(
                                  "Criar novo exercício: '${_termoBusca.trim()}'",
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
                                ),
                                onTap: _abrirDialogGrupoMuscular,
                              );
                            }

                            final ex = _exerciciosFiltrados[index];
                            final nome = ex['nome'] ?? '';
                            final grupo = ex['grupo'] ?? '';
                            final info = CatalogoExercicios.buscarPorNome(nome);
                            final isPadraoExato = _exerciciosPadrao.any(
                              (p) => (p['nome'] ?? '').toLowerCase() == nome.toLowerCase(),
                            );
                            final subtitulo = info != null
                                ? '$grupo • ${info.equipamento}'
                                : '$grupo • Personalizado';
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 2),
                              leading: ExercicioThumbnailWidget(
                                nomeExercicio: nome,
                                grupo: grupo,
                                size: 46,
                                borderRadius: 11,
                                abrirModalAoTocar: true,
                                exibirIndicadorGif: true,
                              ),
                              title: Text(
                                nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textLight,
                                ),
                              ),
                              subtitle: Text(
                                subtitulo,
                                style: TextStyle(
                                  color: isPadraoExato ? AppColors.primary : AppColors.accent,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isPadraoExato) ...[
                                    InkWell(
                                      onTap: () async {
                                        final fundido = await AssociarExercicioModal.mostrar(
                                          context,
                                          controller: widget.controller,
                                          nomeOrigem: nome,
                                          grupoOrigem: grupo,
                                        );
                                        if (fundido != null && mounted) {
                                          setState(() {});
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent.withValues(alpha: 0.14),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppColors.accent.withValues(alpha: 0.45),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.link_rounded,
                                              color: AppColors.accent,
                                              size: 14,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'VINCULAR',
                                              style: TextStyle(
                                                color: AppColors.accent,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  const Icon(
                                    Icons.add_circle_outline,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                widget.onSelecionarExercicio(nome, grupo);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Modal para associar/fundir um exercício criado previamente (customizado ou legado)
/// com um exercício oficial do catálogo padrão sem perder histórico, PRs ou fichas.
class AssociarExercicioModal extends StatefulWidget {
  final TreinoController controller;
  final String nomeOrigem;
  final String grupoOrigem;

  const AssociarExercicioModal({
    super.key,
    required this.controller,
    required this.nomeOrigem,
    required this.grupoOrigem,
  });

  static Future<InfoExercicioCatalogo?> mostrar(
    BuildContext context, {
    required TreinoController controller,
    required String nomeOrigem,
    required String grupoOrigem,
  }) {
    return showDialog<InfoExercicioCatalogo>(
      context: context,
      builder: (_) => AssociarExercicioModal(
        controller: controller,
        nomeOrigem: nomeOrigem,
        grupoOrigem: grupoOrigem,
      ),
    );
  }

  @override
  State<AssociarExercicioModal> createState() => _AssociarExercicioModalState();
}

class _AssociarExercicioModalState extends State<AssociarExercicioModal> {
  String _termoBusca = '';
  bool _processando = false;

  InfoExercicioCatalogo? get _sugestaoAutomatica =>
      CatalogoExercicios.buscarPorNome(widget.nomeOrigem);

  List<InfoExercicioCatalogo> get _catalogoFiltrado {
    final termo = _termoBusca.trim().toLowerCase();
    return CatalogoExercicios.exerciciosPadrao.where((item) {
      if (item.nome.toLowerCase() == widget.nomeOrigem.trim().toLowerCase()) {
        return false;
      }
      if (termo.isEmpty) return true;
      return item.nome.toLowerCase().contains(termo) ||
          item.grupo.toLowerCase().contains(termo) ||
          item.equipamento.toLowerCase().contains(termo) ||
          item.musculoAlvo.toLowerCase().contains(termo);
    }).toList();
  }

  Future<void> _confirmarFusao(InfoExercicioCatalogo destino) async {
    setState(() => _processando = true);
    await widget.controller.fundirExercicio(
      nomeOrigem: widget.nomeOrigem,
      nomeDestino: destino.nome,
      grupoDestino: destino.grupo,
    );
    if (!mounted) return;
    Navigator.pop(context, destino);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '"${widget.nomeOrigem}" foi fundido a "${destino.nome}" (${destino.grupo}) mantendo todo o histórico!',
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
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
    final sugestao = _sugestaoAutomatica;
    final lista = _catalogoFiltrado;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.link_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'ASSOCIAR AO CATÁLOGO PADRÃO',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textDimmed),
                  onPressed: _processando ? null : () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exercício atual: ${widget.nomeOrigem} (${widget.grupoOrigem})',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Escolha o exercício padrão correspondente abaixo. Todas as suas séries históricas, recordes (PRs) e fichas serão unificados sem perder nenhum progresso.',
                    style: TextStyle(
                      color: AppColors.textDimmed,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (sugestao != null &&
                sugestao.nome.toLowerCase() !=
                    widget.nomeOrigem.trim().toLowerCase()) ...[
              const SizedBox(height: 12),
              const Text(
                'SUGESTÃO AUTOMÁTICA',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.45),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  leading: ExercicioThumbnailWidget(
                    nomeExercicio: sugestao.nome,
                    grupo: sugestao.grupo,
                    size: 42,
                    borderRadius: 10,
                    abrirModalAoTocar: true,
                    exibirIndicadorGif: true,
                  ),
                  title: Text(
                    sugestao.nome,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    '${sugestao.grupo} • ${sugestao.equipamento}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: _processando ? null : () => _confirmarFusao(sugestao),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.background,
                      elevation: 0,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'UNIFICAR',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              onChanged: (valor) => setState(() => _termoBusca = valor),
              style: const TextStyle(color: AppColors.textLight, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Buscar exercício padrão no catálogo...',
                hintStyle: const TextStyle(color: AppColors.textDimmed, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                filled: true,
                fillColor: AppColors.background,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
            const SizedBox(height: 10),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: lista.length,
                separatorBuilder: (_, _) => const Divider(color: AppColors.background, height: 1),
                itemBuilder: (context, index) {
                  final item = lista[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    leading: ExercicioThumbnailWidget(
                      nomeExercicio: item.nome,
                      grupo: item.grupo,
                      size: 42,
                      borderRadius: 10,
                      abrirModalAoTocar: true,
                      exibirIndicadorGif: true,
                    ),
                    title: Text(
                      item.nome,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      '${item.grupo} • ${item.equipamento}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.link_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    onTap: _processando ? null : () => _confirmarFusao(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
