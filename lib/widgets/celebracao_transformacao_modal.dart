import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/poder_luta.dart';
import '../theme/app_colors.dart';
import 'scouter_icon.dart';

/// Modal comemorativo exibido quando o usuário desperta uma nova transformação (Level-Up).
class CelebracaoTransformacaoModal extends StatefulWidget {
  final TransformacaoSaiyajin novaTransformacao;

  const CelebracaoTransformacaoModal({
    super.key,
    required this.novaTransformacao,
  });

  @override
  State<CelebracaoTransformacaoModal> createState() =>
      _CelebracaoTransformacaoModalState();
}

class _CelebracaoTransformacaoModalState
    extends State<CelebracaoTransformacaoModal> {
  @override
  void initState() {
    super.initState();
    _dispararImpacto();
  }

  Future<void> _dispararImpacto() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 160));
    await HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final transformacao = widget.novaTransformacao;
    final corAura = transformacao.corAura;
    final corSecundaria = transformacao.corSecundaria;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                corAura.withValues(alpha: 0.9),
                corSecundaria.withValues(alpha: 0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: corAura.withValues(alpha: 0.40),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: corSecundaria.withValues(alpha: 0.25),
                blurRadius: 40,
                spreadRadius: 4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emblema Central de Energia / Scouter
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        corAura.withValues(alpha: 0.25),
                        corSecundaria.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: corAura.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: ScouterIcon(
                      size: 34,
                      lensColor: corAura,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Tag de Patamar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: corAura.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: corAura.withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'NOVO PATAMAR ALCANÇADO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: corAura,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Nome da Transformação em Destaque
                Text(
                  transformacao.titulo.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: AppColors.textLight,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtítulo de Lore
                Text(
                  transformacao.subtituloLore,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDimmed,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),

                // Pilar de Poder do Patamar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.military_tech_rounded,
                        size: 18,
                        color: transformacao.corBadge,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Patamar de Poder: ${PoderLuta.formatarPoder(transformacao.poderMinimo)} Ki',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Botão de Ação Sóbrio e Imponente
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: corAura,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'CONTINUAR EVOLUINDO',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
