import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muscle_mapper/muscle_mapper.dart';

import '../controllers/progresso_controller.dart';
import '../models/recorde_pessoal.dart';
import '../models/sessao_treino.dart';
import '../theme/app_colors.dart';

/// Provedor de assets SVG customizado sobre o [DefaultAnatomyProvider] do
/// `muscle_mapper` para otimizar o contraste das linhas de contorno e a
/// separação entre feixes musculares no tema escuro do Gym Saiyajin.
class DarkThemeAnatomyProvider implements AnatomyAssetProvider {
  static const DefaultAnatomyProvider _delegate = DefaultAnatomyProvider(
    style: AnatomyStyle.minimal,
  );

  static final RegExp _strokeWidthRegex = RegExp(r'stroke-width="3\.\d+"');

  /// Cache estático do SVG apenas com a camada `<g id="body">` (linhas de
  /// contorno e divisões anatômicas internas) para ser renderizada POR CIMA
  /// dos preenchimentos musculares do [MuscleMapper].
  static final Map<String, String> _overlayLinesCache = {};

  const DarkThemeAnatomyProvider();

  @override
  Future<String> getAnatomySvgRawString(
    AnatomyGender gender,
    AnatomyView view,
  ) async {
    final raw = await _delegate.getAnatomySvgRawString(gender, view);
    // Camada de base (abaixo dos músculos): contorno claro (#90A4AE) para
    // destacar cabeça, joelhos, mãos e silhueta externa contra o fundo escuro.
    return raw
        .replaceAll('#484a68', '#90A4AE')
        .replaceAll(_strokeWidthRegex, 'stroke-width="4.2"')
        .replaceAll('fill="currentColor"', 'fill="#37474F"');
  }

  /// Extrai e estiliza a camada de linhas anatômicas (`<g id="body">`) para
  /// ser desenhada SOBRE os músculos coloridos, garantindo contraste tanto
  /// sobre cores vibrantes (amarelo/ciano/vermelho) quanto sobre o fundo escuro.
  Future<String> getOverlayLinesSvgString(
    AnatomyGender gender,
    AnatomyView view,
  ) async {
    final key = '${gender.name}_${view.name}_v2';
    if (_overlayLinesCache.containsKey(key)) {
      return _overlayLinesCache[key]!;
    }

    final raw = await _delegate.getAnatomySvgRawString(gender, view);
    final openTagEnd = raw.indexOf('>');
    final closeTagStart = raw.lastIndexOf('</svg>');
    if (openTagEnd == -1 || closeTagStart == -1) return raw;

    final openTag = raw.substring(0, openTagEnd + 1);
    final innerBody = raw
        .substring(openTagEnd + 1, closeTagStart)
        .replaceAll('fill="currentColor"', 'fill="none"');

    // Dupla camada de traço vetorial:
    // 1. Borda escura externa (#10141C, 4.6px) que separa nitidamente os feixes
    //    musculares sobre áreas claras (Ouro, Ciano e Rubro).
    // 2. Fio metálico central (#B0BEC5, 1.4px) que mantém a cabeça, joelhos e
    //    contornos externos visíveis contra o fundo escuro (#12161D).
    final darkLayer = innerBody
        .replaceAll('#484a68', '#10141C')
        .replaceAll(_strokeWidthRegex, 'stroke-width="4.6"');
    final lightCoreLayer = innerBody
        .replaceAll('#484a68', '#B0BEC5')
        .replaceAll(_strokeWidthRegex, 'stroke-width="1.4"');

    final overlaySvg = '$openTag<g>$darkLayer</g><g>$lightCoreLayer</g></svg>';
    _overlayLinesCache[key] = overlaySvg;
    return overlaySvg;
  }

  @override
  Widget buildSvgWidget(String svgString, {BoxFit fit = BoxFit.contain}) {
    return _delegate.buildSvgWidget(svgString, fit: fit);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DarkThemeAnatomyProvider;

  @override
  int get hashCode => 0x47594D57;
}

/// Card de "Mapa de Calor Muscular" (Frontal e Dorsal) utilizando o pacote
/// `muscle_mapper` integrado ao Dashboard de Progresso.
class ScouterAnatomicoWidget extends StatelessWidget {
  final ProgressoController controller;
  final DarkThemeAnatomyProvider assetProvider;

