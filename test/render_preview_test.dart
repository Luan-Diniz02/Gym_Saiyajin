import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/widgets/capsule_icon.dart';
import 'package:gym_saiyajin/widgets/dragon_ball_icon.dart';
import 'package:gym_saiyajin/widgets/dragon_radar_icon.dart';
import 'package:gym_saiyajin/widgets/escotilha_camara_painter.dart';
import 'package:gym_saiyajin/widgets/ki_aura_icon.dart';
import 'package:gym_saiyajin/widgets/planeta_kaioh_icon.dart';

void main() {
  test('Renderizar preview dos icones em PNG de alta resolucao', () async {
    final envDir = Platform.environment['ANTIGRAVITY_OUTPUT_DIR'];
    final outputDir = (envDir != null && envDir.isNotEmpty && Directory(envDir).existsSync())
        ? envDir
        : '${Directory.systemTemp.path}/gym_saiyajin_previews';
    await Directory(outputDir).create(recursive: true);

    Future<void> renderPainter(CustomPainter painter, String fileName, {double size = 256}) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

      // Fundo escuro sutil para destacar os ícones como no app
      final bgPaint = Paint()..color = const Color(0xFF16171D);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size, size), const Radius.circular(32)),
        bgPaint,
      );

      // Renderiza com margem
      canvas.save();
      final padding = size * 0.10;
      canvas.translate(padding, padding);
      painter.paint(canvas, Size(size - padding * 2, size - padding * 2));
      canvas.restore();

      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      try {
        final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
        final buffer = byteData!.buffer.asUint8List();

        final file = File('$outputDir/$fileName');
        await file.writeAsBytes(buffer);
      } finally {
        img.dispose();
      }
    }

    // Renderizar DragonRadarIcon com 3 dots e com 7 dots
    await renderPainter(const DragonRadarPainter(dots: 3), 'preview_dragon_radar_3dots.png', size: 300);
    await renderPainter(const DragonRadarPainter(dots: 7), 'preview_dragon_radar_7dots.png', size: 300);
    await renderPainter(const DragonRadarPainter(dots: 1), 'preview_dragon_radar_1dot.png', size: 300);

    // Renderizar DragonBallIcon com 4 estrelas (clássica) e 7 estrelas
    await renderPainter(const DragonBallPainter(stars: 4), 'preview_dragon_ball_4stars.png', size: 300);
    await renderPainter(const DragonBallPainter(stars: 7), 'preview_dragon_ball_7stars.png', size: 300);
    await renderPainter(const DragonBallPainter(stars: 1), 'preview_dragon_ball_1star.png', size: 300);

    // Renderizar CapsuleIcon (Azul clássico Capsule Corp, Laranja Saiyajin, Verde e Vermelho)
    await renderPainter(const CapsulePainter(color: Color(0xFF00A3FF)), 'preview_capsule_blue.png', size: 300);
    await renderPainter(const CapsulePainter(color: Color(0xFFFF9800)), 'preview_capsule_orange.png', size: 300);
    await renderPainter(const CapsulePainter(color: Color(0xFF22C55E)), 'preview_capsule_green.png', size: 300);
    await renderPainter(const CapsulePainter(color: Color(0xFFEF4444)), 'preview_capsule_red.png', size: 300);

    // Renderizar PlanetaKaiohIcon (Planeta do Senhor Kaioh com casa, anexo, pista e carro)
    await renderPainter(const PlanetaKaiohPainter(), 'preview_planeta_kaioh.png', size: 300);

    // Renderizar Escotilha da Câmara de Regeneração (Repouso e Ativa)
    await renderPainter(
      const EscotilhaCamaraPainter(
        animationValue: 0.35,
        isAtivo: true,
        progresso: 0.65,
      ),
      'preview_escotilha_camara_ativa.png',
      size: 320,
    );
    await renderPainter(
      const EscotilhaCamaraPainter(
        animationValue: 0.0,
        isAtivo: false,
        progresso: 1.0,
      ),
      'preview_escotilha_camara_repouso.png',
      size: 320,
    );

    // Renderizar KiAuraIcon (Aura Dourada SSJ, Kaio-ken Vermelha, Ciano Guerreiro Z e Púrpura)
    await renderPainter(
      const KiAuraPainter(
        primaryColor: Color(0xFFFFD700),
        secondaryColor: Color(0xFFFF8C00),
        coreColor: Color(0xFFFFFDE7),
      ),
      'preview_ki_aura_gold.png',
      size: 300,
    );
    await renderPainter(
      const KiAuraPainter(
        primaryColor: Color(0xFFFF5252),
        secondaryColor: Color(0xFFD50000),
        coreColor: Color(0xFFFFEBEE),
      ),
      'preview_ki_aura_red.png',
      size: 300,
    );
    await renderPainter(
      const KiAuraPainter(
        primaryColor: Color(0xFF4FC3F7),
        secondaryColor: Color(0xFF0288D1),
        coreColor: Color(0xFFE1F5FE),
      ),
      'preview_ki_aura_cyan.png',
      size: 300,
    );
    await renderPainter(
      const KiAuraPainter(
        primaryColor: Color(0xFFAB47BC),
        secondaryColor: Color(0xFF6A1B9A),
        coreColor: Color(0xFFF3E5F5),
      ),
      'preview_ki_aura_purple.png',
      size: 300,
    );
  });
}
