import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Grupo sequencial de anilhas adjacentes de mesmo peso na ponteira.
class GrupoSequencialAnilha {
  final double peso;
  final int quantidade;

  const GrupoSequencialAnilha({
    required this.peso,
    required this.quantidade,
  });
}

/// Resultado da decomposição de carga em barra e anilhas por lado.
class ResultadoDecomposicaoAnilhas {
  final double pesoBarra;
  final List<double> anilhasPorLado;
  final double restoPorLado;

  const ResultadoDecomposicaoAnilhas({
    required this.pesoBarra,
    required this.anilhasPorLado,
    this.restoPorLado = 0.0,
  });

  double get pesoPorLado =>
      anilhasPorLado.fold<double>(0.0, (soma, a) => soma + a);

  double get pesoTotalMontado => pesoBarra + (pesoPorLado * 2.0);

  /// Agrupa as anilhas de um lado por peso: `{20.0: 2, 10.0: 1}`.
  Map<double, int> get contagemPorAnilha {
    final mapa = <double, int>{};
    for (final a in anilhasPorLado) {
      mapa[a] = (mapa[a] ?? 0) + 1;
    }
    return mapa;
  }
}

/// Motor matemático para cálculo e decomposição de anilhas.
class CalculadoraAnilhas {
  CalculadoraAnilhas._();

  static const List<double> anilhasPadrao = [
    25.0,
    20.0,
    15.0,
    10.0,
    5.0,
    2.5,
    1.25,
  ];

  static const List<double> barrasPadrao = [
    20.0,
    15.0,
    10.0,
    0.0,
  ];

  static String formatarPeso(double valor) {
    if (valor % 1 == 0) {
      return valor.toInt().toString();
    }
    final duasCasas = valor.toStringAsFixed(2);
    if (duasCasas.endsWith('0')) {
      return valor.toStringAsFixed(1);
    }
    return duasCasas;
  }

  /// Decompõe um `pesoTotal` alvo na combinação ótima de anilhas por lado.
  static ResultadoDecomposicaoAnilhas decomporCarga({
    required double pesoTotal,
    required double pesoBarra,
    List<double> anilhasDisponiveis = anilhasPadrao,
  }) {
    if (pesoTotal <= pesoBarra) {
      return ResultadoDecomposicaoAnilhas(
        pesoBarra: pesoBarra,
        anilhasPorLado: const [],
        restoPorLado: 0.0,
      );
    }

    double restante = (pesoTotal - pesoBarra) / 2.0;
    final selecionadas = <double>[];
    final ordenadas = List<double>.from(anilhasDisponiveis)
      ..sort((a, b) => b.compareTo(a));

    for (final anilha in ordenadas) {
      if (anilha <= 0) continue;
      while (restante + 1e-6 >= anilha) {
        selecionadas.add(anilha);
        restante -= anilha;
        if (selecionadas.length >= 20) break;
      }
    }

    final restoFinal = restante < 0.01 ? 0.0 : restante;
    return ResultadoDecomposicaoAnilhas(
      pesoBarra: pesoBarra,
      anilhasPorLado: selecionadas,
      restoPorLado: restoFinal,
    );
  }

  /// Cor única padronizada no Design System Saiyajin para evitar sobrecarga cognitiva.
  static Color corDaAnilha(double peso) => AppColors.primary;
}

/// Modal interativo da Calculadora de Anilhas e Barra (Proposta 5).
class CalculadoraAnilhasModal extends StatefulWidget {
  final double? pesoInicial;
  final double pesoBarraInicial;

  const CalculadoraAnilhasModal({
    super.key,
    this.pesoInicial,
    this.pesoBarraInicial = 20.0,
  });

  static Future<double?> show({
    required BuildContext context,
    double? pesoInicial,
    double pesoBarraInicial = 20.0,
  }) {
    return showDialog<double>(
      context: context,
      builder: (context) => CalculadoraAnilhasModal(
        pesoInicial: pesoInicial,
        pesoBarraInicial: pesoBarraInicial,
      ),
    );
  }

