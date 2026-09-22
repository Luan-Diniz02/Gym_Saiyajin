import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/progresso_controller.dart';
import '../models/poder_luta.dart';
import '../models/sessao_treino.dart';
import '../services/card_share_service.dart';
import '../theme/app_colors.dart';
import 'dragon_ball_icon.dart';
import 'scouter_icon.dart';

enum ProporcaoCard {
  stories, // 9:16 (Instagram Stories / WhatsApp Status)
  quadrado, // 1:1 (Feed Instagram)
}

enum EstiloCardOverlay {
  slimClassico, // Layout clássico com métricas no topo e rodapé (Foto 5)
  scouterHud, // Carimbo Scouter HUD + métricas compactas (Foto 4 Adidas)
  rodapeMinimalista, // Métricas 100% no rodapé com topo desobstruído (Foto 1 Adidas)
}

enum CorTextoCard {
  branco,
  dourado,
}

class CompartilharCardModal extends StatefulWidget {
  final SessaoTreino sessao;
  final ProgressoController? progressoController;

  const CompartilharCardModal({
    super.key,
    required this.sessao,
    this.progressoController,
  });

  @override
  State<CompartilharCardModal> createState() => _CompartilharCardModalState();
}

class _CompartilharCardModalState extends State<CompartilharCardModal> {
  final GlobalKey _cardKey = GlobalKey();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _handleController = TextEditingController();

  XFile? _imagemSelecionada;
  bool _isGerandoImagem = false;

  ProporcaoCard _proporcao = ProporcaoCard.stories;
  EstiloCardOverlay _estilo = EstiloCardOverlay.slimClassico;
  CorTextoCard _corTexto = CorTextoCard.branco;

  @override
  void dispose() {
    _handleController.dispose();
    super.dispose();
  }

