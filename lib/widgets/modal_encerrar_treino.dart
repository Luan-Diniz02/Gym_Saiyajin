import 'package:flutter/material.dart';

import '../controllers/progresso_controller.dart';
import '../controllers/treino_controller.dart';
import '../models/poder_luta.dart';
import '../models/recorde_pessoal.dart';
import '../theme/app_colors.dart';
import 'scouter_icon.dart';

class ResultadoEncerrarTreino {
  final bool descartarAtual;
  final String? nomeTreino;
  final bool salvarComoFicha;
  final String? nomeFicha;

  ResultadoEncerrarTreino({
    required this.descartarAtual,
    this.nomeTreino,
    required this.salvarComoFicha,
    this.nomeFicha,
  });
}

class ModalEncerrarTreinoDialog extends StatefulWidget {
  final TreinoController controller;
  final ProgressoController? progressoController;

  const ModalEncerrarTreinoDialog({
    super.key,
    required this.controller,
    this.progressoController,
  });

  @override
  State<ModalEncerrarTreinoDialog> createState() => _ModalEncerrarTreinoDialogState();
}

class _ModalEncerrarTreinoDialogState extends State<ModalEncerrarTreinoDialog> {
  late final TextEditingController _nomeTreinoController;
  late final TextEditingController _nomeFichaController;

  bool _descartarAtual = false;
  bool _salvarComoFicha = false;
  String? _divisaoSelecionada;

  final List<String> _divisoesPadrao = const [
    'Push',
    'Pull',
    'Legs',
  ];

  @override
  void initState() {
    super.initState();
    final nomeAtual = widget.controller.nomeTreino ?? '';
    _nomeTreinoController = TextEditingController(text: nomeAtual);
    _nomeFichaController = TextEditingController(text: nomeAtual.isNotEmpty ? nomeAtual : 'Minha Ficha');

    if (nomeAtual.isNotEmpty && _divisoesPadrao.contains(nomeAtual)) {
      _divisaoSelecionada = nomeAtual;
    }
  }

  @override
  void dispose() {
    _nomeTreinoController.dispose();
    _nomeFichaController.dispose();
    super.dispose();
  }

