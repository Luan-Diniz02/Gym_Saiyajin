import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Ícone vetorial nativo do clássico Radar do Dragão (Dragon Radar) criado por Bulma.
///
/// Renderizado via [CustomPainter] de alta performance, incluindo:
/// - Gabinete metálico com bisel prateado chanfrado e botão de cronômetro superior;
/// - Pontos de registro/calibração laterais e inferiores;
/// - Visor CRT/LCD verde esmeralda com grade ortogonal de coordenadas;
/// - Reflexo especular curvo de lente de vidro;
/// - Cursor central de localização com triângulo rubi e retículo amarelo;
/// - Esferas do Dragão luminosas rastreadas na tela ([dots], de 0 a 7).
class DragonRadarIcon extends StatelessWidget {
  /// Tamanho do widget em pixels (largura e altura proporcionais).
  final double size;

  /// Quantidade de esferas detectadas na tela (0 a 7). Padrão: 3.
  /// Idealmente vinculado aos dias ativos da meta semanal.
  final int dots;

  /// Se deve exibir o cursor central em forma de triângulo vermelho.
  final bool showCenterArrow;

  /// Se deve exibir as linhas de retículo/mira amarela central.
  final bool showCrosshair;

  const DragonRadarIcon({
    super.key,
    this.size = 28.0,
    this.dots = 3,
    this.showCenterArrow = true,
    this.showCrosshair = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: DragonRadarPainter(
          dots: dots,
          showCenterArrow: showCenterArrow,
          showCrosshair: showCrosshair,
        ),
      ),
    );
  }
}

/// [CustomPainter] de precisão geométrica para desenhar o Radar do Dragão em Canvas.
class DragonRadarPainter extends CustomPainter {
  final int dots;
  final bool showCenterArrow;
  final bool showCrosshair;

  const DragonRadarPainter({
    this.dots = 3,
    this.showCenterArrow = true,
    this.showCrosshair = true,
  });

  // Coordenadas relativas normalizadas [-1.0, 1.0] para até 7 esferas na tela verde
  static const List<Offset> _dragonBallPositions = [
    Offset(0.48, -0.38),  // 1ª Esfera: Superior Direita
    Offset(-0.55, -0.18), // 2ª Esfera: Centro-Esquerda
    Offset(-0.35, 0.52),  // 3ª Esfera: Inferior Esquerda
    Offset(0.25, 0.48),   // 4ª Esfera: Inferior Direita
    Offset(-0.25, -0.52), // 5ª Esfera: Superior Esquerda
    Offset(0.58, 0.12),   // 6ª Esfera: Média Direita
    Offset(-0.02, 0.65),  // 7ª Esfera: Inferior Central
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    // Centro e raio do corpo circular do radar (deslocado levemente para baixo para acomodar o botão)
    final center = Offset(w / 2, h * 0.54);
    final outerRadius = (w / 2) * 0.84;
    final innerBezelRadius = outerRadius * 0.88;
    final screenRadius = outerRadius * 0.76;

    // -------------------------------------------------------------------------
    // 1. Botão Superior (Dial / Stem de Cronômetro)
    // -------------------------------------------------------------------------
    _paintTopButton(canvas, size, center, outerRadius);

    // -------------------------------------------------------------------------
    // 2. Moldura Metálica Externa (Bezel)
    // -------------------------------------------------------------------------
    // Sombra projetada sutil
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawCircle(center.translate(0, 1.2), outerRadius, shadowPaint);

    // Borda preta exterior do gabinete
    final outerRimPaint = Paint()
      ..color = const Color(0xFF1B2328)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, w * 0.035);
    canvas.drawCircle(center, outerRadius, outerRimPaint);

