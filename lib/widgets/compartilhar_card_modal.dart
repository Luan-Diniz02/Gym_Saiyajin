import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/sessao_treino.dart';
import '../services/card_share_service.dart';
import '../theme/app_colors.dart';

class CompartilharCardModal extends StatefulWidget {
  final SessaoTreino sessao;

  const CompartilharCardModal({
    super.key,
    required this.sessao,
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

  Future<void> _compartilharComoImagem() async {
    setState(() {
      _isGerandoImagem = true;
    });

    try {
      final dataStr = _formatarData(widget.sessao.data).replaceAll('/', '-');
      final nomeArquivo = 'treino_saiyajin_$dataStr';

      // Compartilha exclusivamente a imagem PNG, sem texto acompanhando
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview do Card estilizado 9:16 (Borda sutil apenas na pré-visualização)
            _buildCardVisual(),
            const SizedBox(height: 14),

            // Controles de Foto e Compartilhamento
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  // Ações de Foto
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: _tirarFoto,
                        icon: const Icon(Icons.camera_alt, color: AppColors.primary, size: 20),
                        label: const Text(
                          'Câmera',
                          style: TextStyle(color: AppColors.textLight, fontSize: 13),
                        ),
                      ),
                      Container(width: 1, height: 24, color: AppColors.cardBorder),
                      TextButton.icon(
                        onPressed: _escolherGaleria,
                        icon: const Icon(Icons.photo_library, color: AppColors.primary, size: 20),
                        label: const Text(
                          'Galeria',
                          style: TextStyle(color: AppColors.textLight, fontSize: 13),
                        ),
                      ),
                      if (_imagemSelecionada != null) ...[
                        Container(width: 1, height: 24, color: AppColors.cardBorder),
                        IconButton(
                          onPressed: _removerFoto,
                          icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                          tooltip: 'Remover foto',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Campo opcional para arroba / legenda (quando tem foto)
                  if (_imagemSelecionada != null) ...[
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
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Botão principal COMPARTILHAR
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isGerandoImagem ? null : _compartilharComoImagem,
                      icon: _isGerandoImagem
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.background,
                              ),
                            )
                          : const Icon(Icons.share, size: 20),
                      label: Text(
                        _isGerandoImagem ? 'GERANDO...' : 'COMPARTILHAR',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1.0,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Botão Fechar
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Fechar',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardVisual() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: RepaintBoundary(
        key: _cardKey,
        child: SizedBox(
          width: 320,
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: _imagemSelecionada != null ? _buildModoFoto() : _buildModoEstatisticas(),
          ),
        ),
      ),
    );
  }

  /// Estilo inspirado no Hevy: A foto é 100% edge-to-edge sem bordas, com overlay limpo no topo e rodapé perfeitamente alinhado
  Widget _buildModoFoto() {
    final volume = _calcularVolumeTotal();
    final volumeStr = _formatarVolume(volume);
    final totalSeries = _calcularTotalSeries();
    final handleText = _handleController.text.trim().isNotEmpty
        ? (_handleController.text.trim().startsWith('@')
            ? _handleController.text.trim()
            : '@${_handleController.text.trim()}')
        : _formatarData(widget.sessao.data);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Foto do usuário em tela cheia 9:16 (sem bordas, preenchimento total)
        Positioned.fill(
          child: Image.file(
            File(_imagemSelecionada!.path),
            fit: BoxFit.cover,
          ),
        ),

        // Gradiente superior sutil para legibilidade das métricas
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 180,
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

        // Gradiente inferior sutil para legibilidade do rodapé
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 130,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.75),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Conteúdo: Topo (com respiro para Stories) e Rodapé perfeitamente nivelado
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 48.0,
              bottom: 30.0,
              left: 22.0,
              right: 22.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Topo com métricas limpas (estilo Hevy)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricaOverlay(
                      rotulo: 'Duração',
                      valor: widget.sessao.duracaoFormatada,
                    ),
                    _buildMetricaOverlay(
                      rotulo: 'Volume',
                      valor: volumeStr,
                    ),
                    _buildMetricaOverlay(
                      rotulo: 'Séries',
                      valor: '$totalSeries',
                    ),
                  ],
                ),

                // Rodapé com logo e @ / data rigorosamente alinhados no mesmo centro vertical
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Marca Gym Saiyajin (slim e moderna, com sombra flutuante orgânica)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildLogoComSombra(tamanho: 34),
                        const SizedBox(width: 8),
                        Text(
                          'GYM SAIYAJIN',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.9),
                                blurRadius: 6,
                                offset: const Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // @ do usuário ou data
                    Flexible(
                      child: Text(
                        handleText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.9),
                              blurRadius: 6,
                              offset: const Offset(1, 1),
                            ),
                          ],
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
          ),
        ),
      ],
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
        Text(
          rotulo,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.92),
            letterSpacing: 0.2,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 6,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.3,
            shadows: [
              Shadow(
                color: Colors.black,
                blurRadius: 8,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Logo oficial do Shenlong com silhueta de sombra projetada para fotos
  Widget _buildLogoComSombra({double tamanho = 34}) {
    return SizedBox(
      width: tamanho,
      height: tamanho,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sombra projetada no contorno exato da logo (alpha silhouette)
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
          // Logo original nítida transparente
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

  /// Estilo Card Saiyajin completo (quando não há foto)
  Widget _buildModoEstatisticas() {
    final volume = _calcularVolumeTotal();
    final volumeStr = _formatarVolume(volume);
    final totalSeries = _calcularTotalSeries();
    final totalExercicios = widget.sessao.exerciciosConcluidosHoje.length;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1F1708),
            AppColors.background,
            Color(0xFF140D04),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Topo com Logo e Data
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/shenlong_logo.png',
                    width: 34,
                    height: 34,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'GYM SAIYAJIN',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatarData(widget.sessao.data),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textDimmed,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Destaque de Volume Total
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                const Text(
                  'VOLUME TOTAL LEVANTADO',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDimmed,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  volumeStr,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),

          // Grid de Métricas
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetricaCard(
                      icone: Icons.timer,
                      titulo: 'DURAÇÃO',
                      valor: widget.sessao.duracaoFormatada,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricaCard(
                      icone: Icons.pause_circle_outline,
                      titulo: 'DESCANSO',
                      valor: widget.sessao.descansoFormatado,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricaCard(
                      icone: Icons.fitness_center,
                      titulo: 'EXERCÍCIOS',
                      valor: '$totalExercicios',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricaCard(
                      icone: Icons.format_list_numbered,
                      titulo: 'SÉRIES',
                      valor: '$totalSeries',
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Principais Exercícios
          if (widget.sessao.exerciciosConcluidosHoje.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PRINCIPAIS EXERCÍCIOS:',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.textDimmed,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...widget.sessao.exerciciosConcluidosHoje.take(4).map((ex) {
                    double maxCarga = 0;
                    for (final s in ex.seriesDetalhes) {
                      if ((s.peso ?? 0) > maxCarga) maxCarga = s.peso ?? 0;
                    }
                    final cargaStr = maxCarga > 0
                        ? (maxCarga % 1 == 0 ? '${maxCarga.toInt()} kg' : '${maxCarga.toStringAsFixed(1)} kg')
                        : '';

                    final numSeries = ex.seriesDetalhes.length;
                    final seriesText = '$numSeries ${numSeries == 1 ? "série" : "séries"}';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.0),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_right, color: AppColors.primary, size: 16),
                          Expanded(
                            child: Text(
                              ex.nome,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            seriesText,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textDimmed,
                            ),
                          ),
                          if (cargaStr.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              cargaStr,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  if (widget.sessao.exerciciosConcluidosHoje.length > 4)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, left: 14),
                      child: Text(
                        '+ ${widget.sessao.exerciciosConcluidosHoje.length - 4} outro(s)',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Frase de encerramento Saiyajin
          const Text(
            '⚡ SUPERE SEUS LIMITES! ⚡',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricaCard({
    required IconData icone,
    required String titulo,
    required String valor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icone, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textDimmed,
                  ),
                ),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