  void _selecionarDivisao(String divisao) {
    setState(() {
      if (_divisaoSelecionada == divisao) {
        _divisaoSelecionada = null;
      } else {
        _divisaoSelecionada = divisao;
        _nomeTreinoController.text = divisao;
        if (!_salvarComoFicha || _nomeFichaController.text.isEmpty || _divisoesPadrao.contains(_nomeFichaController.text)) {
          _nomeFichaController.text = divisao;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final temExercicioEmAndamento = widget.controller.temExercicioEmAndamento;
    final exercicioAtual = widget.controller.exercicioAtual;
    final volumeSessao = widget.controller.calcularVolumeSessao(
      incluirAtual: !_descartarAtual,
    );
    final kiVolume = (volumeSessao / 100.0).round();
    final totalPrs = widget.controller.totalRecordesBatidosHoje;
    final kiPrs = totalPrs * 150;
    final kiTotalSessao = kiVolume + kiPrs;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho Premium com Scouter
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: ScouterIcon(
                        size: 22,
                        lensColor: Color(0xFF00E676),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Encerrar Batalha',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: AppColors.textLight,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Consolide seus ganhos e seu Ki da sessão',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textDimmed,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.cardBorder, height: 1),
              const SizedBox(height: 16),

              // Card de Ki Conquistado na Sessão
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.12),
                      AppColors.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.electric_bolt_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '+ KI GERADO NA SESSÃO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                                color: AppColors.textDimmed,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '+${PoderLuta.formatarPoder(kiTotalSessao)} Ki',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Detalhe: Volume
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.fitness_center_rounded,
                                  size: 16,
                                  color: Color(0xFF4FC3F7),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Volume',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textDimmed,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${RecordePessoal.formatarPeso(volumeSessao)} kg (+$kiVolume Ki)',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textLight,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Detalhe: PRs
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.military_tech_rounded,
                                  size: 18,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Recordes (PRs)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textDimmed,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$totalPrs PRs (+$kiPrs Ki)',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textLight,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Banner Comemorativo de Recordes Batidos (PRs)
              if (widget.controller.recordesBatidosHoje.isNotEmpty) ...[
                Builder(
                  builder: (context) {
                    final recordes = widget.controller.recordesBatidosHoje;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.bolt_rounded,
                                  size: 20,
                                  color: AppColors.accent,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '⚡ LIMITES SUPERADOS HOJE!',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.accent,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${recordes.length} ${recordes.length == 1 ? 'exercício superou' : 'exercícios superaram'} a melhor marca histórica',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textDimmed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: recordes.values.map((pr) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      pr.exercicioNome,
                                      style: const TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${RecordePessoal.formatarPeso(pr.cargaMaxima)} kg',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
              ],

              // Alerta Premium de Exercício em Andamento
              if (temExercicioEmAndamento && exercicioAtual != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              size: 18,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'EXERCÍCIO EM ABERTO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.accent,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  exercicioAtual.nome,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textLight,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _descartarAtual = false),
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                height: 40,
                                decoration: BoxDecoration(
                                  color: !_descartarAtual ? AppColors.primary : AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: !_descartarAtual ? AppColors.primary : AppColors.cardBorder,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 16,
                                      color: !_descartarAtual ? AppColors.background : AppColors.textDimmed,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Salvar atual',
                                      style: TextStyle(
                                        color: !_descartarAtual ? AppColors.background : AppColors.textLight,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _descartarAtual = true),
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _descartarAtual ? AppColors.danger : AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _descartarAtual ? AppColors.danger : AppColors.cardBorder,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                      color: _descartarAtual ? Colors.white : AppColors.textDimmed,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Descartar',
                                      style: TextStyle(
                                        color: _descartarAtual ? Colors.white : AppColors.textDimmed,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Seleção de Nome / Divisão do Treino
              const Text(
                'DIVISÃO / NOME DO TREINO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDimmed,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: _divisoesPadrao.map((divisao) {
                  final isSel = _divisaoSelecionada == divisao;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: divisao != _divisoesPadrao.last ? 8.0 : 0.0,
                      ),
                      child: InkWell(
                        onTap: () => _selecionarDivisao(divisao),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 42,
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSel ? AppColors.primary : AppColors.cardBorder,
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            divisao,
                            style: TextStyle(
                              color: isSel ? AppColors.background : AppColors.textLight,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nomeTreinoController,
                style: const TextStyle(color: AppColors.textLight, fontSize: 14, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Ou digite o nome (ex: Peito e Tríceps)',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.textDimmed, size: 20),
                  filled: true,
                  fillColor: AppColors.background,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                onChanged: (val) {
                  if (_divisaoSelecionada != val) {
                    setState(() => _divisaoSelecionada = null);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Card Salvar como Ficha
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _salvarComoFicha ? AppColors.accent.withValues(alpha: 0.6) : AppColors.cardBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Theme(
                      data: Theme.of(context).copyWith(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: SwitchListTile.adaptive(
                        value: _salvarComoFicha,
                        onChanged: (val) => setState(() => _salvarComoFicha = val),
                        activeThumbColor: AppColors.accent,
                        activeTrackColor: AppColors.accent.withValues(alpha: 0.35),
                        inactiveThumbColor: AppColors.textDimmed,
                        inactiveTrackColor: AppColors.surface,
                        title: const Text(
                          'Salvar como Ficha',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: const Text(
                          'Guarda esses exercícios para carregar no futuro',
                          style: TextStyle(
                            color: AppColors.textDimmed,
                            fontSize: 11,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        dense: true,
                      ),
                    ),
                    if (_salvarComoFicha) ...[
                      const Divider(color: AppColors.cardBorder, height: 1),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: _nomeFichaController,
                          style: const TextStyle(color: AppColors.textLight, fontSize: 13, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            labelText: 'Nome da Ficha',
                            labelStyle: const TextStyle(color: AppColors.accent, fontSize: 12),
                            prefixIcon: const Icon(Icons.bookmark_outline_rounded, color: AppColors.accent, size: 18),
                            filled: true,
                            fillColor: AppColors.surface,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.cardBorder),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.cardBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Botões de Ação do Rodapé
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDimmed,
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      final nomeTreinoFinal = _nomeTreinoController.text.trim();
                      final nomeFichaFinal = _nomeFichaController.text.trim();

                      Navigator.pop(
                        context,
                        ResultadoEncerrarTreino(
                          descartarAtual: _descartarAtual,
                          nomeTreino: nomeTreinoFinal.isNotEmpty ? nomeTreinoFinal : null,
                          salvarComoFicha: _salvarComoFicha,
                          nomeFicha: nomeFichaFinal.isNotEmpty ? nomeFichaFinal : nomeTreinoFinal,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text(
                      'Concluir Treino',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
