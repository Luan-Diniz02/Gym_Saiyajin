import 'dart:math' as math;
import 'package:flutter/material.dart';

/// CustomPainter que desenha a Escotilha da Câmara de Regeneração Médica
/// (Cápsula de Cura de Namekusei / Freeza Force).
///
/// Apresenta:
/// - Aro metálico exterior industrial em liga escura com 8 rebites prateados chanfrados.
/// - Anel de fluido bioenergético ciano/esmeralda proporcional ao progresso.
/// - Vidro interno circular escurecido com fluido medicinal translúcido.
/// - Silhueta sutil e imersiva da máscara de oxigênio submersa ao fundo.
/// - Micro-bolhas de ar/oxigênio subindo continuamente com oscilação orgânica.
/// - Brilho especular curvo de vidro acrílico.
class EscotilhaCamaraPainter extends CustomPainter {
  final double animationValue;
  final bool isAtivo;
  final double progresso; // 0.0 (vazio) a 1.0 (cheio)

  const EscotilhaCamaraPainter({
    required this.animationValue,
    required this.isAtivo,
    required this.progresso,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    const rimWidth = 14.0;
    final glassRadius = outerRadius - rimWidth;

    _desenharAroMetalico(canvas, center, outerRadius, rimWidth);
    _desenharRebites(canvas, center, outerRadius - rimWidth / 2);
    _desenharAnelFluido(canvas, center, outerRadius - rimWidth + 1, progresso);
    _desenharVidroEFluido(canvas, center, glassRadius);
    _desenharMascaraSubmersa(canvas, center, glassRadius);
    _desenharBolhasOxigenio(canvas, center, glassRadius);
    _desenharReflexoVidro(canvas, center, glassRadius);
  }

  /// Desenha a moldura circular de titânio escuro com chanfro 3D
  void _desenharAroMetalico(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double rimWidth,
  ) {
    // Sombra projetada da escotilha
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, outerRadius - 1, shadowPaint);

    // Borda metálica principal com gradiente circular chanfrado
    final rimPaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0xFF262C3A), // Interior metálico
          Color(0xFF181B24), // Vinco central
          Color(0xFF2C3242), // Borda elevada
          Color(0xFF13151D), // Borda externa
        ],
        stops: const [0.75, 0.85, 0.95, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerRadius, rimPaint);

    // Anel de chanfro interno
    final innerBevelPaint = Paint()
      ..color = const Color(0xFF384055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, outerRadius - rimWidth + 1, innerBevelPaint);

    // Linha de contorno externa ultrafina
    final outerStrokePaint = Paint()
      ..color = const Color(0xFF454E66)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, outerRadius - 0.5, outerStrokePaint);
  }

  /// Desenha 8 rebites/parafusos industriais prateados simétricos
  void _desenharRebites(Canvas canvas, Offset center, double boltRadius) {
    final boltBasePaint = Paint()..style = PaintingStyle.fill;
    final boltHighlightPaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..style = PaintingStyle.fill;
    final boltShadowPaint = Paint()
      ..color = const Color(0xFF0D0F14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int i = 0; i < 8; i++) {
      final angle = i * (math.pi / 4);
      final bx = center.dx + boltRadius * math.cos(angle);
      final by = center.dy + boltRadius * math.sin(angle);
      final bCenter = Offset(bx, by);
      const bRadius = 3.2;

      // Base do rebite
      boltBasePaint.shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: const [
          Color(0xFFCFD8DC),
          Color(0xFF78909C),
          Color(0xFF37474F),
        ],
        stops: const [0.2, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: bCenter, radius: bRadius));

      canvas.drawCircle(bCenter, bRadius, boltBasePaint);
      canvas.drawCircle(bCenter, bRadius, boltShadowPaint);

      // Fenda/Ponto central do parafuso
      canvas.drawCircle(bCenter, 0.9, Paint()..color = const Color(0xFF1E2430));

      // Ponto de brilho especular
      canvas.drawCircle(
        Offset(bx - 0.9, by - 0.9),
        0.6,
        boltHighlightPaint,
      );
    }
  }

  /// Desenha o anel circular de fluido bioenergético com glow medicinal
  void _desenharAnelFluido(
    Canvas canvas,
    Offset center,
    double radius,
    double progresso,
  ) {
    const strokeWidth = 5.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Trilho de fundo (fluido escuro em repouso)
    final trackPaint = Paint()
      ..color = const Color(0xFF063336).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, trackPaint);

    if (progresso <= 0) return;

    final sweepAngle = 2 * math.pi * progresso.clamp(0.0, 1.0);

    // Brilho exterior (Glow suave) quando ativo
    if (isAtivo) {
      final glowPaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, glowPaint);
    }

    // Arco frontal do fluido em gradiente ciano -> verde-água medicinal
    final progressPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [
          Color(0xFF00E5FF), // Ciano puro
          Color(0xFF00BFA5), // Verde-água medicinal
          Color(0xFF1DE9B6), // Esmeralda bioenergética
          Color(0xFF00E5FF),
        ],
        stops: [0.0, 0.45, 0.8, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);
  }

  /// Desenha o interior de vidro com fluido medicinal profundo
  void _desenharVidroEFluido(Canvas canvas, Offset center, double glassRadius) {
    final glassRect = Rect.fromCircle(center: center, radius: glassRadius);

    // Gradiente submarino profundo de líquido curativo
    final liquidPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.95,
        colors: isAtivo
            ? const [
                Color(0xFF0B2E33), // Centro com bioluminescência ativa
                Color(0xFF062024), // Meio tom
                Color(0xFF031114), // Borda escura profunda
              ]
            : const [
                Color(0xFF081C20), // Repouso / escuro
                Color(0xFF051518),
                Color(0xFF020B0D),
              ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(glassRect)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, glassRadius, liquidPaint);

    // Vinco interno escuro no limite do vidro
    final innerBorder = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, glassRadius - 1, innerBorder);
  }

  /// Desenha a silhueta da máscara respiratória submersa no fundo da câmara
  void _desenharMascaraSubmersa(
    Canvas canvas,
    Offset center,
    double glassRadius,
  ) {
    canvas.save();
    // Clip para garantir que nada transborde o vidro
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: glassRadius - 2)),
    );

    // A máscara repousa sutilmente no centro inferior
    final maskCenterY = center.dy + glassRadius * 0.22;
    final maskCenterX = center.dx;

    final maskFillPaint = Paint()
      ..color = const Color(0xFF00383D).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final maskStrokePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Formato da concha da máscara de oxigênio
    const mw = 22.0;
    const mh = 16.0;
    final maskRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(maskCenterX, maskCenterY),
        width: mw * 2,
        height: mh * 2,
      ),
      const Radius.circular(10),
    );

    canvas.drawRRect(maskRect, maskFillPaint);
    canvas.drawRRect(maskRect, maskStrokePaint);

    // Filtro central / grelha da máscara
    final grillPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(maskCenterX - 10, maskCenterY - 3),
      Offset(maskCenterX + 10, maskCenterY - 3),
      grillPaint,
    );
    canvas.drawLine(
      Offset(maskCenterX - 8, maskCenterY + 3),
      Offset(maskCenterX + 8, maskCenterY + 3),
      grillPaint,
    );

    // Mangueiras sanfonadas conectadas aos lados e descendo
    final hosePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final leftHose = Path()
      ..moveTo(maskCenterX - 16, maskCenterY + 6)
      ..cubicTo(
        maskCenterX - 30,
        maskCenterY + 12,
        maskCenterX - 35,
        maskCenterY + 30,
        maskCenterX - 30,
        center.dy + glassRadius,
      );
    canvas.drawPath(leftHose, hosePaint);

    final rightHose = Path()
      ..moveTo(maskCenterX + 16, maskCenterY + 6)
      ..cubicTo(
        maskCenterX + 30,
        maskCenterY + 12,
        maskCenterX + 35,
        maskCenterY + 30,
        maskCenterX + 30,
        center.dy + glassRadius,
      );
    canvas.drawPath(rightHose, hosePaint);

    canvas.restore();
  }

  /// Desenha bolhas de oxigênio procedurais subindo pelo líquido
  void _desenharBolhasOxigenio(
    Canvas canvas,
    Offset center,
    double glassRadius,
  ) {
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: glassRadius - 3)),
    );

    // Conjunto balanceado de bolhas com propriedades físicas próprias
    const bubbles = [
      _BolhaDef(xRel: -0.42, speed: 1.0, radius: 2.8, phase: 0.05),
      _BolhaDef(xRel: -0.20, speed: 1.3, radius: 2.0, phase: 0.35),
      _BolhaDef(xRel: 0.05, speed: 0.9, radius: 3.5, phase: 0.65),
      _BolhaDef(xRel: 0.28, speed: 1.1, radius: 2.4, phase: 0.20),
      _BolhaDef(xRel: 0.45, speed: 0.8, radius: 3.8, phase: 0.80),
      _BolhaDef(xRel: -0.10, speed: 1.4, radius: 1.8, phase: 0.50),
      _BolhaDef(xRel: 0.35, speed: 1.2, radius: 2.2, phase: 0.10),
    ];

    final bubbleStrokePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: isAtivo ? 0.65 : 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final bubbleFillPaint = Paint()
      ..color = const Color(0xFF00BFA5).withValues(alpha: isAtivo ? 0.22 : 0.08)
      ..style = PaintingStyle.fill;

    final bubbleHighlight = Paint()
      ..color = Colors.white.withValues(alpha: isAtivo ? 0.75 : 0.3)
      ..style = PaintingStyle.fill;

    final effectiveAnim = isAtivo ? animationValue : 0.2;
    final totalHeight = glassRadius * 2.0;

    for (final b in bubbles) {
      // Cálculo de subida contínua
      final progressoBolha = (effectiveAnim * b.speed + b.phase) % 1.0;
      final by = (center.dy + glassRadius) - (progressoBolha * totalHeight);

      // Leve oscilação horizontal orgânica
      final sway = math.sin((by / glassRadius) * 2.5 * math.pi) * 3.5;
      final bx = center.dx + (b.xRel * (glassRadius * 0.78)) + sway;

      // Desvanecimento suave nas bordas superior e inferior
      final distFromCenter = (Offset(bx, by) - center).distance;
      if (distFromCenter >= glassRadius - b.radius - 2) continue;

      final bCenter = Offset(bx, by);

      canvas.drawCircle(bCenter, b.radius, bubbleFillPaint);
      canvas.drawCircle(bCenter, b.radius, bubbleStrokePaint);

      // Ponto de brilho especular na bolha
      canvas.drawCircle(
        Offset(bx - b.radius * 0.35, by - b.radius * 0.35),
        b.radius * 0.28,
        bubbleHighlight,
      );
    }

    canvas.restore();
  }

  /// Desenha o reflexo curvo de luz no vidro acrílico da escotilha
  void _desenharReflexoVidro(Canvas canvas, Offset center, double glassRadius) {
    final arcRect = Rect.fromCircle(
      center: center,
      radius: glassRadius - 4,
    );

    // Reflexo superior curvo
    final specPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -math.pi * 0.75,
        endAngle: -math.pi * 0.15,
        colors: [
          Colors.transparent,
          Color(0x3300E5FF),
          Color(0x55FFFFFF),
          Color(0x3300E5FF),
          Colors.transparent,
        ],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(arcRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      arcRect,
      -math.pi * 0.75,
      math.pi * 0.6,
      false,
      specPaint,
    );
  }

  @override
  bool shouldRepaint(covariant EscotilhaCamaraPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isAtivo != isAtivo ||
        oldDelegate.progresso != progresso;
  }
}

class _BolhaDef {
  final double xRel;
  final double speed;
  final double radius;
  final double phase;

  const _BolhaDef({
    required this.xRel,
    required this.speed,
    required this.radius,
    required this.phase,
  });
}