  const ScouterAnatomicoWidget({
    super.key,
    required this.controller,
    this.assetProvider = const DarkThemeAnatomyProvider(),
  });

  /// Mapeia cada [Muscle] granular do pacote `muscle_mapper` para um dos
  /// 7 grupos musculares canônicos do aplicativo (ou `null` para extremidades neutras).
  static String? mapearMuscleParaGrupoCanonico(Muscle muscle) {
    switch (muscle) {
      case Muscle.upperPectoralis:
      case Muscle.midLowerPectoralis:
        return 'PEITO';

      case Muscle.upperTrapezius:
      case Muscle.trapsMiddle:
      case Muscle.lowerTrapezius:
      case Muscle.lats:
      case Muscle.lowerBack:
        return 'COSTAS';

      case Muscle.anteriorDeltoid:
      case Muscle.lateralDeltoid:
      case Muscle.posteriorDeltoid:
        return 'OMBROS';

      case Muscle.longHeadBicep:
      case Muscle.shortHeadBicep:
      case Muscle.wristFlexors:
        return 'BÍCEPS';

      case Muscle.longHeadTriceps:
      case Muscle.lateralHeadTriceps:
      case Muscle.medialHeadTriceps:
      case Muscle.wristExtensors:
        return 'TRÍCEPS';

      case Muscle.upperAbdominals:
      case Muscle.lowerAbdominals:
      case Muscle.obliques:
        return 'ABDÔMEN';

      case Muscle.outerQuadricep:
      case Muscle.rectusFemoris:
      case Muscle.innerQuadricep:
      case Muscle.innerThigh:
      case Muscle.groin:
      case Muscle.lateralHamstrings:
      case Muscle.medialHamstrings:
      case Muscle.gluteusMaximus:
      case Muscle.gluteusMedius:
      case Muscle.gastrocnemius:
      case Muscle.soleus:
      case Muscle.tibialis:
        return 'PERNAS';

      case Muscle.neck:
      case Muscle.hands:
      case Muscle.feet:
        return null;
    }
  }

  static Color corPorNivel(NivelAtivacaoMuscular nivel) {
    switch (nivel) {
      case NivelAtivacaoMuscular.inativo:
        return const Color(0xFF3E5060); // Aço Intermediário visível no escuro
      case NivelAtivacaoMuscular.manutencao:
        return const Color(0xFF00C4E0); // Ciano Bioelétrico contrastante
      case NivelAtivacaoMuscular.ideal:
        return const Color(0xFFFFB300); // Ouro Âmbar Super Saiyajin (alto contraste com linhas)
      case NivelAtivacaoMuscular.altaDemanda:
        return const Color(0xFFFF5252); // Rubro Kaioken
    }
  }

  /// Constrói o mapa de cores por feixe muscular do `muscle_mapper`.
  static Map<Muscle, Color> construirMapaCoresMusculares(
    Map<String, TelemetriaMuscular> telemetria,
  ) {
    final Map<Muscle, Color> cores = {};
    for (final muscle in Muscle.values) {
      final grupo = mapearMuscleParaGrupoCanonico(muscle);
      if (grupo == null) {
        cores[muscle] = const Color(0xFF455A64);
        continue;
      }
      final dados = telemetria[grupo];
      if (dados == null || dados.nivel == NivelAtivacaoMuscular.inativo) {
        cores[muscle] = const Color(0xFF37474F);
      } else {
        cores[muscle] = corPorNivel(dados.nivel);
      }
    }
    return cores;
  }

