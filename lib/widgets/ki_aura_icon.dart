import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Ícone vetorial estilizado em alta fidelidade da **Aura de Ki Saiyajin** (気) de Dragon Ball Z.
/// 
/// Desenha a silhueta de labareda canônica ascendente e pontiaguda de energia Saiyajin:
/// - Aura difusa externa (*Glow*) para sensação de irradiação de poder.
/// - Casca de chama externa com labaredas afiadas voltadas para cima (*upward energy tongues*).
/// - Núcleo interno de alta densidade energética (*Inner Core*).
/// - Micro-centelhas e relâmpagos/sparks de Ki flutuantes nas laterais (*Sparks*).
class KiAuraIcon extends StatelessWidget {
  /// Tamanho do ícone (largura e altura proporcionais).
  final double size;

  /// Cor principal da chama (padrão: Ouro Super Saiyajin `#FFD700`).
  final Color? primaryColor;

  /// Cor secundária da base e contorno da chama (padrão: Laranja Âmbar `#FF8C00`).
  final Color? secondaryColor;

  /// Cor do núcleo de condensação de energia (padrão: Branco Amarelado `#FFFDE7`).
  final Color? coreColor;

  /// Se deve exibir o brilho difuso (*glow*) de energia atrás da chama.
  final bool showGlow;

  /// Se deve exibir as microcentelhas/faíscas de energia ao redor.
  final bool showSparks;

  /// Se deve exibir o núcleo superdenso no interior da chama.
  final bool showCore;

  /// Ação opcional ao tocar no ícone.
  final VoidCallback? onTap;

  const KiAuraIcon({
    super.key,
    this.size = 24.0,
    this.primaryColor,
    this.secondaryColor,
    this.coreColor,
    this.showGlow = true,
    this.showSparks = true,
    this.showCore = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePrimary = primaryColor ?? const Color(0xFFFFD700);
    final effectiveSecondary = secondaryColor ?? const Color(0xFFFF8C00);
    final effectiveCore = coreColor ?? const Color(0xFFFFFDE7);

    Widget icon = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: KiAuraPainter(
          primaryColor: effectivePrimary,
          secondaryColor: effectiveSecondary,
          coreColor: effectiveCore,
          showGlow: showGlow,
          showSparks: showSparks,
          showCore: showCore,
        ),
      ),
    );

    if (onTap != null) {
      icon = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: icon,
      );
    }

    return icon;
  }
}

