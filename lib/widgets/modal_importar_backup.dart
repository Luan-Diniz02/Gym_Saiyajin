import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Modal estilizado no padrão Saiyajin para importação e restauração de backups.
class ModalImportarBackupDialog extends StatefulWidget {
  const ModalImportarBackupDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => const ModalImportarBackupDialog(),
    );
  }

  @override
  State<ModalImportarBackupDialog> createState() => _ModalImportarBackupDialogState();
}

class _ModalImportarBackupDialogState extends State<ModalImportarBackupDialog> {
  String _modoSelecionado = 'mesclar'; // 'mesclar' ou 'substituir'

  @override
  Widget build(BuildContext context) {
    final isSubstituir = _modoSelecionado == 'substituir';

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho Premium
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.settings_backup_restore_rounded,
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
                          'IMPORTAR BACKUP',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: AppColors.textLight,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Selecione como aplicar os dados ao histórico',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textDimmed,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, null),
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
              const SizedBox(height: 16),

              // Opção 1: Mesclar Dados (Recomendado)
              _buildOpcaoCard(
                modo: 'mesclar',
                titulo: 'Mesclar Dados',
                badgeText: 'RECOMENDADO',
                badgeColor: AppColors.accent,
                descricao:
                    'Adiciona os treinos do backup mantendo os registros já existentes no aparelho. Evita treinos duplicados.',
                icone: Icons.merge_type_rounded,
                iconeCor: AppColors.accent,
                ativo: !isSubstituir,
              ),

              const SizedBox(height: 12),

              // Opção 2: Substituir Tudo (Cuidado)
              _buildOpcaoCard(
                modo: 'substituir',
                titulo: 'Substituir Tudo',
                badgeText: 'CUIDADO',
                badgeColor: AppColors.danger,
                descricao:
                    'Apaga o histórico local existente e substitui integralmente pelos treinos contidos no backup.',
                icone: Icons.warning_amber_rounded,
                iconeCor: AppColors.danger,
                ativo: isSubstituir,
                isPerigoso: true,
              ),

              const SizedBox(height: 20),

              // Botão de Confirmação Primário
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context, _modoSelecionado);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSubstituir ? AppColors.danger : AppColors.primary,
                  foregroundColor: isSubstituir ? Colors.white : AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: Icon(
                  isSubstituir ? Icons.delete_forever_rounded : Icons.file_download_outlined,
                  size: 20,
                ),
                label: Text(
                  isSubstituir ? 'SUBSTITUIR E IMPORTAR' : 'MESCLAR E IMPORTAR',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpcaoCard({
    required String modo,
    required String titulo,
    required String badgeText,
    required Color badgeColor,
    required String descricao,
    required IconData icone,
    required Color iconeCor,
    required bool ativo,
    bool isPerigoso = false,
  }) {
    final borderColor = ativo
        ? (isPerigoso ? AppColors.danger : AppColors.primary)
        : AppColors.cardBorder;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _modoSelecionado = modo);
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: ativo ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconeCor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: iconeCor.withValues(alpha: 0.25),
                ),
              ),
              child: Icon(icone, color: iconeCor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descricao,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textDimmed,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              ativo ? Icons.radio_button_checked : Icons.radio_button_off,
              color: ativo
                  ? (isPerigoso ? AppColors.danger : AppColors.primary)
                  : AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
