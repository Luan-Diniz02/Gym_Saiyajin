import 'package:flutter/material.dart';

import '../controllers/treino_controller.dart';
import '../theme/app_colors.dart';

class SelecaoExercicioModal extends StatelessWidget {
  final TreinoController controller;

  const SelecaoExercicioModal({
    super.key,
    required this.controller,
  });

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
                itemCount: controller.exerciciosCadastrados.length,
                separatorBuilder: (context, index) => const Divider(color: AppColors.background),
                itemBuilder: (context, index) {
                  final ex = controller.exerciciosCadastrados[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(ex.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(ex.grupo, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                    trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                    onTap: () {
                      controller.iniciarNovoExercicio(ex.nome, ex.grupo);
                      Navigator.pop(context);
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
