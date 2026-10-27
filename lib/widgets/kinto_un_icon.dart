import 'package:flutter/material.dart';

/// Ícone vetorial da Nuvem Voadora (*Kinto-un* / Flying Nimbus) de Dragon Ball.
/// Representa leveza, fluidez neuromuscular e pureza de movimento para séries
/// de aquecimento (*Warm-up Sets*), sem gerar fadiga destrutiva nem poluir PRs.
class KintoUnIcon extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final bool showGlow;
  final bool showTrail;
  final VoidCallback? onTap;

  const KintoUnIcon({
    super.key,
    this.size = 24.0,
    this.primaryColor = const Color(0xFFFFD700),
    this.secondaryColor = const Color(0xFFFFA000),
    this.showGlow = true,
    this.showTrail = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Widget iconContent = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: KintoUnPainter(
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          showGlow: showGlow,
          showTrail: showTrail,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: iconContent,
      );
    }

    return iconContent;
  }
}

/// [CustomPainter] vetorial que desenha a Nuvem Voadora (*Kinto-un*) em estilo
/// cel-shaded com gradiente dourado suave, gomos volumosos e rastro aerodinâmico.
class KintoUnPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final bool showGlow;
  final bool showTrail;

  const KintoUnPainter({
    this.primaryColor = const Color(0xFFFFD700),
    this.secondaryColor = const Color(0xFFFFA000),
    this.showGlow = true,
    this.showTrail = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final rect = Offset.zero & size;

    // 1. Halo / Brilho suave de Ki dourado ao redor da nuvem
    if (showGlow) {
      final glowPaint = Paint()
        ..isAntiAlias = true
        ..shader = RadialGradient(
          center: const Alignment(0.12, 0.05),
          radius: 0.62,
          colors: [
            primaryColor.withValues(alpha: 0.32),
            secondaryColor.withValues(alpha: 0.12),
            Colors.transparent,
          ],
          stops: const [0.0, 0.65, 1.0],
        ).createShader(rect);
      canvas.drawCircle(Offset(w * 0.54, h * 0.52), w * 0.48, glowPaint);
    }

    // 2. Rastro aerodinâmico (cauda da Kinto-un à esquerda + pequenas nuvens soltas)
    if (showTrail) {
      final trailPath = Path()
        ..moveTo(w * 0.40, h * 0.46)
        ..cubicTo(w * 0.25, h * 0.43, w * 0.12, h * 0.40, w * 0.04, h * 0.34)
        ..cubicTo(w * 0.10, h * 0.50, w * 0.20, h * 0.60, w * 0.38, h * 0.64)
        ..close();

      final trailPaint = Paint()
        ..isAntiAlias = true
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            primaryColor.withValues(alpha: 0.20),
            primaryColor.withValues(alpha: 0.85),
            secondaryColor,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect);
      canvas.drawPath(trailPath, trailPaint);

      // Pequenas gotas/flocos dourados do rastro
      final wispPaint = Paint()
        ..isAntiAlias = true
        ..color = primaryColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(w * 0.11, h * 0.62), w * 0.042, wispPaint);
      canvas.drawCircle(Offset(w * 0.05, h * 0.52), w * 0.028, wispPaint);
    }

    // 3. Silhueta principal da Nuvem Kinto-un (gomos arredondados clássicos do anime)
    final cloudPath = Path()
      ..moveTo(w * 0.30, h * 0.67)
      // Gomo inferior esquerdo
      ..cubicTo(w * 0.17, h * 0.66, w * 0.16, h * 0.46, w * 0.29, h * 0.43)
      // Gomo superior esquerdo
      ..cubicTo(w * 0.28, h * 0.28, w * 0.45, h * 0.22, w * 0.55, h * 0.31)
      // Gomo superior central/direito (principal)
      ..cubicTo(w * 0.64, h * 0.18, w * 0.86, h * 0.24, w * 0.86, h * 0.42)
      // Gomo frontal direito
      ..cubicTo(w * 0.98, h * 0.45, w * 0.97, h * 0.67, w * 0.82, h * 0.69)
      // Gomo inferior central
      ..cubicTo(w * 0.74, h * 0.76, w * 0.58, h * 0.76, w * 0.51, h * 0.70)
      // Fechamento da base esquerda
      ..cubicTo(w * 0.44, h * 0.75, w * 0.35, h * 0.73, w * 0.30, h * 0.67)
      ..close();

    // Sombra base cel-shaded na parte inferior da nuvem
    final shadowPath = cloudPath.shift(Offset(0, h * 0.03));
    final dropShadowPaint = Paint()
      ..isAntiAlias = true
      ..color = secondaryColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawPath(shadowPath, dropShadowPaint);

    // Preenchimento principal com gradiente dourado luminoso
    final bodyPaint = Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(primaryColor, Colors.white, 0.45)!,
          primaryColor,
          secondaryColor,
        ],
        stops: const [0.0, 0.58, 1.0],
      ).createShader(rect);
    canvas.drawPath(cloudPath, bodyPaint);

    // 4. Brilho especular superior nos gomos da nuvem
    canvas.save();
    canvas.clipPath(cloudPath);
    final highlightPaint = Paint()
      ..isAntiAlias = true
      ..color = Colors.white.withValues(alpha: 0.42)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.71, h * 0.34), w * 0.13, highlightPaint);
    canvas.drawCircle(Offset(w * 0.44, h * 0.34), w * 0.09, highlightPaint);
    canvas.restore();

    // 5. Contorno externo e curvas internas características de nuvem de anime (Akira Toriyama)
    final strokeWidth = (w * 0.048).clamp(0.9, 2.4);
    final outlinePaint = Paint()
      ..isAntiAlias = true
      ..color = Color.lerp(secondaryColor, const Color(0xFFBF360C), 0.45)!
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth;

    canvas.drawPath(cloudPath, outlinePaint);

    // Espiral / curva interna de volume cel-shaded
    if (w >= 14) {
      final innerCurvePath = Path()
        ..moveTo(w * 0.54, h * 0.33)
        ..quadraticBezierTo(w * 0.60, h * 0.42, w * 0.53, h * 0.49)
        ..moveTo(w * 0.73, h * 0.56)
        ..quadraticBezierTo(w * 0.66, h * 0.63, w * 0.58, h * 0.57);

      final innerStrokePaint = Paint()
        ..isAntiAlias = true
        ..color = Color.lerp(secondaryColor, const Color(0xFFE65100), 0.35)!
            .withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = (strokeWidth * 0.85).clamp(0.8, 2.0);
      canvas.drawPath(innerCurvePath, innerStrokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant KintoUnPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.showGlow != showGlow ||
        oldDelegate.showTrail != showTrail;
  }
}
