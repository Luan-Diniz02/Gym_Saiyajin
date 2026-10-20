import 'dart:io';

import 'package:flutter/material.dart';

import '../models/catalogo_exercicios.dart';
import '../services/exercicio_custom_midia_service.dart';
import '../theme/app_colors.dart';

/// Miniatura em container arredondado para exibição em listas e cabeçalhos.
///
/// Suporta tanto os 88 exercícios do catálogo padrão offline quanto exercícios
/// personalizados que possuem mídia associada (reutilizada do catálogo offline
/// ou foto/GIF enviada pelo usuário via Galeria/Câmera).
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
    return ListenableBuilder(
      listenable: ExercicioCustomMidiaService.instance,
      builder: (context, _) {
        final info = CatalogoExercicios.buscarPorNome(nomeExercicio);
        final midiaCustom = info == null
            ? ExercicioCustomMidiaService.instance.obterMidia(nomeExercicio)
            : null;

        if (info == null && midiaCustom == null) {
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

        final Widget imagemInterna;
        if (info != null) {
          imagemInterna = Image.asset(
            info.thumbAsset,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.fitness_center_rounded,
              color: AppColors.primary,
              size: size * 0.48,
            ),
          );
        } else if (midiaCustom!.thumbAsset != null) {
          imagemInterna = Image.asset(
            midiaCustom.thumbAsset!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.fitness_center_rounded,
              color: AppColors.primary,
              size: size * 0.48,
            ),
          );
        } else {
          final localPath = midiaCustom.thumbLocalPath;
          final temArquivoLocal =
              localPath != null && File(localPath).existsSync();
          if (temArquivoLocal) {
            imagemInterna = Image.file(
              File(localPath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.fitness_center_rounded,
                color: AppColors.primary,
                size: size * 0.48,
              ),
            );
          } else {
            imagemInterna = Icon(
              Icons.fitness_center_rounded,
              color: AppColors.primary,
              size: size * 0.48,
            );
          }
        }

        final bool isFotoUsuario =
            info == null && midiaCustom?.tipo == 'arquivo';

        final Widget thumbContainer = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isFotoUsuario ? AppColors.background : Colors.white,
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
            borderRadius: BorderRadius.circular(
              (borderRadius - 1.2).clamp(2.0, 30.0),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: EdgeInsets.all(isFotoUsuario ? 0.0 : 2.0),
                  child: imagemInterna,
                ),
                if (exibirIndicadorGif)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3.5,
                        vertical: 1,
                      ),
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
          onTap: () {
            if (info != null) {
              ExercicioDetalheModal.show(context, info);
            } else if (midiaCustom != null) {
              ExercicioDetalheModal.showCustom(
                context,
                midiaCustom,
                grupo: grupo,
              );
            }
          },
          child: Tooltip(
            message: 'Ver execução de $nomeExercicio',
            child: thumbContainer,
          ),
        );
      },
    );
  }
}

/// Modal sob demanda com o GIF animado (180×180), músculos recrutados,
/// equipamento e instruções passo a passo de execução.
class ExercicioDetalheModal extends StatelessWidget {
  final InfoExercicioCatalogo? info;
  final MidiaExercicioCustom? midiaCustom;
  final String? grupoCustom;

  const ExercicioDetalheModal({
    super.key,
    required this.info,
  })  : midiaCustom = null,
        grupoCustom = null;

  const ExercicioDetalheModal.custom({
    super.key,
    required MidiaExercicioCustom this.midiaCustom,
    this.grupoCustom,
  }) : info = null;

  static Future<void> show(BuildContext context, InfoExercicioCatalogo info) {
    return showDialog(
      context: context,
      builder: (context) => ExercicioDetalheModal(info: info),
    );
  }

  static Future<void> showCustom(
    BuildContext context,
    MidiaExercicioCustom midia, {
    String? grupo,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ExercicioDetalheModal.custom(
        midiaCustom: midia,
        grupoCustom: grupo,
      ),
    );
  }

