import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/treino_controller.dart';
import '../models/catalogo_exercicios.dart';
import '../services/exercicio_custom_midia_service.dart';
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

    await _abrirFormularioExercicioCustomizado(
      nomeInicial: nomeNovoExercicio,
      grupoInicial: _grupoSelecionado != 'TODOS' ? _grupoSelecionado : 'PEITO',
      isEdicao: false,
    );
  }

  Future<void> _abrirDialogEditarExercicioCustomizado(
    String nomeAtual,
    String grupoAtual,
  ) async {
    await _abrirFormularioExercicioCustomizado(
      nomeInicial: nomeAtual,
      grupoInicial: grupoAtual,
      isEdicao: true,
    );
  }

  Future<void> _abrirFormularioExercicioCustomizado({
    required String nomeInicial,
    required String grupoInicial,
    required bool isEdicao,
  }) async {
    final nomeCtrl = TextEditingController(text: nomeInicial);
    String grupoEscolhido =
        grupoInicial.trim().isNotEmpty ? grupoInicial.trim().toUpperCase() : 'PEITO';
    const linha1Grupos = ['PEITO', 'COSTAS', 'PERNAS', 'OMBROS'];
    const linha2Grupos = ['BÍCEPS', 'TRÍCEPS', 'ABDÔMEN', 'OUTROS'];

    InfoExercicioCatalogo? itemCatalogoEscolhido;
    MidiaExercicioCustom? midiaAtual =
        ExercicioCustomMidiaService.instance.obterMidia(nomeInicial);
    bool removerMidiaExistente = false;
    bool salvando = false;

    final resultado = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget previewMidia;
            String tituloMidia;
            String subtituloMidia;

            if (itemCatalogoEscolhido != null) {
              tituloMidia = itemCatalogoEscolhido!.nome;
              subtituloMidia =
                  '${itemCatalogoEscolhido!.equipamento} • Catálogo Offline';
              previewMidia = ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  width: 52,
                  height: 52,
                  color: Colors.white,
                  padding: const EdgeInsets.all(2),
                  child: Image.asset(
                    itemCatalogoEscolhido!.thumbAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            } else if (!removerMidiaExistente && midiaAtual != null) {
              final isArquivo = midiaAtual!.tipo == 'arquivo';
              tituloMidia = isArquivo
                  ? 'Foto / GIF do seu dispositivo'
                  : (midiaAtual!.nomeReferenciaCatalogo ??
                      midiaAtual!.nomeExercicio);
              subtituloMidia = isArquivo
                  ? 'Salvo localmente (100% offline)'
                  : '${midiaAtual!.equipamento ?? 'Catálogo'} • Catálogo Offline';

              final localPath = midiaAtual!.thumbLocalPath;
              final assetPath = midiaAtual!.thumbAsset;
              previewMidia = ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  width: 52,
                  height: 52,
                  color: isArquivo ? AppColors.surface : Colors.white,
                  child: assetPath != null
                      ? Padding(
                          padding: const EdgeInsets.all(2),
                          child: Image.asset(assetPath, fit: BoxFit.contain),
                        )
                      : (localPath != null && File(localPath).existsSync()
                          ? Image.file(File(localPath), fit: BoxFit.cover)
                          : const Icon(
                              Icons.fitness_center_rounded,
                              color: AppColors.primary,
                            )),
                ),
              );
            } else {
              tituloMidia = 'Sem imagem ou GIF personalizado';
              subtituloMidia =
                  'Escolha uma animação do catálogo ou envie uma foto';
              previewMidia = Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppColors.textDimmed,
                  size: 22,
                ),
              );
            }

            Widget buildLinhaGrupos(List<String> lista) {
              return Row(
                children: lista.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final g = entry.value;
                  final selecionado =
                      _normalizarGrupo(grupoEscolhido) == _normalizarGrupo(g);
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: idx < lista.length - 1 ? 6 : 0,
                      ),
                      child: InkWell(
                        onTap: () => setDialogState(() => grupoEscolhido = g),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selecionado
                                ? AppColors.primary
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selecionado
                                  ? AppColors.primary
                                  : AppColors.cardBorder,
                            ),
                          ),
                          child: Text(
                            g,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selecionado
                                  ? AppColors.background
                                  : AppColors.textLight,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }

            Widget buildBotaoMidia({
              required IconData icon,
              required String label,
              required VoidCallback onTap,
              bool destaque = false,
            }) {
              return Expanded(
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: destaque
                          ? AppColors.primary.withValues(alpha: 0.14)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: destaque
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 17,
                          color: destaque
                              ? AppColors.primary
                              : AppColors.textLight,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            color: destaque
                                ? AppColors.primary
                                : AppColors.textLight,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final temMidiaSelecionada = itemCatalogoEscolhido != null ||
                (!removerMidiaExistente && midiaAtual != null);

            return AlertDialog(
              backgroundColor: AppColors.surface,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 14, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEdicao ? Icons.edit_outlined : Icons.add_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEdicao
                          ? 'Editar Exercício Personalizado'
                          : 'Novo Exercício Personalizado',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: salvando
                        ? null
                        : () => Navigator.pop(dialogContext),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textDimmed,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NOME DO EXERCÍCIO',
                        style: TextStyle(
                          color: AppColors.textDimmed,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nomeCtrl,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ex: Supino Articulado Pegada Neutra',
                          hintStyle: const TextStyle(
                            color: AppColors.textDimmed,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.cardBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'GRUPO MUSCULAR',
                        style: TextStyle(
                          color: AppColors.textDimmed,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 6),
                      buildLinhaGrupos(linha1Grupos),
                      const SizedBox(height: 6),
                      buildLinhaGrupos(linha2Grupos),
                      const SizedBox(height: 16),
                      const Text(
                        'IMAGEM / GIF DE EXECUÇÃO (OPCIONAL)',
                        style: TextStyle(
                          color: AppColors.textDimmed,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                previewMidia,
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tituloMidia,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        subtituloMidia,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.textDimmed,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (temMidiaSelecionada)
                                  IconButton(
                                    tooltip: 'Remover imagem/GIF',
                                    onPressed: () {
                                      setDialogState(() {
                                        itemCatalogoEscolhido = null;
                                        removerMidiaExistente = true;
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.danger,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                buildBotaoMidia(
                                  icon: Icons.burst_mode_rounded,
                                  label: 'Catálogo',
                                  destaque: true,
                                  onTap: () async {
                                    final item =
                                        await SeletorMidiaCatalogoModal.mostrar(
                                      context,
                                      grupoInicial: grupoEscolhido,
                                    );
                                    if (item != null) {
                                      setDialogState(() {
                                        itemCatalogoEscolhido = item;
                                        removerMidiaExistente = false;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                buildBotaoMidia(
                                  icon: Icons.photo_library_outlined,
                                  label: 'Galeria',
                                  onTap: () async {
                                    final alvoNome =
                                        nomeCtrl.text.trim().isNotEmpty
                                            ? nomeCtrl.text.trim()
                                            : nomeInicial;
                                    final novaMidia =
                                        await ExercicioCustomMidiaService
                                            .instance
                                            .selecionarEAssociarDaGaleriaOuCamera(
                                      nomeExercicio: alvoNome,
                                      source: ImageSource.gallery,
                                      grupo: grupoEscolhido,
                                    );
                                    if (novaMidia != null) {
                                      setDialogState(() {
                                        midiaAtual = novaMidia;
                                        itemCatalogoEscolhido = null;
                                        removerMidiaExistente = false;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                buildBotaoMidia(
                                  icon: Icons.camera_alt_outlined,
                                  label: 'Câmera',
                                  onTap: () async {
                                    final alvoNome =
                                        nomeCtrl.text.trim().isNotEmpty
                                            ? nomeCtrl.text.trim()
                                            : nomeInicial;
                                    final novaMidia =
                                        await ExercicioCustomMidiaService
                                            .instance
                                            .selecionarEAssociarDaGaleriaOuCamera(
                                      nomeExercicio: alvoNome,
                                      source: ImageSource.camera,
                                      grupo: grupoEscolhido,
                                    );
                                    if (novaMidia != null) {
                                      setDialogState(() {
                                        midiaAtual = novaMidia;
                                        itemCatalogoEscolhido = null;
                                        removerMidiaExistente = false;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: salvando
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text(
                    'CANCELAR',
                    style: TextStyle(
                      color: AppColors.textDimmed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: salvando
                      ? null
                      : () async {
                          final novoNome = nomeCtrl.text.trim();
                          if (novoNome.isEmpty) return;
                          setDialogState(() => salvando = true);

                          if (removerMidiaExistente) {
                            await ExercicioCustomMidiaService.instance
                                .removerMidia(nomeInicial);
                            await ExercicioCustomMidiaService.instance
                                .removerMidia(novoNome);
                          } else if (itemCatalogoEscolhido != null) {
                            await ExercicioCustomMidiaService.instance
                                .salvarMidiaDoCatalogo(
                              nomeExercicio: novoNome,
                              itemCatalogo: itemCatalogoEscolhido!,
                            );
                          }

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext, {
                              'nome': novoNome,
                              'grupo': grupoEscolhido,
                            });
                          }
                        },
                  child: salvando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.background,
                          ),
                        )
                      : Text(
                          isEdicao ? 'SALVAR ALTERAÇÕES' : 'CRIAR EXERCÍCIO',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || resultado == null) return;
    final novoNome = resultado['nome'] ?? '';
    final novoGrupo = resultado['grupo'] ?? '';
    if (novoNome.isEmpty || novoGrupo.isEmpty) return;

    if (isEdicao) {
      await widget.controller.editarExercicioCustomizado(
        nomeAntigo: nomeInicial,
        novoNome: novoNome,
        novoGrupo: novoGrupo,
      );
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exercício atualizado para "$novoNome" ($novoGrupo).'),
          backgroundColor: AppColors.surface,
        ),
      );
    } else {
      await widget.controller.salvarNovoExercicioCustomizado(
        novoNome,
        novoGrupo,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSelecionarExercicio(novoNome, novoGrupo);
    }
  }

  Future<void> _confirmarExclusaoExercicioCustomizado(
    String nome,
    String grupo,
  ) async {
    bool apagarDoHistorico = false;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppColors.cardBorder, width: 1),
              ),
              title: const Row(
                children: [
                  Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Excluir Exercício?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deseja remover "$nome" ($grupo) da sua lista de exercícios personalizados e das fichas?',
                    style: const TextStyle(color: AppColors.textLight, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => setDialogState(() => apagarDoHistorico = !apagarDoHistorico),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: apagarDoHistorico
                              ? AppColors.danger.withValues(alpha: 0.6)
                              : AppColors.cardBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: apagarDoHistorico,
                              activeColor: AppColors.danger,
                              onChanged: (val) =>
                                  setDialogState(() => apagarDoHistorico = val ?? false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Apagar também do histórico de treinos anteriores',
                              style: TextStyle(color: AppColors.textDimmed, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('CANCELAR', style: TextStyle(color: AppColors.textDimmed)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('EXCLUIR', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || confirmado != true) return;

    await widget.controller.excluirExercicioCustomizado(
      nome,
      removerHistorico: apagarDoHistorico,
    );

    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exercício "$nome" removido.'),
        backgroundColor: AppColors.surface,
      ),
    );
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
                            final midiaCustom = info == null
                                ? ExercicioCustomMidiaService.instance.obterMidia(nome)
                                : null;
                            final isPadraoExato = _exerciciosPadrao.any(
                              (p) => (p['nome'] ?? '').toLowerCase() == nome.toLowerCase(),
                            );
                            final subtitulo = info != null
                                ? '$grupo • ${info.equipamento}'
                                : midiaCustom != null &&
                                        midiaCustom.equipamento != null &&
                                        midiaCustom.equipamento!.isNotEmpty &&
                                        midiaCustom.equipamento != 'Personalizado'
                                    ? '$grupo • ${midiaCustom.equipamento} (Personalizado)'
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
                                  if (!isPadraoExato)
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert_rounded,
                                        color: AppColors.accent,
                                        size: 20,
                                      ),
                                      tooltip: 'Opções do exercício personalizado',
                                      color: AppColors.surface,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: const BorderSide(color: AppColors.cardBorder),
                                      ),
                                      onSelected: (acao) async {
                                        if (acao == 'editar') {
                                          await _abrirDialogEditarExercicioCustomizado(
                                            nome,
                                            grupo,
                                          );
                                        } else if (acao == 'vincular') {
                                          final fundido = await AssociarExercicioModal.mostrar(
                                            context,
                                            controller: widget.controller,
                                            nomeOrigem: nome,
                                            grupoOrigem: grupo,
                                          );
                                          if (fundido != null && mounted) {
                                            setState(() {});
                                          }
                                        } else if (acao == 'excluir') {
                                          await _confirmarExclusaoExercicioCustomizado(
                                            nome,
                                            grupo,
                                          );
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'editar',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.edit_outlined,
                                                color: AppColors.textLight,
                                                size: 18,
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                'Editar (nome, grupo ou imagem)',
                                                style: TextStyle(fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'vincular',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.link_rounded,
                                                color: AppColors.accent,
                                                size: 18,
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                'Vincular ao catálogo',
                                                style: TextStyle(fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'excluir',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete_outline_rounded,
                                                color: AppColors.danger,
                                                size: 18,
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                'Excluir exercício',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.danger,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
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
