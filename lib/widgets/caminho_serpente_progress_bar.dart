import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Barra de progresso tematica vetorial que reproduz o icônico
/// Caminho da Serpente de Dragon Ball Z (curvas de Bézier sobre nuvens amarelas).
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

    // Pontos-chave da curva em "S" com perspectiva
    // Início na Cauda (inferior esquerdo) -> Ondulação -> Cabeça/Planeta Kaioh (superior direito)
    final startX = 22.0;
    final startY = h - 14.0;
    final endX = w - 24.0;
    final endY = 14.0;

    final path = Path();
    path.moveTo(startX, startY);

    // Curva 1: sobe ondulando para a direita
    final p1x = w * 0.28;
    final p1y = h * 0.15;
    final c1x = w * 0.12;
    final c1y = h * 0.95;

    // Curva 2: desce suavemente no centro
    final p2x = w * 0.62;
    final p2y = h * 0.75;
    final c2x = w * 0.44;
    final c2y = h * -0.15;

    // Curva 3: sobe em direção ao Planeta Kaioh
    final c3x = w * 0.80;
    final c3y = h * 1.05;

    path.cubicTo(c1x, c1y, p1x, p1y, w * 0.35, h * 0.38);
    path.cubicTo(w * 0.45, h * 0.10, c2x, c2y, p2x, p2y);
    path.cubicTo(c3x, c3y, w * 0.88, h * 0.35, endX, endY);

    // 1. Nuvens Amarelas do Outro Mundo no fundo (fundo temático sutil)
    final cloudPaint = Paint()
      ..color = const Color(0xFFFFB300).withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(w * 0.25, h * 0.6), 18, cloudPaint);
    canvas.drawCircle(Offset(w * 0.55, h * 0.4), 22, cloudPaint);
    canvas.drawCircle(Offset(w * 0.82, h * 0.5), 18, cloudPaint);

    // 2. Sombra projetada do Caminho da Serpente
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..strokeWidth = 9.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.save();
    canvas.translate(0, 3.5);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // 3. Pista base do Caminho da Serpente (cinza-azulado com escamas)
    final baseRoadBorderPaint = Paint()
      ..color = const Color(0xFF1B2838)
      ..strokeWidth = 9.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, baseRoadBorderPaint);

    final baseRoadPaint = Paint()
      ..color = const Color(0xFF37474F)
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

        // Halo de brilho do Ki
        final glowPaint = Paint()
          ..color = AppColors.primary.withValues(alpha: 0.35)
          ..strokeWidth = 10.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawPath(activeSubPath, glowPaint);

        // Linha dourada ativa
        final activePaint = Paint()
          ..shader = ui.Gradient.linear(
            Offset(startX, startY),
            Offset(endX, endY),
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

      // 5. Marcador do Guerreiro / Ponto de Ki atual
      final tangent = metric.getTangentForOffset(currentLen);
      if (tangent != null) {
        final warriorPos = tangent.position;

        // Aura de Ki externa
        final auraPaint = Paint()
          ..color = const Color(0xFFFF9800).withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        canvas.drawCircle(warriorPos, 7.5, auraPaint);

        // Núcleo do guerreiro (brilho branco-dourado)
        final markerBorder = Paint()..color = const Color(0xFF1E1E1E);
        canvas.drawCircle(warriorPos, 5.0, markerBorder);

        final markerCore = Paint()..color = const Color(0xFFFFD54F);
        canvas.drawCircle(warriorPos, 3.5, markerCore);

        final centerWhite = Paint()..color = Colors.white;
        canvas.drawCircle(warriorPos, 1.5, centerWhite);
      }
    }

    // 6. Início da Jornada: Cauda da Serpente
    final tailPaint = Paint()..color = const Color(0xFFFF9800);
    canvas.drawCircle(Offset(startX, startY), 3.5, tailPaint);

    // 7. Destino Final: Planeta do Sr. Kaioh (Mini esfera verde com anel e casinha)
    final planetCenter = Offset(endX + 6, endY - 2);

    // Aura celestial do planeta
    final planetGlow = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(planetCenter, 9.0, planetGlow);

    // Esfera do Planeta Kaioh (gramado verde característico)
    final planetPaint = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawCircle(planetCenter, 7.0, planetPaint);

    final planetBorder = Paint()
      ..color = const Color(0xFF81C784)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(planetCenter, 7.0, planetBorder);

    // Casinha vermelha clássica do Sr. Kaioh no topo do planeta
    final housePaint = Paint()..color = const Color(0xFFD32F2F);
    final houseRect = Rect.fromCenter(
      center: Offset(planetCenter.dx, planetCenter.dy - 6.5),
      width: 4.5,
      height: 3.5,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(houseRect, const Radius.circular(1)), housePaint);
  }

  @override
  bool shouldRepaint(covariant _CaminhoSerpentePainter oldDelegate) {
    return (oldDelegate.progresso - progresso).abs() > 0.001;
  }
}