  @override
  State<CalculadoraAnilhasModal> createState() =>
      _CalculadoraAnilhasModalState();
}

class _CalculadoraAnilhasModalState extends State<CalculadoraAnilhasModal> {
  late double _pesoBarra;
  late List<double> _anilhasPorLado;
  late final TextEditingController _pesoAlvoController;
  late final FocusNode _pesoAlvoFocusNode;

  @override
  void initState() {
    super.initState();
    _pesoBarra = widget.pesoBarraInicial;
    final alvoInicial = (widget.pesoInicial != null && widget.pesoInicial! > 0)
        ? widget.pesoInicial!
        : _pesoBarra;

    if (alvoInicial > 0 && alvoInicial < _pesoBarra) {
      _pesoBarra = 0.0;
    }

    final decomposicao = CalculadoraAnilhas.decomporCarga(
      pesoTotal: alvoInicial,
      pesoBarra: _pesoBarra,
    );
    _anilhasPorLado = List<double>.from(decomposicao.anilhasPorLado);
    _pesoAlvoController = TextEditingController(
      text: CalculadoraAnilhas.formatarPeso(_pesoTotalAtual),
    );
    _pesoAlvoFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _pesoAlvoController.dispose();
    _pesoAlvoFocusNode.dispose();
    super.dispose();
  }

  double get _pesoPorLadoAtual =>
      _anilhasPorLado.fold<double>(0.0, (soma, a) => soma + a);

  double get _pesoTotalAtual => _pesoBarra + (_pesoPorLadoAtual * 2.0);

  void _sincronizarCampoTexto() {
    if (!_pesoAlvoFocusNode.hasFocus) {
      final texto = CalculadoraAnilhas.formatarPeso(_pesoTotalAtual);
      if (_pesoAlvoController.text != texto) {
        _pesoAlvoController.text = texto;
      }
    }
  }

  void _selecionarPesoBarra(double novoPesoBarra) {
    HapticFeedback.selectionClick();
    setState(() {
      _pesoBarra = novoPesoBarra;
      _sincronizarCampoTexto();
    });
  }

  /// Adiciona a anilha respeitando estritamente a ordem em que foi clicada (de dentro para fora).
  void _adicionarAnilhaPorLado(double pesoAnilha) {
    if (_anilhasPorLado.length >= 12) return;
    HapticFeedback.lightImpact();
    setState(() {
      _anilhasPorLado.add(pesoAnilha);
      _sincronizarCampoTexto();
    });
  }

  /// Remove a última ocorrência daquela anilha (a mais externa da barra).
  void _removerAnilhaPorLado(double pesoAnilha) {
    HapticFeedback.selectionClick();
    setState(() {
      final idx = _anilhasPorLado.lastIndexOf(pesoAnilha);
      if (idx != -1) {
        _anilhasPorLado.removeAt(idx);
        _sincronizarCampoTexto();
      }
    });
  }

  void _limparAnilhas() {
    HapticFeedback.selectionClick();
    setState(() {
      _anilhasPorLado.clear();
      _sincronizarCampoTexto();
    });
  }

  void _aoDigitarPesoAlvo(String valor) {
    final limpo = valor.replaceAll(',', '.').trim();
    final parsed = double.tryParse(limpo);
    if (parsed == null || parsed < 0) return;

    setState(() {
      final decomposicao = CalculadoraAnilhas.decomporCarga(
        pesoTotal: parsed,
        pesoBarra: _pesoBarra,
      );
      _anilhasPorLado = List<double>.from(decomposicao.anilhasPorLado);
    });
  }