  static Future<void> showPorNome(
    BuildContext context,
    String nomeExercicio, {
    String? grupo,
  }) {
    final info = CatalogoExercicios.buscarPorNome(nomeExercicio);
    if (info != null) return show(context, info);
    final midia = ExercicioCustomMidiaService.instance.obterMidia(nomeExercicio);
    if (midia != null) return showCustom(context, midia, grupo: grupo);
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    final infoReferencia = info ??
        (midiaCustom?.nomeReferenciaCatalogo != null
            ? CatalogoExercicios.buscarPorNome(
                midiaCustom!.nomeReferenciaCatalogo!,
              )
            : null);

    final nomeExibicao = info?.nome ?? midiaCustom?.nomeExercicio ?? '';
    final grupoExibicao = (info?.grupo ??
            grupoCustom ??
            infoReferencia?.grupo ??
            'PERSONALIZADO')
        .toUpperCase();
    final equipamentoExibicao = info?.equipamento ??
        midiaCustom?.equipamento ??
        infoReferencia?.equipamento ??
        'Personalizado';
    final musculoAlvoExibicao = info?.musculoAlvo ??
        midiaCustom?.musculoAlvo ??
        infoReferencia?.musculoAlvo ??
        grupoExibicao;
    final secundarios = info?.musculosSecundarios ??
        infoReferencia?.musculosSecundarios ??
        const <String>[];
    final instrucoes =
        info?.instrucoes ?? infoReferencia?.instrucoes ?? const <String>[];

    Widget midiaPrincipal;
    if (info != null) {
      midiaPrincipal = Image.asset(
        info!.gifAsset,
        width: 180,
        height: 180,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          info!.thumbAsset,
          width: 180,
          height: 180,
          fit: BoxFit.contain,
        ),
      );
    } else if (midiaCustom?.gifAsset != null) {
      midiaPrincipal = Image.asset(
        midiaCustom!.gifAsset!,
        width: 180,
        height: 180,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.fitness_center_rounded,
          size: 64,
          color: AppColors.primary,
        ),
      );
    } else {
      final gifPath = midiaCustom?.gifLocalPath;
      final thumbPath = midiaCustom?.thumbLocalPath;
      if (gifPath != null && File(gifPath).existsSync()) {
        midiaPrincipal = Image.file(
          File(gifPath),
          width: 180,
          height: 180,
          fit: BoxFit.cover,
        );
      } else if (thumbPath != null && File(thumbPath).existsSync()) {
        midiaPrincipal = Image.file(
          File(thumbPath),
          width: 180,
          height: 180,
          fit: BoxFit.cover,
        );
      } else {
        midiaPrincipal = const Icon(
          Icons.fitness_center_rounded,
          size: 64,
          color: AppColors.primary,
        );
      }
    }

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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            grupoExibicao,
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
                          nomeExibicao,
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
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textDimmed,
                      size: 20,
                    ),
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
                  padding: EdgeInsets.all(
                    midiaCustom?.tipo == 'arquivo' ? 2 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: midiaCustom?.tipo == 'arquivo'
                        ? AppColors.background
                        : Colors.white,
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
                    borderRadius: BorderRadius.circular(18),
                    child: midiaPrincipal,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                midiaCustom?.tipo == 'arquivo'
                    ? 'Foto/GIF personalizada salva no dispositivo'
                    : InfoExercicioCatalogo.atribuicao,
                textAlign: TextAlign.center,
                style: const TextStyle(
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
                            valor: equipamentoExibicao,
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
                            valor: musculoAlvoExibicao,
                            corValor: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    if (secundarios.isNotEmpty) ...[
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
                        children: secundarios.map((m) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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
              if (instrucoes.isNotEmpty) ...[
                const SizedBox(height: 16),
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
                ...instrucoes.asMap().entries.map((entry) {
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
              ],
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

/// Modal 100% offline que exibe os 88 exercícios consagrados em português do
/// [CatalogoExercicios] para associar uma imagem/GIF oficial a um exercício personalizado.
class SeletorMidiaCatalogoModal extends StatefulWidget {
  final String? grupoInicial;

  const SeletorMidiaCatalogoModal({
    super.key,
    this.grupoInicial,
  });

  static Future<InfoExercicioCatalogo?> mostrar(
    BuildContext context, {
    String? grupoInicial,
  }) {
    return showDialog<InfoExercicioCatalogo>(
      context: context,
      builder: (_) => SeletorMidiaCatalogoModal(
        grupoInicial: grupoInicial,
      ),
    );
  }

  @override
  State<SeletorMidiaCatalogoModal> createState() =>
      _SeletorMidiaCatalogoModalState();
}

class _SeletorMidiaCatalogoModalState extends State<SeletorMidiaCatalogoModal> {
  static const List<String> _grupos = [
    'TODOS',
    'PEITO',
    'COSTAS',
    'PERNAS',
    'OMBROS',
    'BÍCEPS',
    'TRÍCEPS',
    'ABDÔMEN',
  ];

  late final TextEditingController _buscaCtrl;
  String _termo = '';
  String _grupoSelecionado = 'TODOS';

  @override
  void initState() {
    super.initState();
    _buscaCtrl = TextEditingController();
    if (widget.grupoInicial != null &&
        _grupos.contains(widget.grupoInicial!.toUpperCase())) {
      _grupoSelecionado = widget.grupoInicial!.toUpperCase();
    }
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  String _semAcento(String s) =>
      ExercicioCustomMidiaService.normalizarChave(s);

  List<InfoExercicioCatalogo> get _filtrados {
    final palavras = _semAcento(_termo)
        .split(' ')
        .where((p) => p.isNotEmpty)
        .toList();

    return CatalogoExercicios.exerciciosPadrao.where((item) {
      if (_grupoSelecionado != 'TODOS' &&
          _semAcento(item.grupo) != _semAcento(_grupoSelecionado)) {
        return false;
      }
      if (palavras.isEmpty) return true;
      if (CatalogoExercicios.correspondeBusca(item.nome, _termo)) return true;
      final alvo = _semAcento(
        '${item.nome} ${item.equipamento} ${item.musculoAlvo} ${item.grupo}',
      );
      return palavras.every((p) => alvo.contains(p));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final resultados = _filtrados;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: MediaQuery.of(context).size.height * 0.84,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.burst_mode_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ESCOLHER ANIMAÇÃO DO CATÁLOGO',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textLight,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${CatalogoExercicios.exerciciosPadrao.length} exercícios 100% offline em português',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textDimmed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textDimmed,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _buscaCtrl,
                onChanged: (v) => setState(() => _termo = v),
                style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar por nome, equipamento ou músculo...',
                  hintStyle: const TextStyle(
                    color: AppColors.textDimmed,
                    fontSize: 12,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  suffixIcon: _termo.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 18,
                            color: AppColors.textDimmed,
                          ),
                          onPressed: () {
                            _buscaCtrl.clear();
                            setState(() => _termo = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _grupos.map((g) {
                    final sel = _grupoSelecionado == g;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () => setState(() => _grupoSelecionado = g),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.primary
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.cardBorder,
                            ),
                          ),
                          child: Text(
                            g,
                            style: TextStyle(
                              color: sel
                                  ? AppColors.background
                                  : AppColors.textLight,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: resultados.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum exercício encontrado.',
                          style: TextStyle(color: AppColors.textDimmed),
                        ),
                      )
                    : ListView.separated(
                        itemCount: resultados.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = resultados[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              leading: GestureDetector(
                                onTap: () =>
                                    ExercicioDetalheModal.show(context, item),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.45),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(9),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(2.0),
                                          child: Image.asset(
                                            item.thumbAsset,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        Positioned(
                                          right: 2,
                                          bottom: 2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 3,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.background
                                                  .withValues(alpha: 0.85),
                                              borderRadius:
                                                  BorderRadius.circular(4),
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
                                ),
                              ),
                              title: Text(
                                item.nome,
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                              subtitle: Text(
                                '${item.grupo} • ${item.equipamento}',
                                style: const TextStyle(
                                  color: AppColors.textDimmed,
                                  fontSize: 11.5,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.check_circle_outline_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                              onTap: () => Navigator.pop(context, item),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
