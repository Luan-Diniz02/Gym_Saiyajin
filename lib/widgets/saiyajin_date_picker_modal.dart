import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Modal de seleção de data padronizado no Design System Saiyajin (100% PT-BR, Domingo a Sábado).
class SaiyajinDatePickerModal extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String titulo;

  const SaiyajinDatePickerModal({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.titulo = 'SELECIONAR DATA',
  });

  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    String titulo = 'SELECIONAR DATA',
  }) {
    return showDialog<DateTime>(
      context: context,
      builder: (context) => SaiyajinDatePickerModal(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        titulo: titulo,
      ),
    );
  }

  @override
  State<SaiyajinDatePickerModal> createState() =>
      _SaiyajinDatePickerModalState();
}

class _SaiyajinDatePickerModalState extends State<SaiyajinDatePickerModal> {
  static const List<String> _nomesMeses = [
    'JANEIRO',
    'FEVEREIRO',
    'MARÇO',
    'ABRIL',
    'MAIO',
    'JUNHO',
    'JULHO',
    'AGOSTO',
    'SETEMBRO',
    'OUTUBRO',
    'NOVEMBRO',
    'DEZEMBRO',
  ];

  static const List<String> _diasSemanaLabels = [
    'DOM',
    'SEG',
    'TER',
    'QUA',
    'QUI',
    'SEX',
    'SÁB',
  ];

  late DateTime _dataSelecionada;
  late DateTime _mesExibido;

  @override
  void initState() {
    super.initState();
    _dataSelecionada = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _mesExibido = DateTime(_dataSelecionada.year, _dataSelecionada.month, 1);
  }

  bool _podeIrMesAnterior() {
    final mesMinimo = DateTime(widget.firstDate.year, widget.firstDate.month, 1);
    return _mesExibido.isAfter(mesMinimo);
  }

  bool _podeIrProximoMes() {
    final mesMaximo = DateTime(widget.lastDate.year, widget.lastDate.month, 1);
    return _mesExibido.isBefore(mesMaximo);
  }

  void _navegarMes(int delta) {
    if (delta < 0 && !_podeIrMesAnterior()) return;
    if (delta > 0 && !_podeIrProximoMes()) return;
    HapticFeedback.selectionClick();
    setState(() {
      _mesExibido = DateTime(_mesExibido.year, _mesExibido.month + delta, 1);
    });
  }

  bool _diaPermitido(DateTime data) {
    final min = DateTime(
      widget.firstDate.year,
      widget.firstDate.month,
      widget.firstDate.day,
    );
    final max = DateTime(
      widget.lastDate.year,
      widget.lastDate.month,
      widget.lastDate.day,
    );
    return !data.isBefore(min) && !data.isAfter(max);
  }

  @override
  Widget build(BuildContext context) {
    final ano = _mesExibido.year;
    final mes = _mesExibido.month;
    final totalDiasNoMes = DateTime(ano, mes + 1, 0).day;
    // Domingo = 0, Segunda = 1, ..., Sábado = 6
    final offsetPrimeiroDia = DateTime(ano, mes, 1).weekday % 7;
    final totalCelulas = offsetPrimeiroDia + totalDiasNoMes;
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho padronizado
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.titulo,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_dataSelecionada.day.toString().padLeft(2, '0')}/${_dataSelecionada.month.toString().padLeft(2, '0')}/${_dataSelecionada.year}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_diaPermitido(hoje) &&
                      (_dataSelecionada.year != hoje.year ||
                          _dataSelecionada.month != hoje.month ||
                          _dataSelecionada.day != hoje.day))
                    TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _dataSelecionada = hoje;
                          _mesExibido = DateTime(hoje.year, hoje.month, 1);
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'HOJE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: AppColors.cardBorder, height: 1),
              const SizedBox(height: 10),
              // Navegação do mês
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed:
                        _podeIrMesAnterior() ? () => _navegarMes(-1) : null,
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: _podeIrMesAnterior()
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    '${_nomesMeses[mes - 1]} $ano',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: AppColors.textLight,
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _podeIrProximoMes() ? () => _navegarMes(1) : null,
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: _podeIrProximoMes()
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Dias da semana (DOM a SÁB)
              Row(
                children: _diasSemanaLabels
                    .map(
                      (label) => Expanded(
                        child: Center(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDimmed,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              // Grade de dias
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalCelulas,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 6,
                  mainAxisExtent: 36,
                ),
                itemBuilder: (context, index) {
                  if (index < offsetPrimeiroDia) {
                    return const SizedBox.shrink();
                  }
                  final dia = index - offsetPrimeiroDia + 1;
                  final dataCelula = DateTime(ano, mes, dia);
                  final permitido = _diaPermitido(dataCelula);
                  final isSelecionado = _dataSelecionada.year == ano &&
                      _dataSelecionada.month == mes &&
                      _dataSelecionada.day == dia;
                  final isHoje = hoje.year == ano &&
                      hoje.month == mes &&
                      hoje.day == dia;

                  return GestureDetector(
                    onTap: permitido
                        ? () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _dataSelecionada = dataCelula;
                            });
                          }
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelecionado
                            ? AppColors.primary
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isHoje && !isSelecionado
                            ? Border.all(
                                color: AppColors.primary.withValues(alpha: 0.6),
                                width: 1.2,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$dia',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelecionado || isHoje
                              ? FontWeight.w900
                              : FontWeight.w600,
                          color: !permitido
                              ? AppColors.textMuted.withValues(alpha: 0.4)
                              : (isSelecionado
                                  ? AppColors.background
                                  : (isHoje
                                      ? AppColors.primary
                                      : AppColors.textLight)),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              // Botões padronizados lado a lado
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, null),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.background,
                          foregroundColor: AppColors.textLight,
                          side: const BorderSide(
                            color: AppColors.buttonBorder,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'CANCELAR',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context, _dataSelecionada),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'CONFIRMAR',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
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
