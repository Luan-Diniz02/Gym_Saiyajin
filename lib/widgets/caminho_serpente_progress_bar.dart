import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'planeta_kaioh_icon.dart';

/// Barra de progresso temática vetorial que reproduz o icônico Caminho da Serpente
/// de Dragon Ball Z com curvatura senoidal uniforme e o Planeta do Sr. Kaioh ao final.
class CaminhoSerpenteProgressBar extends StatelessWidget {
  final double progresso; // de 0.0 a 1.0
  final double height;

  const CaminhoSerpenteProgressBar({
    super.key,
    required this.progresso,
    this.height = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _CaminhoSerpentePainter(
          progresso: progresso.clamp(0.0, 1.0),
        ),
      ),
    );
  }
}

class _CaminhoSerpentePainter extends CustomPainter {
  final double progresso;

  _CaminhoSerpentePainter({required this.progresso});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    // Espaçamento e limites do trajeto
    final startX = 22.0;
    const planetSize = 34.0;
    final endX = w - planetSize - 2.0;
    final totalWidth = endX - startX;
    if (totalWidth <= 0) return;

    final midY = h / 2.0;
    // Amplitude da onda senoidal (ondulação suave e uniforme)
    final amplitude = (h / 2.0) - 11.0;
    // 2.5 ciclos senoidais completos na extensão do caminho
    const cycles = 2.5;

    // Constrói a curva senoidal matematicamente perfeita
    final path = Path();
    final steps = (totalWidth / 2.0).ceil();
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = startX + t * totalWidth;
      // Inicia subindo levemente, ondula em vales e cristas e finaliza no centro
      final y = midY - amplitude * math.sin(t * cycles * 2 * math.pi);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // 1. Nuvens Amarelas do Outro Mundo no fundo (sob as curvas)
    final cloudPaint = Paint()
      ..color = const Color(0xFFFFB300).withValues(alpha: 0.09)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    for (int i = 0; i < 5; i++) {
      final cloudX = startX + totalWidth * (0.12 + i * 0.19);
      final cloudY = midY + (i.isEven ? 8.0 : -8.0);
      canvas.drawCircle(Offset(cloudX, cloudY), 16.0, cloudPaint);
    }

    // 2. Sombra projetada do Caminho da Serpente sobre as nuvens
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.50)
      ..strokeWidth = 9.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.save();
    canvas.translate(0, 3.5);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // 3. Pista base do Caminho da Serpente (leito de pedras escurecido)
    final baseRoadBorderPaint = Paint()
      ..color = const Color(0xFF141E28)
      ..strokeWidth = 9.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, baseRoadBorderPaint);

    final baseRoadPaint = Paint()
      ..color = const Color(0xFF33424D)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, baseRoadPaint);

    // 4. Progresso percorrido com Ki Iluminado (Gradiente Dourado Saiyajin)
    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isNotEmpty) {
      final metric = pathMetrics.first;
      final totalLen = metric.length;
      final currentLen = totalLen * progresso;

      if (currentLen > 0) {
        final activeSubPath = metric.extractPath(0.0, currentLen);

        // Halo de brilho do Ki do guerreiro
        final glowPaint = Paint()
          ..color = AppColors.primary.withValues(alpha: 0.38)
          ..strokeWidth = 10.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawPath(activeSubPath, glowPaint);

        // Linha dourada ativa
        final activePaint = Paint()
          ..shader = ui.Gradient.linear(
            Offset(startX, midY),
            Offset(endX, midY),
            const [
              Color(0xFFFF9800),
              Color(0xFFFFD54F),
              Color(0xFFFFB300),
            ],
            const [0.0, 0.5, 1.0],
          )
          ..strokeWidth = 6.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(activeSubPath, activePaint);
      }

      // 5. Marcador do Guerreiro Saiyajin (viajando sobre a onda senoidal)
      final tangent = metric.getTangentForOffset(currentLen);
      if (tangent != null) {
        final warriorPos = tangent.position;

        // Aura de Ki externa pulsante
        final auraPaint = Paint()
          ..color = const Color(0xFFFF9800).withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(warriorPos, 8.5, auraPaint);

        // Núcleo do guerreiro (brilho dourado cel-shaded)
        final markerBorder = Paint()..color = const Color(0xFF1E1E1E);
        canvas.drawCircle(warriorPos, 5.0, markerBorder);

        final markerCore = Paint()..color = const Color(0xFFFFD54F);
        canvas.drawCircle(warriorPos, 3.5, markerCore);

        final centerWhite = Paint()..color = Colors.white;
        canvas.drawCircle(warriorPos, 1.5, centerWhite);
      }
    }

    // 6. Início da Jornada: Cauda da Serpente estilizada
    final tailBorder = Paint()..color = const Color(0xFF141E28);
    canvas.drawCircle(Offset(startX, midY), 5.5, tailBorder);
    final tailPaint = Paint()..color = const Color(0xFFFF9800);
    canvas.drawCircle(Offset(startX, midY), 3.5, tailPaint);

    // 7. Destino Final: Planeta do Sr. Kaioh renderizado em alta definição
    final planetOrigin = Offset(endX, midY - planetSize / 2.0);
    canvas.save();
    canvas.translate(planetOrigin.dx, planetOrigin.dy);
    const PlanetaKaiohPainter().paint(canvas, const Size(planetSize, planetSize));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CaminhoSerpentePainter oldDelegate) {
    return (oldDelegate.progresso - progresso).abs() > 0.001;
  }
}