/// [CustomPainter] de alto desempenho para desenhar a chama e aura de Ki Saiyajin.
class KiAuraPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color coreColor;
  final bool showGlow;
  final bool showSparks;
  final bool showCore;

  const KiAuraPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.coreColor,
    this.showGlow = true,
    this.showSparks = true,
    this.showCore = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final flameRect = Rect.fromLTWH(0, 0, w, h);

    // 1. Aura Difusa Externa (Glow)
    if (showGlow) {
      final glowPath = _gerarPathChamaPrincipal(w, h, escala: 1.08, offsetY: h * 0.01);
      final glowPaint = Paint()
        ..isAntiAlias = true
        ..color = primaryColor.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(1.8, w * 0.12));
      canvas.drawPath(glowPath, glowPaint);
    }

    // 2. Chama Base Externa (Gradiente Vertical de Energia)
    final mainPath = _gerarPathChamaPrincipal(w, h);
    final mainPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor,
          Color.lerp(primaryColor, secondaryColor, 0.45)!,
          secondaryColor,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(flameRect);
    canvas.drawPath(mainPath, mainPaint);

    // Borda sutil de destaque no contorno externo
    final outlinePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, w * 0.032)
      ..color = primaryColor.withValues(alpha: 0.65);
    canvas.drawPath(mainPath, outlinePaint);

    // 3. Núcleo Interno de Alta Densidade (Inner Core)
    if (showCore) {
      final corePath = _gerarPathNucleo(w, h);
      final corePaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            coreColor,
            Color.lerp(coreColor, primaryColor, 0.60)!,
            primaryColor.withValues(alpha: 0.90),
          ],
          stops: const [0.0, 0.60, 1.0],
        ).createShader(flameRect);
      canvas.drawPath(corePath, corePaint);
    }

    // 4. Centelhas / Faíscas de Ki (Sparks)
    if (showSparks) {
      _desenharSparks(canvas, w, h);
    }
  }

  /// Gera a silhueta principal da chama de Ki com línguas de fogo ascendentes e pontiagudas.
  Path _gerarPathChamaPrincipal(double w, double h, {double escala = 1.0, double offsetY = 0.0}) {
    final cx = w * 0.5;
    final cy = h * 0.52 + offsetY;

    double px(double relX) => cx + (relX - 0.5) * w * escala;
    double py(double relY) => cy + (relY - 0.52) * h * escala;

    final path = Path();

    // Início na base inferior central
    path.moveTo(px(0.50), py(0.95));

    // LADO ESQUERDO (subindo com línguas de fogo voltadas para cima)
    // Base até início da primeira labareda
    path.cubicTo(px(0.40), py(0.95), px(0.28), py(0.91), px(0.23), py(0.82));
    // 1. Labareda inferior esquerda: sobe até a ponta afiada voltada para cima
    path.cubicTo(px(0.18), py(0.74), px(0.15), py(0.66), px(0.14), py(0.57));
    // Fenda/reentrância que mergulha para a base da próxima labareda
    path.cubicTo(px(0.19), py(0.62), px(0.24), py(0.65), px(0.25), py(0.64));

    // 2. Labareda média esquerda: sobe esguia e pontiaguda para cima/fora
    path.cubicTo(px(0.22), py(0.52), px(0.21), py(0.42), px(0.23), py(0.33));
    // Fenda média
    path.cubicTo(px(0.29), py(0.39), px(0.33), py(0.42), px(0.34), py(0.40));

    // 3. Labareda superior esquerda: sobe em direção ao cume
    path.cubicTo(px(0.34), py(0.30), px(0.37), py(0.22), px(0.40), py(0.17));
    // Fenda superior
    path.cubicTo(px(0.43), py(0.22), px(0.45), py(0.23), px(0.46), py(0.20));

    // 4. Labareda Central Principal (o pico mais alto da aura de Ki)
    path.cubicTo(px(0.47), py(0.13), px(0.48), py(0.07), px(0.50), py(0.03));

    // LADO DIREITO (descendo de volta à base com assimetria dinâmica de chamas)
    path.cubicTo(px(0.52), py(0.07), px(0.53), py(0.13), px(0.54), py(0.20));
    // Fenda superior direita
    path.cubicTo(px(0.55), py(0.23), px(0.57), py(0.22), px(0.60), py(0.17));

    // 3. Labareda superior direita: ponta voltada para cima
    path.cubicTo(px(0.63), py(0.22), px(0.66), py(0.30), px(0.66), py(0.40));
    // Fenda média direita
    path.cubicTo(px(0.67), py(0.42), px(0.71), py(0.39), px(0.77), py(0.33));

    // 2. Labareda média direita
    path.cubicTo(px(0.79), py(0.42), px(0.78), py(0.52), px(0.75), py(0.64));
    // Fenda inferior direita
    path.cubicTo(px(0.76), py(0.65), px(0.81), py(0.62), px(0.86), py(0.57));

    // 1. Labareda inferior direita
    path.cubicTo(px(0.85), py(0.66), px(0.82), py(0.74), px(0.77), py(0.82));

    // Volta para a base inferior
    path.cubicTo(px(0.72), py(0.91), px(0.60), py(0.95), px(0.50), py(0.95));

    path.close();
    return path;
  }

  /// Gera a silhueta do núcleo interno de energia condensada.
  Path _gerarPathNucleo(double w, double h) {
    final cx = w * 0.5;
    final cy = h * 0.58;

    double px(double relX) => cx + (relX - 0.5) * w * 0.52;
    double py(double relY) => cy + (relY - 0.58) * h * 0.58;

    final path = Path();
    path.moveTo(px(0.50), py(0.94));

    // Lado esquerdo do núcleo
    path.cubicTo(px(0.36), py(0.94), px(0.26), py(0.88), px(0.25), py(0.72));
    path.cubicTo(px(0.28), py(0.74), px(0.32), py(0.75), px(0.35), py(0.71));
    path.cubicTo(px(0.32), py(0.55), px(0.36), py(0.42), px(0.42), py(0.34));
    path.cubicTo(px(0.45), py(0.38), px(0.47), py(0.38), px(0.48), py(0.32));

    // Pico do núcleo
    path.cubicTo(px(0.49), py(0.26), px(0.50), py(0.20), px(0.50), py(0.18));

    // Lado direito do núcleo
    path.cubicTo(px(0.50), py(0.20), px(0.51), py(0.26), px(0.52), py(0.32));
    path.cubicTo(px(0.53), py(0.38), px(0.55), py(0.38), px(0.58), py(0.34));
    path.cubicTo(px(0.64), py(0.42), px(0.68), py(0.55), px(0.65), py(0.71));
    path.cubicTo(px(0.68), py(0.75), px(0.72), py(0.74), px(0.75), py(0.72));
    path.cubicTo(px(0.74), py(0.88), px(0.64), py(0.94), px(0.50), py(0.94));

    path.close();
    return path;
  }

  /// Desenha faíscas/centelhas pontiagudas ascendentes características do Ki Saiyajin.
  void _desenharSparks(Canvas canvas, double w, double h) {
    final sparkPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = primaryColor.withValues(alpha: 0.90);

    final sparkCorePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = coreColor.withValues(alpha: 0.95);

    // Centelhas pontiagudas flutuantes (losangos esguios verticais)
    // 1. Esquerda alta
    _desenharCentelhaLosango(canvas, Offset(w * 0.18, h * 0.28), w * 0.038, h * 0.08, sparkPaint, sparkCorePaint);

    // 2. Direita alta
    _desenharCentelhaLosango(canvas, Offset(w * 0.82, h * 0.24), w * 0.035, h * 0.075, sparkPaint, sparkCorePaint);

    // 3. Direita baixa
    _desenharCentelhaLosango(canvas, Offset(w * 0.90, h * 0.62), w * 0.032, h * 0.065, sparkPaint, sparkCorePaint);

    // 4. Esquerda baixa
    _desenharCentelhaLosango(canvas, Offset(w * 0.09, h * 0.66), w * 0.032, h * 0.062, sparkPaint, sparkCorePaint);
  }

  void _desenharCentelhaLosango(
    Canvas canvas,
    Offset centro,
    double raioX,
    double raioY,
    Paint glowPaint,
    Paint corePaint,
  ) {
    final path = Path()
      ..moveTo(centro.dx, centro.dy - raioY)
      ..lineTo(centro.dx + raioX, centro.dy)
      ..lineTo(centro.dx, centro.dy + raioY)
      ..lineTo(centro.dx - raioX, centro.dy)
      ..close();

    canvas.drawPath(path, glowPaint);

    // Núcleo mais brilhante
    final corePath = Path()
      ..moveTo(centro.dx, centro.dy - raioY * 0.5)
      ..lineTo(centro.dx + raioX * 0.5, centro.dy)
      ..lineTo(centro.dx, centro.dy + raioY * 0.5)
      ..lineTo(centro.dx - raioX * 0.5, centro.dy)
      ..close();
    canvas.drawPath(corePath, corePaint);
  }

  @override
  bool shouldRepaint(covariant KiAuraPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.coreColor != coreColor ||
        oldDelegate.showGlow != showGlow ||
        oldDelegate.showSparks != showSparks ||
        oldDelegate.showCore != showCore;
  }
}
