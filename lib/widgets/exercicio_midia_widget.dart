import 'package:flutter/material.dart';

import '../models/catalogo_exercicios.dart';
import '../theme/app_colors.dart';

/// Miniatura em container arredondado para exibição em listas e cabeçalhos.
///
/// Para exercícios do catálogo padrão, exibe a miniatura estática (`.jpg`) em um
/// card branco arredondado com borda Saiyajin. Ao tocar (se [abrirModalAoTocar]
/// for `true`), abre o [ExercicioDetalheModal] com o GIF animado sob demanda.
class ExercicioThumbnailWidget extends StatelessWidget {
  final String nomeExercicio;
  final String? grupo;
  final double size;
  final double borderRadius;
  final bool abrirModalAoTocar;
  final bool exibirIndicadorGif;

  const ExercicioThumbnailWidget({
    super.key,
    required this.nomeExercicio,
    this.grupo,
    this.size = 46,
    this.borderRadius = 12,
    this.abrirModalAoTocar = true,
    this.exibirIndicadorGif = false,
  });

  @override
  Widget build(BuildContext context) {
    final info = CatalogoExercicios.buscarPorNome(nomeExercicio);

    if (info == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Icon(
          Icons.fitness_center_rounded,
          color: AppColors.primary.withValues(alpha: 0.75),
          size: size * 0.46,
        ),
      );
    }

    final Widget thumbContainer = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular((borderRadius - 1.2).clamp(2.0, 30.0)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: Image.asset(
                info.thumbAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.fitness_center_rounded,
                  color: AppColors.primary,
                  size: size * 0.48,
                ),
              ),
            ),
            if (exibirIndicadorGif)
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.6),
                      width: 0.8,
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 10,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (!abrirModalAoTocar) {
      return thumbContainer;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ExercicioDetalheModal.show(context, info),
      child: Tooltip(
        message: 'Ver execução de ${info.nome}',
        child: thumbContainer,
      ),
    );
  }
}

/// Modal sob demanda com o GIF animado (180×180), músculos recrutados,
/// equipamento e instruções passo a passo de execução.
class ExercicioDetalheModal extends StatelessWidget {
  final InfoExercicioCatalogo info;

  const ExercicioDetalheModal({
    super.key,
    required this.info,
  });

  static Future<void> show(BuildContext context, InfoExercicioCatalogo info) {
    return showDialog(
      context: context,
      builder: (context) => ExercicioDetalheModal(info: info),
    );
  }

  static Future<void> showPorNome(BuildContext context, String nomeExercicio) {
    final info = CatalogoExercicios.buscarPorNome(nomeExercicio);
    if (info == null) return Future.value();
    return show(context, info);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            info.grupo.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          info.nome,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textLight,
                            letterSpacing: 0.4,
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

              // Container Arredondado com o GIF Animado (180x180 nativo)
              Center(
                child: Container(
                  width: 196,
                  height: 196,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.65),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      info.gifAsset,
                      width: 180,
                      height: 180,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        info.thumbAsset,
                        width: 180,
                        height: 180,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.fitness_center_rounded,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                InfoExercicioCatalogo.atribuicao,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 16),

              // Metadados (Equipamento + Músculo Alvo + Sinergistas)
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
                      children: [
                        Expanded(
                          child: _buildMetaItem(
                            icon: Icons.handyman_outlined,
                            label: 'EQUIPAMENTO',
                            valor: info.equipamento,
                            corValor: AppColors.textLight,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: AppColors.cardBorder,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        Expanded(
                          child: _buildMetaItem(
                            icon: Icons.my_location_rounded,
                            label: 'MÚSCULO ALVO',
                            valor: info.musculoAlvo,
                            corValor: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    if (info.musculosSecundarios.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: AppColors.cardBorder, height: 1),
                      ),
                      const Text(
                        'SINERGISTAS / SECUNDÁRIOS',
                        style: TextStyle(
                          color: AppColors.textDimmed,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: info.musculosSecundarios.map((m) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Text(
                              m,
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Instruções Passo a Passo
              const Text(
                'EXECUÇÃO TÉCNICA',
                style: TextStyle(
                  color: AppColors.textDimmed,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 8),
              ...info.instrucoes.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final texto = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$idx',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          texto,
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 13,
                            height: 1.38,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'ENTENDIDO',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String label,
    required String valor,
    required Color corValor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textDimmed,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            color: corValor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
