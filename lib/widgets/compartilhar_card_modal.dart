import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  slimClassico, // Layout clássico com métricas na base e topo 100% desobstruído
  scouterHud, // Carimbo Scouter HUD + Dock de telemetria unificada na base
  rodapeMinimalista, // Painel de rodapé ancorado com terço superior e meio livres
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
  double _dragDeltaCard = 0.0;
  double _dragDeltaBarra = 0.0;

  @override
  void dispose() {
    _handleController.dispose();
    super.dispose();
  }

  Future<void> _tirarFoto() async {
    try {
      HapticFeedback.lightImpact();
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
      HapticFeedback.lightImpact();
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
    HapticFeedback.lightImpact();
    setState(() {
      _imagemSelecionada = null;
    });
  }

  void _proximoEstilo() {
    HapticFeedback.selectionClick();
    final currentIndex = EstiloCardOverlay.values.indexOf(_estilo);
    final nextIndex = (currentIndex + 1) % EstiloCardOverlay.values.length;
    setState(() {
      _estilo = EstiloCardOverlay.values[nextIndex];
    });
  }

  void _estiloAnterior() {
    HapticFeedback.selectionClick();
    final currentIndex = EstiloCardOverlay.values.indexOf(_estilo);
    final prevIndex = (currentIndex - 1 + EstiloCardOverlay.values.length) % EstiloCardOverlay.values.length;
    setState(() {
      _estilo = EstiloCardOverlay.values[prevIndex];
    });
  }

  (IconData icone, String nome) _detalhesEstilo(EstiloCardOverlay estilo) {
    switch (estilo) {
      case EstiloCardOverlay.slimClassico:
        return (Icons.view_agenda_rounded, 'SLIM CLÁSSICO');
      case EstiloCardOverlay.scouterHud:
        return (Icons.track_changes_rounded, 'SCOUTER HUD');
      case EstiloCardOverlay.rodapeMinimalista:
        return (Icons.dock_rounded, 'RODAPÉ MINIMALISTA');
    }
  }

  void _mostrarAviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
      ),
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
    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF0F1015),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1015),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              // Barra Superior Estilo Studio
              _buildBarraSuperior(),

              // Área de Pré-Visualização Dinâmica (FittedBox responsivo com suporte a gesto de swipe/arrastar)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (_) => _dragDeltaCard = 0.0,
                      onHorizontalDragUpdate: (details) => _dragDeltaCard += details.primaryDelta ?? 0,
                      onHorizontalDragEnd: (DragEndDetails details) {
                        final v = details.primaryVelocity ?? 0;
                        if (_dragDeltaCard < -40 || v < -120) {
                          // Arrastou para a esquerda -> Próximo preset
                          _proximoEstilo();
                        } else if (_dragDeltaCard > 40 || v > 120) {
                          // Arrastou para a direita -> Preset anterior
                          _estiloAnterior();
                        }
                        _dragDeltaCard = 0.0;
                      },
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: _buildCardVisual(),
                      ),
                    ),
                  ),
                ),
              ),

              // Painel de Personalização Inferior com SafeArea
              _buildPainelControles(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarraSuperior() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF13141B),
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppColors.textDimmed, size: 22),
            tooltip: 'Fechar',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              padding: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
            ),
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
          ElevatedButton.icon(
            onPressed: _isGerandoImagem ? null : _compartilharComoImagem,
            icon: _isGerandoImagem
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.share_rounded, size: 15, color: Colors.black),
            label: const Text(
              'COMPARTILHAR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                color: Colors.black,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardVisual() {
    const double larguraLogica = 300.0;
    final double aspectRatio = _proporcao == ProporcaoCard.stories ? (9 / 16) : 1.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: RepaintBoundary(
        key: _cardKey,
        child: SizedBox(
          width: larguraLogica,
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

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Foto do guerreiro em tela cheia OU gradiente Saiyajin padrão
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

        // 2. Gradiente superior sutil de proteção de contraste
        if (_estilo != EstiloCardOverlay.rodapeMinimalista)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _proporcao == ProporcaoCard.stories ? 140 : 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.black.withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

        // 3. Gradiente inferior suave para acomodar as métricas
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: _estilo == EstiloCardOverlay.rodapeMinimalista
              ? (_proporcao == ProporcaoCard.stories ? 200 : 150)
              : 170,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.45),
                  Colors.black.withValues(alpha: 0.88),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // 4. Camada de Overlay Gráfico Selecionado
        Positioned.fill(
          child: _renderizarOverlay(
            transformacao: transformacao,
            kiSessao: kiSessao,
            prsCount: prsCount,
          ),
        ),
      ],
    );
  }

  Widget _renderizarOverlay({
    required TransformacaoSaiyajin transformacao,
    required int kiSessao,
    required int prsCount,
  }) {
    switch (_estilo) {
      case EstiloCardOverlay.slimClassico:
        return _buildOverlaySlimClassico();
      case EstiloCardOverlay.scouterHud:
        return _buildOverlayScouterHud(
          transformacao: transformacao,
          kiSessao: kiSessao,
          prsCount: prsCount,
        );
      case EstiloCardOverlay.rodapeMinimalista:
        return _buildOverlayRodapeMinimalista(
          transformacao: transformacao,
        );
    }
  }

  /// 1. Preset: Slim Clássico Refinado
  /// - Topo: Apenas a pílula sutil da divisão do treino.
  /// - Centro: 100% livre para o rosto e corpo do atleta.
  /// - Base: Métricas limpas com alto contraste e rodapé com marca/handle.
  Widget _buildOverlaySlimClassico() {
    final volume = _calcularVolumeTotal();
    final volumeStr = _formatarVolume(volume);
    final totalSeries = _calcularTotalSeries();
    final handleText = _obterTextoHandle();
    final isStories = _proporcao == ProporcaoCard.stories;

    return Padding(
      padding: EdgeInsets.only(
        top: isStories ? 40.0 : 16.0,
        bottom: isStories ? 22.0 : 14.0,
        left: 18.0,
        right: 18.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Topo Desobstruído: Somente a Pílula da Divisão Centralizada
          if (widget.sessao.nomeTreino != null &&
              widget.sessao.nomeTreino!.trim().isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxWidth: 240),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4.5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                  width: 0.8,
                ),
              ),
              child: Text(
                widget.sessao.nomeTreino!.trim().toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1.6,
                  shadows: _sombraTextoForte(),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            )
          else
            const SizedBox.shrink(),

          // Base: Métricas Esportivas Limpas + Assinatura
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetricaOverlay(
                      rotulo: 'Duração',
                      valor: widget.sessao.duracaoFormatada,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricaOverlay(
                      rotulo: 'Volume',
                      valor: volumeStr,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricaOverlay(
                      rotulo: 'Séries',
                      valor: '$totalSeries',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLogoComSombra(tamanho: 28),
                      const SizedBox(width: 8),
                      Text(
                        'GYM SAIYAJIN',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.6,
                          color: Colors.white,
                          shadows: _sombraTextoForte(),
                        ),
                      ),
                    ],
                  ),
                  Flexible(
                    child: Text(
                      handleText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.90),
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
        ],
      ),
    );
  }

  /// 2. Preset: Scouter HUD Refinado
  /// - Topo: Divisão à esquerda + Carimbo Scouter à direita.
  /// - Base: Dock de telemetria unificada com métricas, logo e data integrados em uma única moldura.
  Widget _buildOverlayScouterHud({
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
        top: isStories ? 40.0 : 16.0,
        bottom: isStories ? 22.0 : 14.0,
        left: 16.0,
        right: 16.0,
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
                  widget.sessao.nomeTreino!.trim().isNotEmpty)
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
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
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                        letterSpacing: 1.0,
                        shadows: _sombraTextoForte(),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),

              // Carimbo do Scouter HUD
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: transformacao.corBadge.withValues(alpha: 0.7),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: transformacao.corBadge.withValues(alpha: 0.22),
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
                      lensColor: transformacao.corLenteScouter,
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
                          style: const TextStyle(
                            color: Colors.white,
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

          // Base: Dock de Telemetria Unificada
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: transformacao.corBadge.withValues(alpha: 0.45),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: transformacao.corBadge.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Métricas em Linha
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricaInline(
                        titulo: 'VOLUME',
                        valor: volumeStr,
                      ),
                    ),
                    _buildDivisorVertical(),
                    Expanded(
                      child: _buildMetricaInline(
                        titulo: 'DURAÇÃO',
                        valor: widget.sessao.duracaoFormatada,
                      ),
                    ),
                    _buildDivisorVertical(),
                    Expanded(
                      child: _buildMetricaInline(
                        titulo: 'SÉRIES',
                        valor: '$totalSeries',
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
                const SizedBox(height: 8),
                Divider(
                  color: Colors.white.withValues(alpha: 0.16),
                  height: 1,
                ),
                const SizedBox(height: 7),
                // Linha da Marca e Data integradas
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
                                  color: Colors.white,
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
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.90),
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

  /// 3. Preset: Rodapé Minimalista Ancorado
  /// - Topo e meio 100% desobstruídos.
  /// - Painel translúcido elegante ancorado suavemente na base.
  Widget _buildOverlayRodapeMinimalista({
    required TransformacaoSaiyajin transformacao,
  }) {
    final volume = _calcularVolumeTotal();
    final volumeStr = _formatarVolume(volume);
    final totalSeries = _calcularTotalSeries();
    final handleText = _obterTextoHandle();
    final isStories = _proporcao == ProporcaoCard.stories;

    return Padding(
      padding: EdgeInsets.only(
        bottom: isStories ? 18.0 : 12.0,
        left: 16.0,
        right: 16.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.52),
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
                          color: AppColors.primary,
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
                      ),
                    ),
                    _buildDivisorVertical(),
                    Expanded(
                      child: _buildMetricaInline(
                        titulo: 'DURAÇÃO',
                        valor: widget.sessao.duracaoFormatada,
                      ),
                    ),
                    _buildDivisorVertical(),
                    Expanded(
                      child: _buildMetricaInline(
                        titulo: 'SÉRIES',
                        valor: '$totalSeries',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(
                  color: Colors.white.withValues(alpha: 0.16),
                  height: 1,
                ),
                const SizedBox(height: 7),

                // Marca e @
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLogoComSombra(tamanho: 20),
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
                                  color: Colors.white,
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
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.white.withValues(alpha: 0.90),
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
              color: Colors.white.withValues(alpha: 0.70),
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
              color: Colors.white,
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
      height: 20,
      color: Colors.white24,
    );
  }

  /// Painel de Controles com Ergonomia Premium e SafeArea
  Widget _buildPainelControles() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF14161E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 0.8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha 1: Seletor de Presets com Setas, Indicador de Dots e Swipe
          _buildSeletorPresets(),
          const SizedBox(height: 10),

          // Linha 2: Seletor de Proporção (Stories vs Feed)
          Row(
            children: [
              Expanded(
                child: _buildBotaoProporcao(
                  rotulo: 'STORIES (9:16)',
                  proporcao: ProporcaoCard.stories,
                  icone: Icons.stay_current_portrait_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBotaoProporcao(
                  rotulo: 'FEED (1:1)',
                  proporcao: ProporcaoCard.quadrado,
                  icone: Icons.crop_square_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Linha 3: Ações de Foto (Câmera / Galeria / Excluir)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _tirarFoto,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Câmera',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: _escolherGaleria,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Galeria',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_imagemSelecionada != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: _removerFoto,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.45)),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.danger,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Linha 4: Campo de @handle ou legenda no rodapé
          TextField(
            controller: _handleController,
            style: const TextStyle(fontSize: 13, color: AppColors.textLight),
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Seu @ ou legenda no rodapé (ex: @usuario)',
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.alternate_email, size: 18, color: AppColors.primary),
              suffixIcon: _handleController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 16, color: AppColors.textDimmed),
                      onPressed: () {
                        _handleController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Seletor de Presets com Setas de Navegação, Indicador de Dots e Suporte a Swipe
  Widget _buildSeletorPresets() {
    final info = _detalhesEstilo(_estilo);
    final totalPresets = EstiloCardOverlay.values.length;
    final currentIndex = EstiloCardOverlay.values.indexOf(_estilo);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          // Seta Esquerda
          IconButton(
            onPressed: _estiloAnterior,
            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textLight, size: 26),
            tooltip: 'Preset anterior',
            splashRadius: 22,
          ),

          // Centro interativo com nome, subtítulo, ícone e dots indicadores
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) => _dragDeltaBarra = 0.0,
              onHorizontalDragUpdate: (details) => _dragDeltaBarra += details.primaryDelta ?? 0,
              onHorizontalDragEnd: (details) {
                final v = details.primaryVelocity ?? 0;
                if (_dragDeltaBarra < -30 || v < -100) _proximoEstilo();
                if (_dragDeltaBarra > 30 || v > 100) _estiloAnterior();
                _dragDeltaBarra = 0.0;
              },
              child: InkWell(
                onTap: _proximoEstilo,
                borderRadius: BorderRadius.circular(8),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.94, end: 1.0).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Row(
                      key: ValueKey(_estilo),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(info.$1, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          info.$2,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textLight,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Dots indicadores de posição do preset
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(totalPresets, (index) {
                            final isCurrent = index == currentIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 2.5),
                              width: isCurrent ? 14 : 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isCurrent ? AppColors.primary : Colors.white24,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Seta Direita
          IconButton(
            onPressed: _proximoEstilo,
            icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 26),
            tooltip: 'Próximo preset',
            splashRadius: 22,
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
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _proporcao = proporcao);
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSel ? AppColors.surface : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSel ? AppColors.primary : AppColors.cardBorder,
            width: isSel ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icone,
              size: 18,
              color: isSel ? AppColors.primary : AppColors.textDimmed,
            ),
            const SizedBox(width: 8),
            Text(
              rotulo,
              style: TextStyle(
                fontSize: 12,
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

  Widget _buildMetricaOverlay({
    required String rotulo,
    required String valor,
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
              color: Colors.white.withValues(alpha: 0.92),
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
              color: Colors.white,
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
