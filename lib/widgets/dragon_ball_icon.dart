import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Ícone vetorial da icônica Esfera do Dragão (Dragon Ball) de Dragon Ball Z.
/// Renderizado com fidelidade através de [CustomPainter], incluindo gradiente
/// esférico dourado-alaranjado, profundidade translúcida, estrelas rubi com
/// relevo multifacetado e brilhos especulares cel-shaded.
class DragonBallIcon extends StatelessWidget {
  final double size;
  final int stars;

  const DragonBallIcon({
    super.key,
    this.size = 24.0,
    this.stars = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: DragonBallPainter(stars: stars),
      ),
    );
  }
}

/// [CustomPainter] de alto desempenho para desenhar a Esfera do Dragão vetorial.
class DragonBallPainter extends CustomPainter {
  final int stars;

  const DragonBallPainter({this.stars = 4});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final radius = math.min(w, h) / 2;
    if (radius <= 0) return;

    final center = Offset(w / 2, h / 2);
    final sphereRect = Rect.fromCircle(center: center, radius: radius);

    // 1. Clip para garantir que nada extrapole a esfera perfeitamente circular
    canvas.save();
    final clipPath = Path()..addOval(sphereRect);
    canvas.clipPath(clipPath);

    // 2. Base da esfera: Gradiente esférico radial
    // Ponto focal de iluminação deslocado ligeiramente para o canto superior esquerdo
    final spherePaint = Paint()
      ..isAntiAlias = true
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.28),
        radius: 0.95,
        colors: const [
          Color(0xFFFFD54F), // Âmbar claro dourado
          Color(0xFFFFB300), // Âmbar brilhante
          Color(0xFFFF8F00), // Laranja âmbar vibrante
          Color(0xFFF57C00), // Laranja quente
          Color(0xFFE65100), // Borda âmbar-alaranjada profunda
        ],
        stops: const [0.0, 0.28, 0.58, 0.84, 1.0],
      ).createShader(sphereRect);
    canvas.drawCircle(center, radius, spherePaint);

    // 3. Sombra de profundidade e curvatura no quadrante inferior/direito
    final depthPaint = Paint()
      ..isAntiAlias = true
      ..shader = RadialGradient(
        center: const Alignment(0.40, 0.40),
        radius: 0.85,
        colors: [
          Colors.transparent,
          const Color(0xFFBF360C).withValues(alpha: 0.45),
        ],
        stops: const [0.55, 1.0],
      ).createShader(sphereRect);
    canvas.drawCircle(center, radius, depthPaint);

    // 4. Brilho cáustico de refração interna na parte inferior-direita
    final causticPaint = Paint()
      ..isAntiAlias = true
      ..shader = RadialGradient(
        center: const Alignment(0.42, 0.42),
        radius: 0.70,
        colors: [
          Colors.transparent,
          const Color(0xFFFFB74D).withValues(alpha: 0.30),
          Colors.transparent,
        ],
        stops: const [0.65, 0.88, 1.0],
      ).createShader(sphereRect);
    canvas.drawCircle(center, radius, causticPaint);

    // 5. Borda externa suave para delimitar o volume esférico
    final rimDepthPaint = Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFFBF360C).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (radius * 0.05).clamp(0.6, 2.0);
    canvas.drawCircle(
      center,
      radius - rimDepthPaint.strokeWidth / 2,
      rimDepthPaint,
    );

    // 6. Brilho em crescente de marfim/branco na borda superior-esquerda
    final rimLightPaint = Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFFFFFDE7).withValues(alpha: 0.80)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (radius * 0.055).clamp(0.8, 2.5);
    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius - rimLightPaint.strokeWidth / 2,
      ),
      math.pi * 1.02,
      math.pi * 0.50,
      false,
      rimLightPaint,
    );

    // 7. Estrelas vermelhas de 5 pontas com relevo facetado
    _drawStars(canvas, center, radius);

    // 8. Brilho especular primário: arco em crescente translúcido marfim/branco
    final highlightArcPaint = Paint()
      ..isAntiAlias = true
      ..color = Colors.white.withValues(alpha: 0.90)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (radius * 0.18).clamp(1.8, 20.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.70),
      math.pi * 1.13,
      math.pi * 0.24,
      false,
      highlightArcPaint,
    );

    // 9. Ponto focal de reflexo secundário: pequena pílula/oval inclinada a ~9:30h
    canvas.save();
    canvas.translate(center.dx - radius * 0.60, center.dy - radius * 0.22);
    canvas.rotate(-0.48); // Inclinação tangente à curvatura da esfera
    final dotRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: (radius * 0.09).clamp(1.2, 12.0),
        height: (radius * 0.17).clamp(2.0, 22.0),
      ),
      Radius.circular(radius * 0.06),
    );
    final dotPaint = Paint()
      ..isAntiAlias = true
      ..color = Colors.white.withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(dotRRect, dotPaint);
    canvas.restore();

    canvas.restore(); // Restaura o clip da esfera
  }

  void _drawStars(Canvas canvas, Offset center, double radius) {
    final positions = _getStarPositions(center, radius, stars);
    // Proporção do tamanho da estrela em relação à esfera
    final double starRadius = stars == 4 ? radius * 0.21 : radius * 0.19;
    final double innerRadius = starRadius * 0.41;

    final basePaint = Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFFD50000)
      ..style = PaintingStyle.fill;

    final shadowFacetPaint = Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFF800000)
      ..style = PaintingStyle.fill;

    final lightFacetPaint = Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.fill;

    final subtleDropShadowPaint = Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFF7F1000).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    for (final pos in positions) {
      final vertices = <Offset>[];
      for (int k = 0; k < 10; k++) {
        final angle = -math.pi / 2 + k * (math.pi / 5);
        final r = k.isEven ? starRadius : innerRadius;
        vertices.add(Offset(
          pos.dx + r * math.cos(angle),
          pos.dy + r * math.sin(angle),
        ));
      }

      final starPath = Path()..moveTo(vertices[0].dx, vertices[0].dy);
      for (int k = 1; k < 10; k++) {
        starPath.lineTo(vertices[k].dx, vertices[k].dy);
      }
      starPath.close();

      // Sombra sutil projetada dentro da resina transparente
      if (radius >= 12) {
        final shadowOffset = Offset(radius * 0.02, radius * 0.02);
        canvas.drawPath(starPath.shift(shadowOffset), subtleDropShadowPaint);
      }

      // Base rubi da estrela
      canvas.drawPath(starPath, basePaint);

      // Facetas 3D de relevo (estrelas lapidadas clássicas de Dragon Ball)
      for (int i = 0; i < 5; i++) {
        final tip = vertices[2 * i];
        final leftValley = vertices[(2 * i - 1 + 10) % 10];
        final rightValley = vertices[(2 * i + 1) % 10];

        // Faceta direita (sombra)
        final shadowPath = Path()
          ..moveTo(pos.dx, pos.dy)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(rightValley.dx, rightValley.dy)
          ..close();
        canvas.drawPath(shadowPath, shadowFacetPaint);

        // Faceta esquerda (iluminada)
        final lightPath = Path()
          ..moveTo(pos.dx, pos.dy)
          ..lineTo(leftValley.dx, leftValley.dy)
          ..lineTo(tip.dx, tip.dy)
          ..close();
        canvas.drawPath(lightPath, lightFacetPaint);
      }

      // Linha de vinco central sutil nas pontas
      if (radius >= 14) {
        final ridgePaint = Paint()
          ..isAntiAlias = true
          ..color = const Color(0xFFFF5252).withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (radius * 0.015).clamp(0.4, 1.2);
        for (int i = 0; i < 5; i++) {
          final tip = vertices[2 * i];
          canvas.drawLine(pos, tip, ridgePaint);
        }
      }
    }
  }

  List<Offset> _getStarPositions(Offset center, double radius, int count) {
    if (count <= 1) {
      return [center];
    } else if (count == 2) {
      final d = radius * 0.28;
      return [
        Offset(center.dx - d, center.dy - d),
        Offset(center.dx + d, center.dy + d),
      ];
    } else if (count == 3) {
      final d = radius * 0.28;
      return [
        Offset(center.dx, center.dy - d * 1.05),
        Offset(center.dx - d * 0.95, center.dy + d * 0.65),
        Offset(center.dx + d * 0.95, center.dy + d * 0.65),
      ];
    } else if (count == 4) {
      // 4 estrelas: exatamente 2 acima e 2 abaixo, perfeitamente simétricas
      final d = radius * 0.28;
      return [
        Offset(center.dx - d, center.dy - d),
        Offset(center.dx + d, center.dy - d),
        Offset(center.dx - d, center.dy + d),
        Offset(center.dx + d, center.dy + d),
      ];
    } else if (count == 5) {
      final d = radius * 0.34;
      return [
        Offset(center.dx - d, center.dy - d),
        Offset(center.dx + d, center.dy - d),
        center,
        Offset(center.dx - d, center.dy + d),
        Offset(center.dx + d, center.dy + d),
      ];
    } else if (count == 6) {
      final dx = radius * 0.28;
      final dy = radius * 0.32;
      return [
        Offset(center.dx - dx, center.dy - dy),
        Offset(center.dx + dx, center.dy - dy),
        Offset(center.dx - dx, center.dy),
        Offset(center.dx + dx, center.dy),
        Offset(center.dx - dx, center.dy + dy),
        Offset(center.dx + dx, center.dy + dy),
      ];
    } else {
      // 7 estrelas: 1 central + 6 ao redor em anel
      final d = radius * 0.36;
      final list = <Offset>[center];
      for (int i = 0; i < 6; i++) {
        final angle = (i * 60 - 90) * math.pi / 180;
        list.add(Offset(
          center.dx + d * math.cos(angle),
          center.dy + d * math.sin(angle),
        ));
      }
      return list;
    }
  }

  @override
  bool shouldRepaint(covariant DragonBallPainter oldDelegate) {
    return oldDelegate.stars != stars;
  }
}