  /// Agrupa anilhas adjacentes mantendo a ordem exata em que foram adicionadas.
  List<GrupoSequencialAnilha> get _gruposNaOrdemAdicionada {
    final grupos = <GrupoSequencialAnilha>[];
    for (final peso in _anilhasPorLado) {
      if (grupos.isNotEmpty && grupos.last.peso == peso) {
        final ultimo = grupos.removeLast();
        grupos.add(
          GrupoSequencialAnilha(
            peso: ultimo.peso,
            quantidade: ultimo.quantidade + 1,
          ),
        );
      } else {
        grupos.add(GrupoSequencialAnilha(peso: peso, quantidade: 1));
      }
    }
    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    final gruposSequenciais = _gruposNaOrdemAdicionada;
    final chavesJaUsadas = <double>{};

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho Padronizado Fixo
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
                      Icons.fitness_center_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CALCULADORA DE ANILHAS',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                            color: AppColors.textLight,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Decomposição bilateral e montagem rápida',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textDimmed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_anilhasPorLado.isNotEmpty)
                    TextButton(
                      key: const Key('btn-limpar-anilhas'),
                      onPressed: _limparAnilhas,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'LIMPAR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.cardBorder, height: 1),
              const SizedBox(height: 12),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Visor de Carga Total & Decomposição
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'CARGA TOTAL MONTADA',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDimmed,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        CalculadoraAnilhas.formatarPeso(
                                          _pesoTotalAtual,
                                        ),
                                        key: const Key(
                                          'texto-peso-total-anilhas',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'kg',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textDimmed,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _pesoBarra > 0
                                        ? 'Barra ${CalculadoraAnilhas.formatarPeso(_pesoBarra)} kg + ${CalculadoraAnilhas.formatarPeso(_pesoPorLadoAtual)} kg cada lado'
                                        : '${CalculadoraAnilhas.formatarPeso(_pesoPorLadoAtual)} kg cada lado (Só Anilhas)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 92,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'CALCULAR KG',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDimmed,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    height: 40,
                                    child: TextField(
                                      key: const Key('input-peso-alvo-anilhas'),
                                      controller: _pesoAlvoController,
                                      focusNode: _pesoAlvoFocusNode,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textLight,
                                      ),
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                        filled: true,
                                        fillColor: AppColors.surface,
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                            color: AppColors.buttonBorder,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                            color: AppColors.primary,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      onChanged: _aoDigitarPesoAlvo,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Seletor de Peso da Barra
                      const Text(
                        'PESO DA BARRA / EQUIPAMENTO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDimmed,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: CalculadoraAnilhas.barrasPadrao
                            .map((pesoBarra) {
                          final selecionado = _pesoBarra == pesoBarra;
                          final label = pesoBarra == 0.0
                              ? 'SÓ ANILHAS'
                              : '${pesoBarra.toInt()} KG';
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: pesoBarra != 0.0 ? 6.0 : 0.0,
                              ),
                              child: GestureDetector(
                                key: Key('chip-barra-${pesoBarra.toInt()}'),
                                onTap: () => _selecionarPesoBarra(pesoBarra),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 7),
                                  decoration: BoxDecoration(
                                    color: selecionado
                                        ? AppColors.primary
                                        : AppColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selecionado
                                          ? AppColors.primary
                                          : AppColors.buttonBorder,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      color: selecionado
                                          ? AppColors.background
                                          : AppColors.textLight,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),

                      // Ilustração Vetorial da Barra Simétrica Completa (Ambos os lados)
                      Container(
                        height: 76,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: CustomPaint(
                          painter: BarraAnilhasPainter(
                            anilhasPorLado: _anilhasPorLado,
                            pesoBarra: _pesoBarra,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),

                      const SizedBox(height: 8),
                      // Faixa de altura estável para chips de anilhas montadas (evita pulo de layout)
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 28),
                        child: Center(
                          child: gruposSequenciais.isEmpty
                              ? const Text(
                                  'Toque nos pesos abaixo para adicionar em ambos os lados',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  alignment: WrapAlignment.center,
                                  children: gruposSequenciais
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final grupo = entry.value;
                                    final pesoFormatado =
                                        CalculadoraAnilhas.formatarPeso(
                                      grupo.peso,
                                    );
                                    final usarChavePrincipal =
                                        chavesJaUsadas.add(grupo.peso);
                                    return GestureDetector(
                                      key: usarChavePrincipal
                                          ? Key('anilha-montada-$pesoFormatado')
                                          : Key(
                                              'anilha-montada-$pesoFormatado-${entry.key}',
                                            ),
                                      onTap: () =>
                                          _removerAnilhaPorLado(grupo.peso),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.14,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.55,
                                            ),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${grupo.quantidade}× $pesoFormatado kg',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.close_rounded,
                                              size: 13,
                                              color: AppColors.primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      const Text(
                        'ADICIONAR ANILHA (POR LADO)',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDimmed,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Botões padronizados em cor única (sem efeito arco-íris)
                      Row(
                        children:
                            CalculadoraAnilhas.anilhasPadrao.map((anilha) {
                          final label = CalculadoraAnilhas.formatarPeso(anilha);
                          final isUltima = anilha == 1.25;
                          return Expanded(
                            child: Padding(
                              padding:
                                  EdgeInsets.only(right: isUltima ? 0.0 : 5.0),
                              child: GestureDetector(
                                key: Key('btn-add-anilha-$label'),
                                onTap: () => _adicionarAnilhaPorLado(anilha),
                                child: Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: AppColors.background,
                                    border: Border.all(
                                      color: AppColors.buttonBorder,
                                      width: 1.4,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '+$label',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.textLight,
                                            height: 1.1,
                                          ),
                                        ),
                                        const Text(
                                          'KG',
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textDimmed,
                                            height: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),
              // Rodapé Padronizado de Alto Contraste Fixo
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        key: const Key('btn-cancelar-anilhas'),
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        key: const Key('btn-aplicar-anilhas'),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context, _pesoTotalAtual);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'APLICAR NA SÉRIE',
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

/// CustomPainter que desenha a barra olímpica completa vista de frente e empilha
/// as anilhas simetricamente em AMBOS os lados (de dentro para fora).
class BarraAnilhasPainter extends CustomPainter {
  final List<double> anilhasPorLado;
  final double pesoBarra;

  const BarraAnilhasPainter({
    required this.anilhasPorLado,
    required this.pesoBarra,
  });

  double _alturaRelativaAnilha(double peso, double maxHeight) {
    if (peso >= 25.0) return maxHeight * 0.94;
    if (peso >= 20.0) return maxHeight * 0.86;
    if (peso >= 15.0) return maxHeight * 0.76;
    if (peso >= 10.0) return maxHeight * 0.66;
    if (peso >= 5.0) return maxHeight * 0.54;
    if (peso >= 2.5) return maxHeight * 0.44;
    return maxHeight * 0.36;
  }

  double _larguraAnilha(double peso) {
    if (peso >= 20.0) return 14.0;
    if (peso >= 10.0) return 12.0;
    if (peso >= 5.0) return 10.0;
    return 8.5;
  }

  void _desenharAnilha(
    Canvas canvas, {
    required Rect rect,
    required double peso,
  }) {
    const cor = AppColors.primary;
    final paintAnilha = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFFAB40),
          cor,
          const Color(0xFFE65100),
        ],
      ).createShader(rect);

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3.5));
    canvas.drawRRect(rrect, paintAnilha);

    final paintBorda = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, paintBorda);

    if (rect.width >= 8.0 && rect.height >= 26.0) {
      final label = CalculadoraAnilhas.formatarPeso(peso);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: AppColors.background,
            fontSize: label.length >= 4
                ? 6.0
                : (rect.width >= 11.5 ? 7.5 : 6.5),
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(
          rect.left + (rect.width - tp.width) / 2,
          rect.top + (rect.height - tp.height) / 2,
        ),
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final paintMetal = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF90A4AE),
          Color(0xFFCFD8DC),
          Color(0xFF546E7A),
        ],
      ).createShader(Rect.fromLTWH(0, centerY - 14, size.width, 28));

    // Dimensões da barra simétrica
    const double meiaHasteCentral = 34.0;
    const double larguraBatente = 7.0;
    const double margemExterna = 6.0;

    final double batenteEsqLeft = centerX - meiaHasteCentral - larguraBatente;
    final double batenteDirLeft = centerX + meiaHasteCentral;
    final double ponteiraEsqWidth =
        (batenteEsqLeft - margemExterna).clamp(10.0, size.width / 2);
    final double ponteiraDirLeft = batenteDirLeft + larguraBatente;
    final double ponteiraDirWidth =
        (size.width - margemExterna - ponteiraDirLeft)
            .clamp(10.0, size.width / 2);

    // 1. Eixo Central da Barra (entre os dois batentes)
    canvas.drawRect(
      Rect.fromLTWH(
        centerX - meiaHasteCentral,
        centerY - 4,
        meiaHasteCentral * 2,
        8,
      ),
      paintMetal,
    );

    // Recartilhado sutil (knurling) no eixo central
    final paintKnurling = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(centerX - 26, centerY - 4, 18, 8),
      paintKnurling,
    );
    canvas.drawRect(
      Rect.fromLTWH(centerX + 8, centerY - 4, 18, 8),
      paintKnurling,
    );

    // 2. Ponteira Esquerda e Ponteira Direita (sleeves)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(margemExterna, centerY - 6, ponteiraEsqWidth, 12),
        const Radius.circular(3),
      ),
      paintMetal,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(ponteiraDirLeft, centerY - 6, ponteiraDirWidth, 12),
        const Radius.circular(3),
      ),
      paintMetal,
    );

    // 3. Batente Esquerdo e Batente Direito (collars)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(batenteEsqLeft, centerY - 13, larguraBatente, 26),
        const Radius.circular(2.5),
      ),
      paintMetal,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(batenteDirLeft, centerY - 13, larguraBatente, 26),
        const Radius.circular(2.5),
      ),
      paintMetal,
    );

    // 4. Desenha as anilhas em AMBOS os lados na ordem exata adicionada (de dentro para fora)
    if (anilhasPorLado.isEmpty) return;

    final double espacoUtilPorLado = (ponteiraDirWidth - 8.0).clamp(20.0, 200.0);
    final double larguraOriginalPorLado = anilhasPorLado.fold<double>(
      0.0,
      (soma, p) => soma + _larguraAnilha(p) + 2.5,
    );
    final double escalaX = larguraOriginalPorLado > espacoUtilPorLado &&
            larguraOriginalPorLado > 0
        ? (espacoUtilPorLado / larguraOriginalPorLado)
        : 1.0;

    double cursorDireito = ponteiraDirLeft + 2.5;
    double cursorEsquerdo = batenteEsqLeft - 2.5;

    for (final peso in anilhasPorLado) {
      final largura = (_larguraAnilha(peso) * escalaX).clamp(6.5, 16.0);
      final altura = _alturaRelativaAnilha(peso, size.height);
      final gap = 2.5 * escalaX;

      // Anilha do lado DIREITO (cresce para a direita ->)
      final rectDir = Rect.fromLTWH(
        cursorDireito,
        centerY - altura / 2,
        largura,
        altura,
      );
      _desenharAnilha(canvas, rect: rectDir, peso: peso);
      cursorDireito += largura + gap;

      // Anilha do lado ESQUERDO (cresce para a esquerda <-)
      cursorEsquerdo -= largura;
      final rectEsq = Rect.fromLTWH(
        cursorEsquerdo,
        centerY - altura / 2,
        largura,
        altura,
      );
      _desenharAnilha(canvas, rect: rectEsq, peso: peso);
      cursorEsquerdo -= gap;
    }
  }

  @override
  bool shouldRepaint(covariant BarraAnilhasPainter oldDelegate) {
    if (oldDelegate.pesoBarra != pesoBarra ||
        oldDelegate.anilhasPorLado.length != anilhasPorLado.length) {
      return true;
    }
    for (int i = 0; i < anilhasPorLado.length; i++) {
      if (oldDelegate.anilhasPorLado[i] != anilhasPorLado[i]) return true;
    }
    return false;
  }
}
