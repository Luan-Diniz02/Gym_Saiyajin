import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Ícone vetorial estilizado do Scouter clássico de Dragon Ball, desenhado nativamente via CustomPainter.
class ScouterIcon extends StatelessWidget {
  final double size;
  final Color? lensColor;
  final Color? bodyColor;
  final bool showHud;

  const ScouterIcon({
    super.key,
    this.size = 24,
    this.lensColor,
    this.bodyColor,
    this.showHud = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLensColor = lensColor ?? const Color(0xFF00E676);
    final effectiveBodyColor = bodyColor ?? const Color(0xFFECEFF1);

    return SizedBox(
      width: size * 1.25,
      height: size,
      child: CustomPaint(
        painter: _ScouterPainter(
          lensColor: effectiveLensColor,
          bodyColor: effectiveBodyColor,
          showHud: showHud,
        ),
      ),
    );
  }
}

class _ScouterPainter extends CustomPainter {
  final Color lensColor;
  final Color bodyColor;
  final bool showHud;

  _ScouterPainter({
    required this.lensColor,
    required this.bodyColor,
    required this.showHud,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Proporções normalizadas:
    // A lente fica à esquerda (0.0 a 0.65 do width)
    // O encaixe auricular fica à direita (0.65 a 1.0 do width)

    // 1. Base auricular (Ear cup) no lado direito
    final earRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.72, h * 0.15, w * 0.25, h * 0.70),
      Radius.circular(w * 0.08),
    );

    final earPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(earRect, earPaint);

    // Borda escura suave na base auricular
    final earBorderPaint = Paint()
      ..color = AppColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.03).clamp(1.0, 2.0);
    canvas.drawRRect(earRect, earBorderPaint);

    // Indicador LED vermelho de energia no auricular
    final ledRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.77, h * 0.40, w * 0.10, h * 0.20),
      Radius.circular(w * 0.03),
    );
    final ledPaint = Paint()
      ..color = const Color(0xFFFF3D00)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(ledRect, ledPaint);

    // 2. Haste de conexão metálica entre a base e a lente
    final armPath = Path()
      ..moveTo(w * 0.58, h * 0.32)
      ..lineTo(w * 0.75, h * 0.35)
      ..lineTo(w * 0.75, h * 0.55)
      ..lineTo(w * 0.58, h * 0.58)
      ..close();

    final armPaint = Paint()
      ..color = bodyColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawPath(armPath, armPaint);

    // 3. Lente holográfica translúcida (Visor)
    // Formato poligonal icônico de Dragon Ball:
    // Topo reto, canto superior esquerdo chanfrado, lateral esquerda vertical,
    // canto inferior esquerdo chanfrado, base com degrau e união à haste.
    final lensPath = Path()
      ..moveTo(w * 0.12, h * 0.22) // Topo esquerdo
      ..lineTo(w * 0.62, h * 0.22) // Topo direito (junto à haste)
      ..lineTo(w * 0.60, h * 0.75) // Fundo direito
      ..lineTo(w * 0.25, h * 0.85) // Canto inferior chanfrado
      ..lineTo(w * 0.05, h * 0.65) // Canto lateral inferior
      ..lineTo(w * 0.05, h * 0.35) // Lateral esquerda
      ..close();

    // Preenchimento translúcido com brilho
    final lensFillPaint = Paint()
      ..color = lensColor.withValues(alpha: 0.30)
      ..style = PaintingStyle.fill;
    canvas.drawPath(lensPath, lensFillPaint);

    // Contorno neon brilhante da lente
    final lensBorderPaint = Paint()
      ..color = lensColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.04).clamp(1.2, 2.5)
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(lensPath, lensBorderPaint);

    // 4. Elementos HUD internos holográficos (Retículo de mira)
    if (showHud && w >= 18) {
      final hudPaint = Paint()
        ..color = lensColor.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (w * 0.02).clamp(0.8, 1.2);

      final centerHud = Offset(w * 0.32, h * 0.50);
      final radiusHud = w * 0.12;

      // Círculo central de mira
      canvas.drawCircle(centerHud, radiusHud, hudPaint);

      // Ponto focal central
      final pointPaint = Paint()
        ..color = lensColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(centerHud, (w * 0.025).clamp(1.0, 1.8), pointPaint);

      // Cruz de mira sutil
      canvas.drawLine(
        Offset(centerHud.dx - radiusHud * 1.3, centerHud.dy),
        Offset(centerHud.dx + radiusHud * 1.3, centerHud.dy),
        hudPaint,
      );
      canvas.drawLine(
        Offset(centerHud.dx, centerHud.dy - radiusHud * 1.3),
        Offset(centerHud.dx, centerHud.dy + radiusHud * 1.3),
        hudPaint,
      );

      // Tracinhos digitais de leitura de poder no canto inferior do visor
      if (w >= 28) {
        final dashPaint = Paint()
          ..color = lensColor.withValues(alpha: 0.85)
          ..style = PaintingStyle.fill;

        for (int i = 0; i < 4; i++) {
          final dashRect = Rect.fromLTWH(
            w * 0.20 + (i * w * 0.06),
            h * 0.72,
            w * 0.035,
            h * 0.04,
          );
          canvas.drawRect(dashRect, dashPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ScouterPainter oldDelegate) {
    return oldDelegate.lensColor != lensColor ||
        oldDelegate.bodyColor != bodyColor ||
        oldDelegate.showHud != showHud;
  }
}
