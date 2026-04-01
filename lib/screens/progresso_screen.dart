import 'package:flutter/material.dart';

import '../controllers/progresso_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/metricas_dashboard_widget.dart';
import '../widgets/progresso_grafico_widget.dart';

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

  // --- MODAL DE MEDIDAS ---
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
                const SizedBox(height: 30),
                MetricasDashboardWidget(
                  controller: _controller,
                  onEditarMeta: _abrirModalAtualizarMeta,
                ),
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

  // --- CARD DE PESO COM BOTÃO DE EDITAR ---
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
              Text('PESO ATUAL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text(
                'Última atualização: ${_controller.dataUltimaAtualizacaoFormatada}',
                style: TextStyle(fontSize: 12, color: AppColors.textDimmed),
              ),
            ],
          ),
          Row(
            children: [
              Text('${_controller.pesoAtual.toStringAsFixed(1)} kg', 
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.accent)),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.textDimmed, size: 20),
                onPressed: _abrirModalAtualizarMedidas, // Abre o modal
              )
            ],
          ),
        ],
      ),
    );
  }
}