import 'package:flutter/material.dart';

import '../models/sessao_treino.dart';
import '../theme/app_colors.dart';
import 'modal_ajuste_tempo_sessao.dart';

class ModalEditarSessaoDialog extends StatefulWidget {
  final SessaoTreino sessao;

  const ModalEditarSessaoDialog({
    super.key,
    required this.sessao,
  });

  @override
  State<ModalEditarSessaoDialog> createState() => _ModalEditarSessaoDialogState();
}

class _ModalEditarSessaoDialogState extends State<ModalEditarSessaoDialog> {
  late final TextEditingController _nomeTreinoController;
  late DateTime _data;
  late int _duracaoSegundos;
  late int _descansoTotalSegundos;
  String? _divisaoSelecionada;

  final List<String> _divisoesPadrao = const [
    'Push',
    'Pull',
    'Legs',
  ];

  @override
  void initState() {
    super.initState();
    final nomeAtual = widget.sessao.nomeTreino ?? '';
    _nomeTreinoController = TextEditingController(text: nomeAtual);
    _data = widget.sessao.data ?? DateTime.now();
    _duracaoSegundos = widget.sessao.duracaoSegundos;
    _descansoTotalSegundos = widget.sessao.descansoTotalSegundos;

    if (nomeAtual.isNotEmpty && _divisoesPadrao.contains(nomeAtual)) {
      _divisaoSelecionada = nomeAtual;
    }
  }

  @override
  void dispose() {
    _nomeTreinoController.dispose();
    super.dispose();
  }

  void _selecionarDivisao(String divisao) {
    setState(() {
      if (_divisaoSelecionada == divisao) {
        _divisaoSelecionada = null;
      } else {
        _divisaoSelecionada = divisao;
        _nomeTreinoController.text = divisao;
      }
    });
  }

  String _formatarTempo(int segundos) {
    final h = segundos ~/ 3600;
    final m = (segundos % 3600) ~/ 60;
    final s = segundos % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _selecionarData() async {
    final novaData = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.background,
              surface: AppColors.surface,
              onSurface: AppColors.textLight,
            ),
          ),
          child: child!,
        );
      },
    );

    if (novaData != null && mounted) {
      setState(() {
        _data = DateTime(
          novaData.year,
          novaData.month,
          novaData.day,
          _data.hour,
          _data.minute,
          _data.second,
        );
      });
    }
  }

  Future<void> _abrirAjusteDuracao() async {
    final novoTempo = await ModalAjusteTempoSessao.show(
      context: context,
      titulo: 'DURAÇÃO DO TREINO',
      icone: Icons.timer_outlined,
      corDestaque: AppColors.primary,
      tempoInicialSegundos: _duracaoSegundos,
      isDescanso: false,
    );

    if (novoTempo != null && mounted) {
      setState(() {
        _duracaoSegundos = novoTempo;
        // Validação estrita: o descanso não pode ultrapassar o tempo de treino
        if (_descansoTotalSegundos > _duracaoSegundos) {
          _descansoTotalSegundos = _duracaoSegundos;
        }
      });
    }
  }

  Future<void> _abrirAjusteDescanso() async {
    final novoTempo = await ModalAjusteTempoSessao.show(
      context: context,
      titulo: 'TEMPO DE DESCANSO',
      icone: Icons.snooze_rounded,
      corDestaque: const Color(0xFF00E676),
      tempoInicialSegundos: _descansoTotalSegundos,
      limiteMaximoSegundos: _duracaoSegundos,
      isDescanso: true,
    );

    if (novoTempo != null && mounted) {
      setState(() => _descansoTotalSegundos = novoTempo);
    }
  }

  String _formatarData(DateTime data) {
    const dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year;
    final sem = dias[data.weekday - 1];
    return '$dia/$mes/$ano ($sem)';
  }

  @override
  Widget build(BuildContext context) {
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
                      child: Icon(
                        Icons.edit_calendar_rounded,
                        size: 22,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Editar Treino Salvo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: AppColors.textLight,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Corrija data, divisão ou tempos registrados',
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

              // Seletor de Data
              const Text(
                'DATA DA SESSÃO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDimmed,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _selecionarData,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: AppColors.accent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _formatarData(_data),
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Text(
                        'Alterar',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tempos da Sessão (Duração e Descanso)
              const Text(
                'DURAÇÃO & DESCANSO DA SESSÃO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDimmed,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Duração
                  Expanded(
                    child: InkWell(
                      onTap: _abrirAjusteDuracao,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.timer_outlined,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Duração',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDimmed,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatarTempo(_duracaoSegundos),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: AppColors.textDimmed,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Descanso
                  Expanded(
                    child: InkWell(
                      onTap: _abrirAjusteDescanso,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E676).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.snooze_rounded,
                                size: 16,
                                color: Color(0xFF00E676),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Descanso',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDimmed,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatarTempo(_descansoTotalSegundos),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: AppColors.textDimmed,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Nome / Divisão
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
              const SizedBox(height: 20),

              // Botões
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
                      final sessaoEditada = widget.sessao.copyWith(
                        nomeTreino: nomeTreinoFinal.isNotEmpty ? nomeTreinoFinal : null,
                        data: _data,
                        duracaoSegundos: _duracaoSegundos,
                        descansoTotalSegundos: _descansoTotalSegundos,
                      );
                      Navigator.pop(context, sessaoEditada);
                    },
                    icon: const Icon(Icons.save_rounded, size: 20),
                    label: const Text(
                      'Salvar Alterações',
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
