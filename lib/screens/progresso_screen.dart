import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/progresso_controller.dart';
import '../services/preferences_service.dart';
import '../theme/app_colors.dart';
import '../widgets/metricas_dashboard_widget.dart';
import '../widgets/progresso_grafico_widget.dart';
import '../widgets/quadro_recordes_modal.dart';

class ProgressoScreen extends StatefulWidget {
  final ProgressoController controller;

  const ProgressoScreen({super.key, required this.controller});

  @override
  State<ProgressoScreen> createState() => _ProgressoScreenState();
}

class _ProgressoScreenState extends State<ProgressoScreen> {
  late final ProgressoController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.carregarDados();
  }

  void _abrirModalAtualizarMedidas() {
    final pesoController = TextEditingController(text: _controller.pesoAtual.toString());
    final alturaController = TextEditingController(text: _controller.altura.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('ATUALIZAR MEDIDAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pesoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Peso (kg)',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: alturaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Altura (m)',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR', style: TextStyle(color: AppColors.textDimmed)),
            ),
            ElevatedButton(
              onPressed: () {
                final novoPeso = double.tryParse(pesoController.text.replaceAll(',', '.')) ?? _controller.pesoAtual;
                final novaAltura = double.tryParse(alturaController.text.replaceAll(',', '.')) ?? _controller.altura;
                _controller.atualizarMedidas(peso: novoPeso, altura: novaAltura);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.background),
              child: const Text('SALVAR', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _abrirModalAtualizarMeta() {
    int metaTemporaria = _controller.metaDiasSemana;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Center(
                child: Text('META SEMANAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Quantos dias você quer treinar?',
                    style: TextStyle(color: AppColors.textDimmed, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (metaTemporaria > 1) setStateModal(() => metaTemporaria--);
                        },
                        icon: const Icon(Icons.remove_circle_outline, size: 32, color: AppColors.primary),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        '$metaTemporaria',
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.accent),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        onPressed: () {
                          if (metaTemporaria < 7) setStateModal(() => metaTemporaria++);
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 32, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCELAR', style: TextStyle(color: AppColors.textDimmed)),
                ),
                ElevatedButton(
                  onPressed: () {
                    _controller.atualizarMetaDiasSemana(metaTemporaria);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                  ),
                  child: const Text('SALVAR', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text(
                  'SEU PROGRESSO',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
                const SizedBox(height: 16),
                _buildSeletorModoApp(),
                const SizedBox(height: 24),
                MetricasDashboardWidget(
                  controller: _controller,
                  onEditarMeta: _abrirModalAtualizarMeta,
                  onEditarMedidas: _abrirModalAtualizarMedidas,
                ),
                const SizedBox(height: 18),
                _buildQuadroRecordesCard(),
                const SizedBox(height: 24),
                ProgressoGraficoWidget(controller: _controller),
                const SizedBox(height: 24),
                _buildPesoCorporalCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSeletorModoApp() {
    final modoAtual = _controller.modoApp;
    final isSaiyajin = modoAtual == PreferencesService.modoAppSaiyajin;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                if (!isSaiyajin) {
                  HapticFeedback.selectionClick();
                  _controller.alternarModoApp(PreferencesService.modoAppSaiyajin);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSaiyajin ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 16,
                      color: isSaiyajin ? AppColors.background : AppColors.textDimmed,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'MODO SAIYAJIN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSaiyajin ? FontWeight.w900 : FontWeight.w600,
                        color: isSaiyajin ? AppColors.background : AppColors.textDimmed,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                if (isSaiyajin) {
                  HapticFeedback.selectionClick();
                  _controller.alternarModoApp(PreferencesService.modoAppAtleta);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !isSaiyajin ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 16,
                      color: !isSaiyajin ? AppColors.background : AppColors.textDimmed,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'MODO ATLETA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: !isSaiyajin ? FontWeight.w900 : FontWeight.w600,
                        color: !isSaiyajin ? AppColors.background : AppColors.textDimmed,
                        letterSpacing: 0.5,
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

  Widget _buildQuadroRecordesCard() {
    final modoAtual = _controller.modoApp;
    final isSaiyajin = modoAtual == PreferencesService.modoAppSaiyajin;
    final total = _controller.totalRecordes;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        QuadroRecordesModal.show(context, _controller.recordesPessoais);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: total > 0
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Icon(
                isSaiyajin ? Icons.military_tech_rounded : Icons.emoji_events_rounded,
                color: AppColors.accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isSaiyajin ? 'HALL DA FAMA ⚡' : 'RECORDES PESSOAIS 🏆',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textLight,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (total > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$total PRs',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    total > 0
                        ? 'Ver maiores cargas e 1RM por exercício'
                        : 'Nenhum recorde registrado ainda',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textDimmed,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textDimmed,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPesoCorporalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PESO ATUAL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text(
                'Última atualização: ${_controller.dataUltimaAtualizacaoFormatada}',
                style: const TextStyle(fontSize: 12, color: AppColors.textDimmed),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '${_controller.pesoAtual.toStringAsFixed(1)} kg',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: _abrirModalAtualizarMedidas,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, color: AppColors.primary, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'EDITAR',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
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
    );
  }
}