  /// Constrói o mapa de intensidades (opacidade) por feixe muscular, destacando
  /// o grupo selecionado pelo usuário sem deixar o restante do corpo escuro demais.
  static Map<Muscle, double> construirMapaIntensidades(
    Map<String, TelemetriaMuscular> telemetria, {
    String? grupoSelecionado,
  }) {
    final Map<Muscle, double> intensidades = {};
    for (final muscle in Muscle.values) {
      final grupo = mapearMuscleParaGrupoCanonico(muscle);
      if (grupo == null) {
        intensidades[muscle] = grupoSelecionado != null ? 0.65 : 0.85;
        continue;
      }

      final dados = telemetria[grupo];
      final bool isInativo =
          dados == null || dados.nivel == NivelAtivacaoMuscular.inativo;

      if (grupoSelecionado != null) {
        if (grupo == grupoSelecionado) {
          intensidades[muscle] = 1.0;
        } else {
          intensidades[muscle] = isInativo ? 0.55 : 0.60;
        }
      } else {
        intensidades[muscle] = isInativo ? 0.85 : 0.94;
      }
    }
    return intensidades;
  }

  void _aoTocarMusculo(Muscle muscle) {
    final grupo = mapearMuscleParaGrupoCanonico(muscle);
    if (grupo != null) {
      HapticFeedback.selectionClick();
      controller.selecionarGrupoMapaMuscular(grupo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final telemetria = controller.calcularTelemetriaMuscular();
        final pontosFracos = controller.obterPontosFracosMusculares(
          telemetria: telemetria,
        );
        final grupoSel = controller.grupoMuscularSelecionado;
        final dadosSelecionado = grupoSel != null ? telemetria[grupoSel] : null;
        final int totalSeriesPeriodo = telemetria.values.fold(
          0,
          (soma, item) => soma + item.seriesValidas,
        );

        final muscleColors = construirMapaCoresMusculares(telemetria);
        final muscleIntensities = construirMapaIntensidades(
          telemetria,
          grupoSelecionado: grupoSel,
        );

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho limpo seguindo o padrão de PROGRESSÃO DE CARGA (Opção A)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'MAPA DE CALOR MUSCULAR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildSeletorPeriodo(),
                ],
              ),
              const SizedBox(height: 16),

              // Área dos diagramas anatômicos Frontal e Dorsal (muscle_mapper)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF12161D),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildColunaCorpo(
                            titulo: 'FRONTAL',
                            view: AnatomyView.front,
                            muscleColors: muscleColors,
                            muscleIntensities: muscleIntensities,
                            canvasKey: const Key('canvas-heatmap-frontal'),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 210,
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                        Expanded(
                          child: _buildColunaCorpo(
                            titulo: 'DORSAL',
                            view: AnatomyView.back,
                            muscleColors: muscleColors,
                            muscleIntensities: muscleIntensities,
                            canvasKey: const Key('canvas-heatmap-dorsal'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildLegendaNiveis(),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Painel de inspeção do grupo selecionado (se houver)
              if (dadosSelecionado != null) ...[
                _buildPainelDetalheGrupo(dadosSelecionado),
                const SizedBox(height: 12),
              ],

              // Chips interativos dos 7 grupos musculares
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SÉRIES DE TRABALHO POR GRUPO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDimmed,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    'Total: $totalSeriesPeriodo séries',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ProgressoController.gruposMuscularesCanonicos.map((
                  grupo,
                ) {
                  final dados = telemetria[grupo]!;
                  final selecionado = grupoSel == grupo;
                  final cor = corPorNivel(dados.nivel);

                  return InkWell(
                    key: Key('chip-musculo-$grupo'),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.selecionarGrupoMapaMuscular(grupo);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: selecionado
                            ? cor.withValues(alpha: 0.22)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selecionado
                              ? cor
                              : (dados.seriesValidas > 0
                                    ? cor.withValues(alpha: 0.45)
                                    : Colors.white12),
                          width: selecionado ? 1.4 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: cor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$grupo: ${dados.seriesValidas}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: selecionado
                                  ? Colors.white
                                  : (dados.seriesValidas > 0
                                        ? AppColors.textLight
                                        : AppColors.textDimmed),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Alerta de pontos fracos (Lagging Muscles)
              if (pontosFracos.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sem estímulo (${controller.periodoMapaMuscular.label.toLowerCase()}): ${pontosFracos.join(', ')}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeletorPeriodo() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: PeriodoMapaMuscular.values.map((periodo) {
          final ativo = controller.periodoMapaMuscular == periodo;
          return GestureDetector(
            key: Key('periodo-mapa-${periodo.dias}'),
            onTap: () {
              HapticFeedback.selectionClick();
              controller.mudarPeriodoMapaMuscular(periodo);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ativo
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: ativo
                    ? Border.all(
                        color: AppColors.primary.withValues(alpha: 0.6),
                      )
                    : null,
              ),
              child: Text(
                periodo.label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: ativo ? AppColors.primary : AppColors.textDimmed,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildColunaCorpo({
    required String titulo,
    required AnatomyView view,
    required Map<Muscle, Color> muscleColors,
    required Map<Muscle, double> muscleIntensities,
    required Key canvasKey,
  }) {
    return Column(
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textDimmed,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          key: canvasKey,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              MuscleMapper(
                gender: AnatomyGender.male,
                view: view,
                assetProvider: assetProvider,
                muscleColors: muscleColors,
                muscleIntensities: muscleIntensities,
                onMuscleTapped: _aoTocarMusculo,
                loadingWidget: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              // Sobreposição das linhas de divisão anatômica (<g id="body">)
              // para que os feixes musculares não fiquem chapados sob as cores.
              IgnorePointer(
                child: _OverlayLinhasAnatomicas(
                  assetProvider: assetProvider,
                  view: view,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendaNiveis() {
    final escala = controller.periodoMapaMuscular.dias >= 28 ? 4 : 1;
    final minIdeal = 6 * escala;
    final maxIdeal = 12 * escala;
    final minAlta = 13 * escala;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: [
        _buildItemLegenda(
          cor: const Color(0xFF3E5060),
          label: '0 (Descanso)',
        ),
        _buildItemLegenda(
          cor: const Color(0xFF00C4E0),
          label: '1-${minIdeal - 1} (Ativado)',
        ),
        _buildItemLegenda(
          cor: const Color(0xFFFFB300),
          label: '$minIdeal-$maxIdeal (Ideal)',
        ),
        _buildItemLegenda(
          cor: const Color(0xFFFF5252),
          label: '$minAlta+ (Sobrecarga)',
        ),
      ],
    );
  }

  Widget _buildItemLegenda({required Color cor, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: cor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            color: AppColors.textDimmed,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPainelDetalheGrupo(TelemetriaMuscular dados) {
    final cor = corPorNivel(dados.nivel);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    dados.grupo,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: cor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      dados.nivel.label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: cor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Volume: ${SessaoTreino.formatarVolume(dados.volumeTotalKg)} • Maior 1RM: ${dados.maior1RM > 0 ? '${RecordePessoal.formatarPeso(dados.maior1RM)} kg' : '--'}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textDimmed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${dados.seriesValidas}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: cor,
                ),
              ),
              const Text(
                'SÉRIES',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDimmed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverlayLinhasAnatomicas extends StatefulWidget {
  final DarkThemeAnatomyProvider assetProvider;
  final AnatomyView view;

  const _OverlayLinhasAnatomicas({
    required this.assetProvider,
    required this.view,
  });

  @override
  State<_OverlayLinhasAnatomicas> createState() =>
      _OverlayLinhasAnatomicasState();
}

class _OverlayLinhasAnatomicasState extends State<_OverlayLinhasAnatomicas> {
  String? _svgOverlay;

  @override
  void initState() {
    super.initState();
    _carregarOverlay();
  }

  @override
  void didUpdateWidget(covariant _OverlayLinhasAnatomicas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.view != widget.view ||
        oldWidget.assetProvider != widget.assetProvider) {
      _carregarOverlay();
    }
  }

  Future<void> _carregarOverlay() async {
    try {
      final svg = await widget.assetProvider.getOverlayLinesSvgString(
        AnatomyGender.male,
        widget.view,
      );
      if (mounted) {
        setState(() => _svgOverlay = svg);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final svg = _svgOverlay;
    if (svg == null) return const SizedBox.shrink();
    return widget.assetProvider.buildSvgWidget(svg);
  }
}
