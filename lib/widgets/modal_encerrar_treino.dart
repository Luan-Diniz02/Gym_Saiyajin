import 'package:flutter/material.dart';

import '../controllers/treino_controller.dart';
import '../theme/app_colors.dart';

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

  const ModalEncerrarTreinoDialog({
    super.key,
    required this.controller,
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
    'Treino A',
    'Treino B',
    'Treino C',
    'Push',
    'Pull',
    'Legs',
    'Superiores',
    'Inferiores',
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
              // Cabeçalho
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sports_score,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Encerrar Treino',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                        Text(
                          'Defina a divisão e conclua sua sessão',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textDimmed,
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

              // Alerta de Exercício em Andamento
              if (temExercicioEmAndamento && exercicioAtual != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Exercício em aberto: ${exercicioAtual.nome}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Salvar atual')),
                              selected: !_descartarAtual,
                              onSelected: (_) => setState(() => _descartarAtual = false),
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.surface,
                              labelStyle: TextStyle(
                                color: !_descartarAtual ? AppColors.background : AppColors.textLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Descartar')),
                              selected: _descartarAtual,
                              onSelected: (_) => setState(() => _descartarAtual = true),
                              selectedColor: AppColors.danger,
                              backgroundColor: AppColors.surface,
                              labelStyle: TextStyle(
                                color: _descartarAtual ? AppColors.textLight : AppColors.textDimmed,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _divisoesPadrao.map((divisao) {
                  final isSel = _divisaoSelecionada == divisao;
                  return ChoiceChip(
                    label: Text(divisao),
                    selected: isSel,
                    onSelected: (_) => _selecionarDivisao(divisao),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.background,
                    labelStyle: TextStyle(
                      color: isSel ? AppColors.background : AppColors.textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isSel ? AppColors.primary : AppColors.cardBorder,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nomeTreinoController,
                style: const TextStyle(color: AppColors.textLight, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ou digite o nome (ex: Peito e Tríceps)',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.background,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
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

              // Checkbox Salvar como Ficha
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _salvarComoFicha ? AppColors.accent.withValues(alpha: 0.5) : AppColors.cardBorder,
                  ),
                ),
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: _salvarComoFicha,
                      onChanged: (val) => setState(() => _salvarComoFicha = val ?? false),
                      title: const Text(
                        'Salvar como Ficha (Template)',
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
                      activeColor: AppColors.accent,
                      checkColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      dense: true,
                    ),
                    if (_salvarComoFicha)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: TextField(
                          controller: _nomeFichaController,
                          style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Nome da Ficha',
                            labelStyle: const TextStyle(color: AppColors.accent, fontSize: 12),
                            filled: true,
                            fillColor: AppColors.surface,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.cardBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Botões de Ação
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: AppColors.textDimmed),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text(
                      'Concluir Treino',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
