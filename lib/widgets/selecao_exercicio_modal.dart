import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SelecaoExercicioModal extends StatefulWidget {
  final void Function(String nome, String grupo) onSelecionarExercicio;

  const SelecaoExercicioModal({
    super.key,
    required this.onSelecionarExercicio,
  });

  @override
  State<SelecaoExercicioModal> createState() => _SelecaoExercicioModalState();
}

class _SelecaoExercicioModalState extends State<SelecaoExercicioModal> {
  String _termoBusca = '';

  final List<Map<String, String>> _exerciciosPadrao = [
    // PEITO
    {'nome': 'Supino Reto', 'grupo': 'PEITO'},
    {'nome': 'Supino Inclinado', 'grupo': 'PEITO'},
    {'nome': 'Supino Declinado', 'grupo': 'PEITO'},
    {'nome': 'Crucifixo', 'grupo': 'PEITO'},
    {'nome': 'Crossover', 'grupo': 'PEITO'},
    {'nome': 'Voador', 'grupo': 'PEITO'},
    // COSTAS
    {'nome': 'Puxada Frontal', 'grupo': 'COSTAS'},
    {'nome': 'Remada Curvada', 'grupo': 'COSTAS'},
    {'nome': 'Remada Baixa', 'grupo': 'COSTAS'},
    {'nome': 'Serrote', 'grupo': 'COSTAS'},
    {'nome': 'Barra Fixa', 'grupo': 'COSTAS'},
    // PERNAS
    {'nome': 'Agachamento Livre', 'grupo': 'PERNAS'},
    {'nome': 'Leg Press 45', 'grupo': 'PERNAS'},
    {'nome': 'Cadeira Extensora', 'grupo': 'PERNAS'},
    {'nome': 'Cadeira Flexora', 'grupo': 'PERNAS'},
    {'nome': 'Mesa Flexora', 'grupo': 'PERNAS'},
    {'nome': 'Panturrilha Máquina', 'grupo': 'PERNAS'},
    {'nome': 'Elevacao Pélvica', 'grupo': 'PERNAS'},
    // OMBROS
    {'nome': 'Desenvolvimento Halteres', 'grupo': 'OMBROS'},
    {'nome': 'Elevação Lateral', 'grupo': 'OMBROS'},
    {'nome': 'Elevação Frontal', 'grupo': 'OMBROS'},
    // BÍCEPS E TRÍCEPS
    {'nome': 'Rosca Direta', 'grupo': 'BÍCEPS'},
    {'nome': 'Rosca Martelo', 'grupo': 'BÍCEPS'},
    {'nome': 'Tríceps Polia', 'grupo': 'TRÍCEPS'},
    {'nome': 'Tríceps Testa', 'grupo': 'TRÍCEPS'},
    {'nome': 'Tríceps Francês', 'grupo': 'TRÍCEPS'},
    // ABDÔMEN
    {'nome': 'Abdominal Supra', 'grupo': 'ABDÔMEN'},
    {'nome': 'Prancha', 'grupo': 'ABDÔMEN'},
  ];

  List<Map<String, String>> get _exerciciosFiltrados {
    final termo = _termoBusca.trim().toLowerCase();
    if (termo.isEmpty) return _exerciciosPadrao;

    return _exerciciosPadrao.where((exercicio) {
      final nome = (exercicio['nome'] ?? '').toLowerCase();
      final grupo = (exercicio['grupo'] ?? '').toLowerCase();
      return nome.contains(termo) || grupo.contains(termo);
    }).toList();
  }

  bool get _deveExibirCriarNovo {
    final termo = _termoBusca.trim();
    if (termo.isEmpty) return false;

    final termoNormalizado = termo.toLowerCase();
    final temResultadoExato = _exerciciosFiltrados.any(
      (exercicio) => (exercicio['nome'] ?? '').toLowerCase() == termoNormalizado,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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

    Navigator.pop(context);
    widget.onSelecionarExercicio(nomeNovoExercicio, grupoSelecionado);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
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
                const Text('SELECIONE O EXERCÍCIO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              decoration: InputDecoration(
                hintText: 'Buscar exercício...',
                hintStyle: const TextStyle(color: AppColors.textDimmed),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
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
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(grupo, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                    trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary),
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
      ),
    );
  }
}
