import 'package:flutter/material.dart';

import '../models/recorde_pessoal.dart';
import '../services/preferences_service.dart';
import '../theme/app_colors.dart';

/// Modal estilizado para visualização dos Recordes Pessoais (PRs) / Hall da Fama.
class QuadroRecordesModal extends StatefulWidget {
  final List<RecordePessoal> recordes;

  const QuadroRecordesModal({
    super.key,
    required this.recordes,
  });

  static Future<void> show(BuildContext context, List<RecordePessoal> recordes) {
    return showDialog(
      context: context,
      builder: (context) => QuadroRecordesModal(recordes: recordes),
    );
  }

  @override
  State<QuadroRecordesModal> createState() => _QuadroRecordesModalState();
}

class _QuadroRecordesModalState extends State<QuadroRecordesModal> {
  final TextEditingController _buscaController = TextEditingController();
  String _grupoSelecionado = 'TODOS';
  String _filtroTexto = '';

  final List<String> _grupos = const [
    'TODOS',
    'PEITO',
    'COSTAS',
    'PERNAS',
    'OMBROS',
    'BRAÇOS',
    'BÍCEPS',
    'TRÍCEPS',
    'ABDÔMEN',
  ];

  @override
  void initState() {
    super.initState();
    _buscaController.addListener(() {
      setState(() {
        _filtroTexto = _buscaController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  List<RecordePessoal> get _recordesFiltrados {
    return widget.recordes.where((pr) {
      final matchTexto = _filtroTexto.isEmpty ||
          pr.exercicioNome.toLowerCase().contains(_filtroTexto);

      final matchGrupo = _grupoSelecionado == 'TODOS' ||
          pr.grupo.toUpperCase().contains(_grupoSelecionado) ||
          (_grupoSelecionado == 'BRAÇOS' &&
              (pr.grupo.toUpperCase().contains('BÍCEPS') ||
                  pr.grupo.toUpperCase().contains('TRÍCEPS') ||
                  pr.grupo.toUpperCase().contains('ANTEBRAÇO')));

      return matchTexto && matchGrupo;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final modoApp = PreferencesService.modoAppNotifier.value;
    final isSaiyajin = modoApp == PreferencesService.modoAppSaiyajin;
    final total = widget.recordes.length;
    final filtrados = _recordesFiltrados;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho Premium
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
                    child: Icon(
                      isSaiyajin
                          ? Icons.military_tech_rounded
                          : Icons.emoji_events_rounded,
                      color: AppColors.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSaiyajin ? 'HALL DA FAMA ⚡' : 'RECORDES PESSOAIS 🏆',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$total ${total == 1 ? 'exercício com marca' : 'exercícios com marcas registradas'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textDimmed,
                          ),
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
              const SizedBox(height: 14),

              // Campo de Busca
              TextField(
                controller: _buscaController,
                style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar exercício por nome...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textDimmed, size: 20),
                  suffixIcon: _buscaController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textDimmed, size: 18),
                          onPressed: () => _buscaController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.background,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

              const SizedBox(height: 12),

              // Chips de Filtro por Grupo Muscular
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _grupos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final grupo = _grupos[i];
                    final isSel = _grupoSelecionado == grupo;
                    return InkWell(
                      onTap: () => setState(() => _grupoSelecionado = grupo),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSel ? AppColors.primary : AppColors.cardBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            grupo,
                            style: TextStyle(
                              color: isSel ? AppColors.background : AppColors.textLight,
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Lista de Recordes ou Empty State
              Expanded(
                child: filtrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Icon(
                                Icons.emoji_events_outlined,
                                size: 32,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              total == 0
                                  ? 'NENHUM RECORDE AINDA'
                                  : 'NENHUM EXERCÍCIO ENCONTRADO',
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                total == 0
                                    ? (isSaiyajin
                                        ? 'Conclua suas séries nos treinos para gravar seu poder no Hall da Fama!'
                                        : 'Conclua suas séries nos treinos para registrar seus recordes de carga e 1RM!')
                                    : 'Tente alterar os termos da busca ou selecionar outro grupo muscular.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textDimmed,
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtrados.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final pr = filtrados[index];
                          return _buildCardRecorde(pr);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardRecorde(RecordePessoal pr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome do Exercício + Badge de Grupo
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  pr.exercicioNome,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (pr.grupo.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    pr.grupo.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textDimmed,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Painel Duplo: Carga Máxima & 1RM Estimado
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                // Carga Máxima
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CARGA MÁXIMA',
                        style: TextStyle(
                          color: AppColors.textDimmed,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${RecordePessoal.formatarPeso(pr.cargaMaxima)} kg',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '× ${pr.repsCargaMaxima}',
                            style: const TextStyle(
                              color: AppColors.textDimmed,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Container(
                  height: 32,
                  width: 1,
                  color: AppColors.cardBorder,
                ),

                const SizedBox(width: 12),

                // 1RM Estimado
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1RM ESTIMADO',
                        style: TextStyle(
                          color: AppColors.textDimmed,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${RecordePessoal.formatarPeso(pr.umRepMaxEstimado)} kg',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${RecordePessoal.formatarPeso(pr.peso1RM)}×${pr.reps1RM})',
                            style: const TextStyle(
                              color: AppColors.textDimmed,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Data do Recorde (se disponível)
          if (pr.dataRecorde != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event_available_outlined, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 5),
                Text(
                  'Recorde registrado em ${_formatarData(pr.dataRecorde!)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();
    return '$dia/$mes/$ano';
  }
}