    // Preenchimento metálico prateado chanfrado
    final bezelPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFECEFF1),
          Color(0xFFCFD8DC),
          Color(0xFF90A4AE),
          Color(0xFF546E7A),
        ],
        stops: [0.0, 0.25, 0.55, 0.85, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));
    canvas.drawCircle(center, outerRadius - (outerRimPaint.strokeWidth / 2), bezelPaint);

    // Borda escura interna de encaixe da tela
    final innerRimPaint = Paint()
      ..color = const Color(0xFF102015)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, w * 0.02);
    canvas.drawCircle(center, innerBezelRadius, innerRimPaint);

    // Marcações de calibração / pontos de registro no aro metálico (3h, 6h, 9h)
    _paintRegistrationDots(canvas, center, outerRadius, innerBezelRadius);

    // -------------------------------------------------------------------------
    // 3. Visor CRT/LCD Verde Esmeralda (Tela de Radar)
    // -------------------------------------------------------------------------
    final screenRect = Rect.fromCircle(center: center, radius: screenRadius);

    canvas.save();
    final screenClip = Path()..addOval(screenRect);
    canvas.clipPath(screenClip);

    // Fundo verde do radar com gradiente de emissão luminoso
    final screenBgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.1, -0.1),
        radius: 0.85,
        colors: const [
          Color(0xFF00E676), // Verde esmeralda brilhante
          Color(0xFF00C853), // Verde vivo de radar
          Color(0xFF009624), // Verde escuro de borda
          Color(0xFF00600F), // Profundidade do visor
        ],
        stops: const [0.0, 0.45, 0.85, 1.0],
      ).createShader(screenRect);
    canvas.drawCircle(center, screenRadius, screenBgPaint);

    // Grade ortogonal de coordenadas (Grid de telemetria)
    _paintRadarGrid(canvas, center, screenRadius);

    // -------------------------------------------------------------------------
    // 4. Cursor Central (Triângulo Vermelho & Mira Amarela)
    // -------------------------------------------------------------------------
    if (showCrosshair) {
      _paintCrosshair(canvas, center, screenRadius);
    }
    if (showCenterArrow) {
      _paintCenterArrow(canvas, center, screenRadius);
    }

    // -------------------------------------------------------------------------
    // 5. Esferas do Dragão Detectadas (Pontos Luminosos)
    // -------------------------------------------------------------------------
    _paintDetectedDots(canvas, center, screenRadius);

    // -------------------------------------------------------------------------
    // 6. Reflexo Especular da Lente de Vidro Curvo
    // -------------------------------------------------------------------------
    _paintGlassReflex(canvas, center, screenRadius);

    canvas.restore(); // Fecha o clip da tela
  }

  void _paintTopButton(Canvas canvas, Size size, Offset center, double outerRadius) {
    final w = size.width;
    final topCenter = Offset(center.dx, center.dy - outerRadius);

    // Haste de ligação (Pescoço do botão)
    final neckWidth = w * 0.16;
    final neckHeight = w * 0.08;
    final neckRect = Rect.fromCenter(
      center: Offset(topCenter.dx, topCenter.dy - (neckHeight * 0.4)),
      width: neckWidth,
      height: neckHeight,
    );
    final neckPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF78909C), Color(0xFFCFD8DC), Color(0xFF546E7A)],
      ).createShader(neckRect);
    canvas.drawRect(neckRect, neckPaint);

    // Cúpula superior (Dome / Dial arredondado)
    final domeWidth = w * 0.28;
    final domeHeight = w * 0.14;
    final domeRect = Rect.fromCenter(
      center: Offset(topCenter.dx, topCenter.dy - (neckHeight * 0.8) - (domeHeight * 0.35)),
      width: domeWidth,
      height: domeHeight,
    );
    final domeRRect = RRect.fromRectAndRadius(domeRect, Radius.circular(domeHeight * 0.5));

    final domePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFECEFF1),
          Color(0xFFB0BEC5),
          Color(0xFF78909C),
        ],
      ).createShader(domeRect);
    canvas.drawRRect(domeRRect, domePaint);

    // Contorno da cúpula
    final domeStrokePaint = Paint()
      ..color = const Color(0xFF263238)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, w * 0.025);
    canvas.drawRRect(domeRRect, domeStrokePaint);
  }

  void _paintRegistrationDots(Canvas canvas, Offset center, double outerRadius, double innerBezelRadius) {
    final dotRadius = math.max(0.8, (outerRadius - innerBezelRadius) * 0.22);
    final midRadius = (outerRadius + innerBezelRadius) / 2;

    final dotPaint = Paint()
      ..color = const Color(0xFF263238)
      ..style = PaintingStyle.fill;

    // Pontos laterais (3h e 9h)
    canvas.drawCircle(Offset(center.dx + midRadius, center.dy), dotRadius, dotPaint);
    canvas.drawCircle(Offset(center.dx - midRadius, center.dy), dotRadius, dotPaint);

    // Pontos inferiores (6h)
    canvas.drawCircle(Offset(center.dx - (dotRadius * 1.5), center.dy + midRadius), dotRadius * 0.9, dotPaint);
    canvas.drawCircle(Offset(center.dx + (dotRadius * 1.5), center.dy + midRadius), dotRadius * 0.9, dotPaint);
  }

  void _paintRadarGrid(Canvas canvas, Offset center, double radius) {
    final gridPaint = Paint()
      ..color = const Color(0xFF003D14).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.5, radius * 0.02);

    const int divisions = 6;
    final step = (radius * 2) / divisions;

    // Linhas verticais
    for (int i = 1; i < divisions; i++) {
      final x = (center.dx - radius) + (i * step);
      canvas.drawLine(
        Offset(x, center.dy - radius),
        Offset(x, center.dy + radius),
        gridPaint,
      );
    }

    // Linhas horizontais
    for (int i = 1; i < divisions; i++) {
      final y = (center.dy - radius) + (i * step);
      canvas.drawLine(
        Offset(center.dx - radius, y),
        Offset(center.dx + radius, y),
        gridPaint,
      );
    }
  }

  void _paintCrosshair(Canvas canvas, Offset center, double radius) {
    final crossPaint = Paint()
      ..color = const Color(0xFFFFEB3B).withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, radius * 0.035);

    final crosshairArm = radius * 0.38;
    final gap = radius * 0.08;

    // Braço horizontal
    canvas.drawLine(
      Offset(center.dx - crosshairArm, center.dy),
      Offset(center.dx - gap, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx + gap, center.dy),
      Offset(center.dx + crosshairArm, center.dy),
      crossPaint,
    );

    // Braço vertical
    canvas.drawLine(
      Offset(center.dx, center.dy - crosshairArm),
      Offset(center.dx, center.dy - gap),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + gap),
      Offset(center.dx, center.dy + crosshairArm),
      crossPaint,
    );
  }

  void _paintCenterArrow(Canvas canvas, Offset center, double radius) {
    final arrowSize = radius * 0.22;
    final arrowPath = Path();

    // Triângulo rubi clássico apontando para o topo (Norte)
    arrowPath.moveTo(center.dx, center.dy - arrowSize);
    arrowPath.lineTo(center.dx + (arrowSize * 0.75), center.dy + (arrowSize * 0.6));
    arrowPath.lineTo(center.dx, center.dy + (arrowSize * 0.3));
    arrowPath.lineTo(center.dx - (arrowSize * 0.75), center.dy + (arrowSize * 0.6));
    arrowPath.close();

    final arrowFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFF1744), Color(0xFFC62828)],
      ).createShader(Rect.fromCircle(center: center, radius: arrowSize));
    canvas.drawPath(arrowPath, arrowFill);

    final arrowBorder = Paint()
      ..color = const Color(0xFF4A0007)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.5, radius * 0.02);
    canvas.drawPath(arrowPath, arrowBorder);
  }

  void _paintDetectedDots(Canvas canvas, Offset center, double screenRadius) {
    final int effectiveDots = dots.clamp(0, 7);
    if (effectiveDots <= 0) return;

    final dotRadius = math.max(1.8, screenRadius * 0.11);

    for (int i = 0; i < effectiveDots; i++) {
      final posNorm = _dragonBallPositions[i];
      final dotCenter = Offset(
        center.dx + (posNorm.dx * screenRadius),
        center.dy + (posNorm.dy * screenRadius),
      );

      // 1. Halo / Brilho suave externo da esfera
      final glowPaint = Paint()
        ..color = const Color(0xFFFFC107).withValues(alpha: 0.45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, dotRadius * 1.2);
      canvas.drawCircle(dotCenter, dotRadius * 1.5, glowPaint);

      // 2. Núcleo dourado brilhante da Esfera do Dragão
      final dotFill = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.25),
          radius: 0.8,
          colors: const [
            Color(0xFFFFF9C4), // Brilho central claro
            Color(0xFFFFD54F), // Dourado âmbar Saiyajin
            Color(0xFFFF8F00), // Borda escura
          ],
        ).createShader(Rect.fromCircle(center: dotCenter, radius: dotRadius));
      canvas.drawCircle(dotCenter, dotRadius, dotFill);

      // 3. Contorno nítido sutil
      final dotStroke = Paint()
        ..color = const Color(0xFFBF360C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.4, dotRadius * 0.18);
      canvas.drawCircle(dotCenter, dotRadius, dotStroke);

      // 4. Ponto de reflexo central
      final coreDot = Paint()
        ..color = const Color(0xFFD84315)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dotCenter, dotRadius * 0.22, coreDot);
    }
  }

  void _paintGlassReflex(Canvas canvas, Offset center, double screenRadius) {
    final reflexRect = Rect.fromCircle(
      center: Offset(center.dx, center.dy - (screenRadius * 0.35)),
      radius: screenRadius * 0.9,
    );

    final reflexPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(reflexRect);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: screenRadius),
      math.pi * 1.15,
      math.pi * 0.7,
      true,
      reflexPaint,
    );
  }

  @override
  bool shouldRepaint(covariant DragonRadarPainter oldDelegate) {
    return oldDelegate.dots != dots ||
        oldDelegate.showCenterArrow != showCenterArrow ||
        oldDelegate.showCrosshair != showCrosshair;
  }
}