  Future<void> _tirarFoto() async {
    try {
      final foto = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );
      if (foto != null) {
        setState(() {
          _imagemSelecionada = foto;
        });
      }
    } catch (e) {
      _mostrarAviso('Não foi possível acessar a câmera: $e');
    }
  }

  Future<void> _escolherGaleria() async {
    try {
      final foto = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (foto != null) {
        setState(() {
          _imagemSelecionada = foto;
        });
      }
    } catch (e) {
      _mostrarAviso('Não foi possível acessar a galeria: $e');
    }
  }

  void _removerFoto() {
    setState(() {
      _imagemSelecionada = null;
    });
  }

  void _mostrarAviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  String _formatarData(DateTime? data) {
    if (data == null) return 'Hoje';
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();
    return '$dia/$mes/$ano';
  }

  double _calcularVolumeTotal() {
    double total = 0.0;
    for (final ex in widget.sessao.exerciciosConcluidosHoje) {
      for (final s in ex.seriesDetalhes) {
        if (s.concluida || (s.peso != null && s.peso! > 0 && s.reps != null && s.reps! > 0)) {
          total += (s.peso ?? 0.0) * (s.reps ?? 0);
        }
      }
    }
    return total;
  }

  String _formatarVolume(double volume) {
    final intVal = volume.round();
    final str = intVal.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    final formatted = buffer.toString().split('').reversed.join('');
    return '$formatted kg';
  }

  int _calcularTotalSeries() {
    int total = 0;
    for (final ex in widget.sessao.exerciciosConcluidosHoje) {
      total += ex.seriesDetalhes.length;
    }
    return total;
  }

  int _calcularKiSessao() {
    final volume = _calcularVolumeTotal();
    return (volume / 100).round();
  }

  int _obterTotalPRs() {
    return widget.progressoController?.totalRecordes ?? 0;
  }

  TransformacaoSaiyajin _obterTransformacao() {
    if (widget.progressoController != null) {
      return widget.progressoController!.poderLuta.transformacao;
    }
    final ki = _calcularKiSessao();
    return TransformacaoSaiyajin.obterPorPoder(ki * 10);
  }

  Future<void> _compartilharComoImagem() async {
    setState(() {
      _isGerandoImagem = true;
    });

    try {
      final dataStr = _formatarData(widget.sessao.data).replaceAll('/', '-');
      final propStr = _proporcao == ProporcaoCard.stories ? 'stories' : 'feed';
      final nomeArquivo = 'treino_saiyajin_${propStr}_$dataStr';

      final sucesso = await CardShareService.compartilharWidgetComoImagem(
        boundaryKey: _cardKey,
        nomeArquivo: nomeArquivo,
        textoCompartilhamento: null,
      );

      if (!sucesso && mounted) {
        _mostrarAviso('Não foi possível gerar a imagem para compartilhamento.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGerandoImagem = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra Superior Estilo Adidas Running (Título, Fechar, Compartilhar)
              _buildBarraSuperior(),
              const SizedBox(height: 10),

              // Seletor de Formato: STORIES vs QUADRADO
              _buildSeletorProporcao(),
              const SizedBox(height: 12),

              // Card Visual RepaintBoundary
              _buildCardVisual(),
              const SizedBox(height: 12),

              // Painel de Personalização Inferior
              _buildPainelControles(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarraSuperior() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppColors.textDimmed, size: 22),
            tooltip: 'Fechar',
          ),
          const Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'COMPARTILHE SEU PROGRESSO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isGerandoImagem ? null : _compartilharComoImagem,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isGerandoImagem
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Text(
                    'COMPARTILHAR',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeletorProporcao() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBotaoProporcao(
            rotulo: 'STORIES (9:16)',
            proporcao: ProporcaoCard.stories,
            icone: Icons.stay_current_portrait_rounded,
          ),
          const SizedBox(width: 4),
          _buildBotaoProporcao(
            rotulo: 'FEED (1:1)',
            proporcao: ProporcaoCard.quadrado,
            icone: Icons.crop_square_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoProporcao({
    required String rotulo,
    required ProporcaoCard proporcao,
    required IconData icone,
  }) {
    final isSel = _proporcao == proporcao;
    return InkWell(
      onTap: () => setState(() => _proporcao = proporcao),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSel ? AppColors.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icone,
              size: 14,
              color: isSel ? AppColors.primary : AppColors.textDimmed,
            ),
            const SizedBox(width: 5),
            Text(
              rotulo,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                color: isSel ? AppColors.textLight : AppColors.textDimmed,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardVisual() {
    final double largura = 300;
    final double aspectRatio = _proporcao == ProporcaoCard.stories ? (9 / 16) : (1 / 1);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.75),
            blurRadius: 20,
            spreadRadius: 3,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: RepaintBoundary(
        key: _cardKey,
        child: SizedBox(
          width: largura,
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: _buildModoFoto(),
          ),
        ),
      ),
    );
  }

  /// Estilo com a foto do usuário edge-to-edge (ou fundo Saiyajin premium)
  Widget _buildModoFoto() {
    final transformacao = _obterTransformacao();
    final kiSessao = _calcularKiSessao();
    final prsCount = _obterTotalPRs();

    final Color corPrimaria = _corTexto == CorTextoCard.branco
        ? Colors.white
        : const Color(0xFFFFD700);

    final Color corSecundaria = _corTexto == CorTextoCard.branco
        ? AppColors.primary
        : const Color(0xFFFF9E00);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Foto do guerreiro em tela cheia OU gradiente Saiyajin se nenhuma foto selecionada
        Positioned.fill(
          child: _imagemSelecionada != null
              ? Image.file(
                  File(_imagemSelecionada!.path),
                  fit: BoxFit.cover,
                )
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF1E2028),
                        Color(0xFF121319),
                        Color(0xFF090A0D),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: 0.08,
                      child: Image.asset(
                        'assets/images/shenlong_logo.png',
                        width: 180,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.fitness_center,
                          size: 80,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
        ),

        // Gradiente superior sutil
        if (_estilo != EstiloCardOverlay.rodapeMinimalista)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _proporcao == ProporcaoCard.stories ? 180 : 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.70),
                    Colors.black.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

        // Gradiente inferior sutil
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: _estilo == EstiloCardOverlay.rodapeMinimalista
              ? (_proporcao == ProporcaoCard.stories ? 220 : 170)
              : 140,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.40),
                  Colors.black.withValues(alpha: 0.85),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Camada do Layout Selecionado
        Positioned.fill(
          child: _renderizarOverlay(
            corPrimaria: corPrimaria,
            corSecundaria: corSecundaria,
            transformacao: transformacao,
            kiSessao: kiSessao,
            prsCount: prsCount,
          ),
        ),
      ],
    );
  }

  Widget _renderizarOverlay({
    required Color corPrimaria,
    required Color corSecundaria,
    required TransformacaoSaiyajin transformacao,
    required int kiSessao,
    required int prsCount,
  }) {
    switch (_estilo) {
      case EstiloCardOverlay.slimClassico:
        return _buildOverlaySlimClassico(
          corPrimaria: corPrimaria,
          corSecundaria: corSecundaria,
        );
      case EstiloCardOverlay.scouterHud:
        return _buildOverlayScouterHud(
          corPrimaria: corPrimaria,
          corSecundaria: corSecundaria,
          transformacao: transformacao,
          kiSessao: kiSessao,
          prsCount: prsCount,
        );
      case EstiloCardOverlay.rodapeMinimalista:
        return _buildOverlayRodapeMinimalista(
          corPrimaria: corPrimaria,
          corSecundaria: corSecundaria,
          transformacao: transformacao,
          kiSessao: kiSessao,
        );
    }
  }

  /// 1. Preset: Slim Clássico (O estilo oficial da Foto 5)
  Widget _buildOverlaySlimClassico({
    required Color corPrimaria,
    required Color corSecundaria,
  }) {
    final volume = _calcularVolumeTotal();
    final volumeStr = _formatarVolume(volume);
    final totalSeries = _calcularTotalSeries();
    final handleText = _obterTextoHandle();
    final isStories = _proporcao == ProporcaoCard.stories;

    return Padding(
      padding: EdgeInsets.only(
        top: isStories ? 44.0 : 20.0,
        bottom: isStories ? 26.0 : 18.0,
        left: 20.0,
        right: 20.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Topo: Divisão + Métricas em 3 colunas
          Column(
            children: [
              if (widget.sessao.nomeTreino != null &&
                  widget.sessao.nomeTreino!.trim().isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  constraints: const BoxConstraints(maxWidth: 240),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    widget.sessao.nomeTreino!.trim().toUpperCase(),
                    style: TextStyle(
                      color: corPrimaria.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 1.8,
                      shadows: _sombraTextoForte(),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              Row(
                children: [
                  Expanded(
                    child: _buildMetricaOverlay(
                      rotulo: 'Duração',
                      valor: widget.sessao.duracaoFormatada,
                      cor: corPrimaria,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricaOverlay(
                      rotulo: 'Volume',
                      valor: volumeStr,
                      cor: corPrimaria,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricaOverlay(
                      rotulo: 'Séries',
                      valor: '$totalSeries',
                      cor: corPrimaria,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Rodapé: Logo Shenlong + GYM SAIYAJIN e Data/@
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLogoComSombra(tamanho: 32),
                  const SizedBox(width: 8),
                  Text(
                    'GYM SAIYAJIN',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                      color: corPrimaria,
                      shadows: _sombraTextoForte(),
                    ),
                  ),
                ],
              ),
              Flexible(
                child: Text(
                  handleText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: corPrimaria.withValues(alpha: 0.90),
                    shadows: _sombraTextoForte(),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. Preset: Scouter HUD (Inspirado no Adidas Running Foto 4)
  Widget _buildOverlayScouterHud({
    required Color corPrimaria,
    required Color corSecundaria,
    required TransformacaoSaiyajin transformacao,
    required int kiSessao,
    required int prsCount,
  }) {
    final volume = _calcularVolumeTotal();
    final volumeStr = _formatarVolume(volume);
    final totalSeries = _calcularTotalSeries();
    final handleText = _obterTextoHandle();
    final isStories = _proporcao == ProporcaoCard.stories;

    return Padding(
      padding: EdgeInsets.only(
        top: isStories ? 44.0 : 18.0,
        bottom: isStories ? 26.0 : 16.0,
        left: 18.0,
        right: 18.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Topo: Divisão à esquerda + Carimbo Scouter HUD à direita
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.sessao.nomeTreino != null &&
                  widget.sessao.nomeTreino!.trim().isNotEmpty) ...[
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.40),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      widget.sessao.nomeTreino!.trim().toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: corPrimaria,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                        letterSpacing: 1.0,
                        shadows: _sombraTextoForte(),
                      ),
                    ),
                  ),
                ),
              ] else
                const SizedBox.shrink(),

              // Carimbo do Scouter HUD
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: transformacao.corBadge.withValues(alpha: 0.7),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: transformacao.corBadge.withValues(alpha: 0.20),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScouterIcon(
                      size: 20,
                      lensColor: transformacao == TransformacaoSaiyajin.superSaiyajin2
                          ? const Color(0xFF00E5FF)
                          : transformacao.corAura,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+${PoderLuta.formatarPoder(kiSessao)} Ki',
                          style: TextStyle(
                            color: transformacao.corBadge,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            shadows: _sombraTextoForte(),
                          ),
                        ),
                        Text(
                          transformacao.titulo.toUpperCase(),
                          style: TextStyle(
                            color: corPrimaria.withValues(alpha: 0.9),
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Rodapé Compacto (Estilo Foto 4 do Adidas)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Linha de Métricas Compactas
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.40),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetricaInline(
                        titulo: 'VOLUME',
                        valor: volumeStr,
                        cor: corPrimaria,
                      ),
                    ),
                    _buildDivisorVertical(),
                    Expanded(
                      child: _buildMetricaInline(
                        titulo: 'DURAÇÃO',
                        valor: widget.sessao.duracaoFormatada,
                        cor: corPrimaria,
                      ),
                    ),
                    _buildDivisorVertical(),
                    Expanded(
                      child: _buildMetricaInline(
                        titulo: 'SÉRIES',
                        valor: '$totalSeries',
                        cor: corPrimaria,
                      ),
                    ),
                    if (prsCount > 0) ...[
                      _buildDivisorVertical(),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const DragonBallIcon(size: 13, stars: 4),
                            const SizedBox(height: 1),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$prsCount PRs',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: transformacao.corBadge,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Linha da Marca e Data
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLogoComSombra(tamanho: 24),
                        const SizedBox(width: 6),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'GYM SAIYAJIN',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: corPrimaria,
                                shadows: _sombraTextoForte(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (handleText.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        handleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: corPrimaria.withValues(alpha: 0.85),
                          shadows: _sombraTextoForte(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3. Preset: Rodapé Minimalista (Topo 100% livre — Foto 1 do Adidas)
  Widget _buildOverlayRodapeMinimalista({
    required Color corPrimaria,
    required Color corSecundaria,
    required TransformacaoSaiyajin transformacao,
    required int kiSessao,
  }) {
    final volume = _calcularVolumeTotal();
    final volumeStr = _formatarVolume(volume);
    final totalSeries = _calcularTotalSeries();
    final handleText = _obterTextoHandle();
    final isStories = _proporcao == ProporcaoCard.stories;

    return Padding(
      padding: EdgeInsets.only(
        bottom: isStories ? 26.0 : 16.0,
        left: 18.0,
        right: 18.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Card Translúcido Compacto na parte inferior
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.50),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.20),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Divisão do Treino e Patamar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        widget.sessao.nomeTreino != null && widget.sessao.nomeTreino!.trim().isNotEmpty
                            ? widget.sessao.nomeTreino!.trim().toUpperCase()
                            : 'TREINO SAIYAJIN',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: corSecundaria,
                          shadows: _sombraTextoForte(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      transformacao.titulo.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: transformacao.corBadge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 3 Métricas em Linha
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricaInline(
                        titulo: 'VOLUME',
                        valor: volumeStr,
                        cor: corPrimaria,
                      ),
                    ),
                    _buildDivisorVertical(),
                    Expanded(
                      child: _buildMetricaInline(
                        titulo: 'DURAÇÃO',
                        valor: widget.sessao.duracaoFormatada,
                        cor: corPrimaria,
                      ),
                    ),
                    _buildDivisorVertical(),
                    Expanded(
                      child: _buildMetricaInline(
                        titulo: 'SÉRIES',
                        valor: '$totalSeries',
                        cor: corPrimaria,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 8),

                // Marca e @
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLogoComSombra(tamanho: 22),
                          const SizedBox(width: 6),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'GYM SAIYAJIN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: corPrimaria,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (handleText.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          handleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: corPrimaria.withValues(alpha: 0.85),
                            shadows: _sombraTextoForte(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricaInline({
    required String titulo,
    required String valor,
    required Color cor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            titulo,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: cor.withValues(alpha: 0.70),
              shadows: _sombraTextoForte(),
            ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            valor,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: cor,
              letterSpacing: 0.3,
              shadows: _sombraTextoForte(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivisorVertical() {
    return Container(
      width: 1,
      height: 22,
      color: Colors.white24,
    );
  }



  /// Painel de Controles com Abas e Customizações
  Widget _buildPainelControles() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Ações de Foto (Câmera / Galeria)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _tirarFoto,
                  icon: const Icon(Icons.camera_alt, color: AppColors.primary, size: 18),
                  label: const Text(
                    'Câmera',
                    style: TextStyle(color: AppColors.textLight, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _escolherGaleria,
                  icon: const Icon(Icons.photo_library, color: AppColors.primary, size: 18),
                  label: const Text(
                    'Galeria',
                    style: TextStyle(color: AppColors.textLight, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              if (_imagemSelecionada != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _removerFoto,
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                  tooltip: 'Remover foto',
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // 2. Seletor de Estilo de Overlay
          const Text(
            'ESTILO DO OVERLAY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.textDimmed,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildChipEstilo(
                rotulo: 'Slim Clássico',
                estilo: EstiloCardOverlay.slimClassico,
                icone: Icons.vertical_align_top_rounded,
              ),
              const SizedBox(width: 6),
              _buildChipEstilo(
                rotulo: 'Scouter HUD',
                estilo: EstiloCardOverlay.scouterHud,
                icone: Icons.track_changes_rounded,
              ),
              const SizedBox(width: 6),
              _buildChipEstilo(
                rotulo: 'Rodapé',
                estilo: EstiloCardOverlay.rodapeMinimalista,
                icone: Icons.vertical_align_bottom_rounded,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 3. Cor do Texto (Branco vs Dourado)
          Row(
            children: [
              const Text(
                'COR DO TEXTO: ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.textDimmed,
                ),
              ),
              const SizedBox(width: 8),
              _buildChipCor(
                rotulo: 'Branco',
                cor: CorTextoCard.branco,
                colorIndicator: Colors.white,
              ),
              const SizedBox(width: 6),
              _buildChipCor(
                rotulo: 'Dourado',
                cor: CorTextoCard.dourado,
                colorIndicator: const Color(0xFFFFD700),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Campo de @handle ou legenda
          TextField(
            controller: _handleController,
            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Seu @ ou legenda no rodapé (ex: @usuario)',
              hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.alternate_email, size: 16, color: AppColors.textDimmed),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipEstilo({
    required String rotulo,
    required EstiloCardOverlay estilo,
    required IconData icone,
  }) {
    final isSel = _estilo == estilo;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _estilo = estilo),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSel ? AppColors.primary.withValues(alpha: 0.15) : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSel ? AppColors.primary : AppColors.cardBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icone,
                size: 13,
                color: isSel ? AppColors.primary : AppColors.textDimmed,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    rotulo,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                      color: isSel ? AppColors.primary : AppColors.textDimmed,
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

  Widget _buildChipCor({
    required String rotulo,
    required CorTextoCard cor,
    required Color colorIndicator,
  }) {
    final isSel = _corTexto == cor;
    return InkWell(
      onTap: () => setState(() => _corTexto = cor),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSel ? AppColors.surface : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSel ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colorIndicator,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 0.5),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              rotulo,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                color: isSel ? AppColors.textLight : AppColors.textDimmed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricaOverlay({
    required String rotulo,
    required String valor,
    required Color cor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            rotulo,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cor.withValues(alpha: 0.92),
              letterSpacing: 0.2,
              shadows: _sombraTextoForte(),
            ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: cor,
              letterSpacing: 0.3,
              shadows: _sombraTextoForte(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoComSombra({double tamanho = 34}) {
    return SizedBox(
      width: tamanho,
      height: tamanho,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(1.5, 1.5),
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.85),
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/images/shenlong_logo.png',
                  width: tamanho,
                  height: tamanho,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Image.asset(
            'assets/images/shenlong_logo.png',
            width: tamanho,
            height: tamanho,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }



  String _obterTextoHandle() {
    return _handleController.text.trim().isNotEmpty
        ? (_handleController.text.trim().startsWith('@')
            ? _handleController.text.trim()
            : '@${_handleController.text.trim()}')
        : _formatarData(widget.sessao.data);
  }

  List<Shadow> _sombraTextoForte() {
    return [
      Shadow(
        color: Colors.black.withValues(alpha: 0.90),
        blurRadius: 8,
        offset: const Offset(1, 1),
      ),
      Shadow(
        color: Colors.black.withValues(alpha: 0.70),
        blurRadius: 16,
        offset: const Offset(2, 2),
      ),
    ];
  }
}
