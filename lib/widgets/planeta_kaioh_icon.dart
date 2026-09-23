import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Ícone vetorial cel-shaded em alta fidelidade do Planeta do Senhor Kaioh (界王星)
/// de Dragon Ball Z.
/// 
/// Desenha o minúsculo planeta esférico verde de alta gravidade com:
/// - Gradiente esférico verde cel-shaded com relevo 3D
/// - Pista circular pavimentada em arco atravessando o planeta
/// - Casa e cúpula icônica do Sr. Kaioh com teto arredondado e anexo
/// - Clássico carro conversível vintage vermelho estacionado na pista
/// - Bosques de árvores arredondadas ao redor da curvatura do planeta
/// - Brilho atmosférico sutil
class PlanetaKaiohIcon extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const PlanetaKaiohIcon({
    super.key,
    this.size = 36.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget icon = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: PlanetaKaiohPainter(),
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

/// [CustomPainter] de alto desempenho para renderizar o Planeta do Sr. Kaioh.
class PlanetaKaiohPainter extends CustomPainter {
  const PlanetaKaiohPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final minDim = math.min(w, h);
    if (minDim <= 0) return;

    final center = Offset(w / 2, h / 2 + minDim * 0.04);
    final planetRadius = minDim * 0.38;

    // 1. Atmosfera e Aura esférica sutil
    final auraPaint = Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFF76D22A).withValues(alpha: 0.22)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, minDim * 0.08);
    canvas.drawCircle(center, planetRadius * 1.08, auraPaint);

    // 2. Árvores de fundo (que extrapolam a silhueta da esfera)
    _desenharArvoresSilhueta(canvas, center, planetRadius, minDim);

    // 3. Esfera Principal do Planeta (Grama e Relevo esférico)
    final sphereRect = Rect.fromCircle(center: center, radius: planetRadius);
    final spherePaint = Paint()
      ..isAntiAlias = true
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.32),
        radius: 0.95,
        colors: const [
          Color(0xFFACF14A), // Verde limão ensolarado
          Color(0xFF78D124), // Verde grama vivo
          Color(0xFF52A714), // Verde floresta médio
          Color(0xFF28630A), // Verde sombra profunda da base
        ],
        stops: const [0.0, 0.40, 0.75, 1.0],
      ).createShader(sphereRect);
    canvas.drawCircle(center, planetRadius, spherePaint);

    // Sombra de oclusão esférica inferior direita
    final shadowPaint = Paint()
      ..isAntiAlias = true
      ..shader = RadialGradient(
        center: const Alignment(0.45, 0.55),
        radius: 0.85,
        colors: [
          const Color(0xFF133804).withValues(alpha: 0.45),
          Colors.transparent,
        ],
        stops: const [0.0, 0.8],
      ).createShader(sphereRect);
    canvas.drawCircle(center, planetRadius, shadowPaint);

    // Clip para os elementos internos que acompanham a curvatura esférica
    canvas.save();
    final sphereClip = Path()..addOval(sphereRect);
    canvas.clipPath(sphereClip);

    // 4. Estrada / Pista circular pavimentada que cruza o planeta
    _desenharEstrada(canvas, center, planetRadius, minDim);

    // 5. Carro clássico vermelho vintage na pista
    _desenharCarroVermelho(canvas, center, planetRadius, minDim);

    // 6. Árvores internas em primeiro plano
    _desenharArvoresInternas(canvas, center, planetRadius, minDim);

    canvas.restore(); // Fecha o clip da esfera

    // 7. Casa e Anexo do Sr. Kaioh (desenhadas no polo superior do planeta)
    _desenharCasaSrKaioh(canvas, center, planetRadius, minDim);

    // 8. Brilho especular celestial no topo-esquerdo da esfera
    final highlightPaint = Paint()
      ..isAntiAlias = true
      ..color = Colors.white.withValues(alpha: 0.28)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, minDim * 0.04);
    final highlightCenter = Offset(center.dx - planetRadius * 0.35, center.dy - planetRadius * 0.38);
    canvas.drawOval(
      Rect.fromCenter(center: highlightCenter, width: planetRadius * 0.55, height: planetRadius * 0.30),
      highlightPaint,
    );
  }

  void _desenharEstrada(Canvas canvas, Offset center, double r, double minDim) {
    // Pista pavimentada branca/cinza claro em curva suave atravessando o planeta
    final pStartLeft = Offset(center.dx - r * 0.98, center.dy - r * 0.18);
    final pEndRight = Offset(center.dx + r * 0.98, center.dy + r * 0.48);
    final pCtrl1 = Offset(center.dx - r * 0.30, center.dy - r * 0.42);
    final pCtrl2 = Offset(center.dx + r * 0.35, center.dy - r * 0.05);

    final roadThickness = minDim * 0.085;

    // Base asfáltica com borda de guia
    final roadBorderPaint = Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFF90A4AE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = roadThickness + 1.2
      ..strokeCap = StrokeCap.butt;

    final roadPaint = Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFFF1F5F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = roadThickness
      ..strokeCap = StrokeCap.butt;

    final roadPath = Path()
      ..moveTo(pStartLeft.dx, pStartLeft.dy)
      ..cubicTo(pCtrl1.dx, pCtrl1.dy, pCtrl2.dx, pCtrl2.dy, pEndRight.dx, pEndRight.dy);

    canvas.drawPath(roadPath, roadBorderPaint);
    canvas.drawPath(roadPath, roadPaint);
  }

  void _desenharCarroVermelho(Canvas canvas, Offset center, double r, double minDim) {
    // Posição do clássico carro conversível vermelho do Sr. Kaioh sobre a estrada
    final carPos = Offset(center.dx - r * 0.35, center.dy - r * 0.34);
    final carW = minDim * 0.14;
    final carH = minDim * 0.08;

    canvas.save();
    canvas.translate(carPos.dx, carPos.dy);
    canvas.rotate(0.25); // Inclinado na tangente da curva

    // Sombra do carro
    final carShadow = Paint()
      ..color = const Color(0xFF37474F).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, carH * 0.45), width: carW * 1.05, height: carH * 0.4),
      carShadow,
    );

    // Carroceria vermelha esportiva
    final bodyPaint = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.fill;
    final carBody = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: carW, height: carH * 0.75),
      Radius.circular(carH * 0.3),
    );
    canvas.drawRRect(carBody, bodyPaint);

    // Cabine / Parabrisa branco
    final cabinPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(carW * 0.08, -carH * 0.05), width: carW * 0.45, height: carH * 0.45),
      cabinPaint,
    );

    // Interior / Volante detalhe escuro
    final seatPaint = Paint()..color = const Color(0xFF263238);
    canvas.drawCircle(Offset(carW * 0.08, -carH * 0.05), carH * 0.15, seatPaint);

    // Rodas pretas
    final wheelPaint = Paint()..color = const Color(0xFF1E272C);
    canvas.drawCircle(Offset(-carW * 0.35, carH * 0.32), carH * 0.22, wheelPaint);
    canvas.drawCircle(Offset(carW * 0.35, carH * 0.32), carH * 0.22, wheelPaint);

    canvas.restore();
  }

  void _desenharCasaSrKaioh(Canvas canvas, Offset center, double r, double minDim) {
    // A casa do Sr. Kaioh é composta pelo domo bege e a garagem/anexo arredondado
    final houseCenter = Offset(center.dx - r * 0.38, center.dy - r * 0.88);
    final scale = minDim * 0.01;

    canvas.save();
    canvas.translate(houseCenter.dx, houseCenter.dy);
    canvas.rotate(-0.25); // Acompanha a curvatura superior esquerda

    // 1. Anexo / Garagem marrom ao lado
    final garageRect = Rect.fromLTWH(scale * 12, scale * 3, scale * 16, scale * 12);
    final garagePaint = Paint()
      ..color = const Color(0xFFD48B47)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(garageRect, Radius.circular(scale * 4)), garagePaint);

    // Portão do anexo
    final garageDoorPaint = Paint()..color = const Color(0xFF4E342E);
    canvas.drawRect(Rect.fromLTWH(scale * 16, scale * 6, scale * 8, scale * 9), garageDoorPaint);

    // 2. Casa principal (Domo bege/amarelo)
    final domePaint = Paint()
      ..color = const Color(0xFFF3D99C)
      ..style = PaintingStyle.fill;
    final domeBorderPaint = Paint()
      ..color = const Color(0xFFB58E55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final domePath = Path()
      ..moveTo(-scale * 10, scale * 14)
      ..quadraticBezierTo(-scale * 12, -scale * 2, 0, -scale * 6)
      ..quadraticBezierTo(scale * 12, -scale * 2, scale * 10, scale * 14)
      ..close();
    canvas.drawPath(domePath, domePaint);
    canvas.drawPath(domePath, domeBorderPaint);

    // Telhado / Faixa superior marrom
    final roofCapPaint = Paint()..color = const Color(0xFFC76B24);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(0, -scale * 1), width: scale * 14, height: scale * 8),
      math.pi,
      math.pi,
      true,
      roofCapPaint,
    );

    // Anteninha / Torre do topo
    final spirePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(0, -scale * 7.5), scale * 1.5, spirePaint);

    // Porta em arco
    final doorPaint = Paint()..color = const Color(0xFF4A2A18);
    final doorPath = Path()
      ..moveTo(-scale * 3.5, scale * 14)
      ..lineTo(-scale * 3.5, scale * 7)
      ..quadraticBezierTo(0, scale * 4.5, scale * 3.5, scale * 7)
      ..lineTo(scale * 3.5, scale * 14)
      ..close();
    canvas.drawPath(doorPath, doorPaint);

    canvas.restore();
  }

  void _desenharArvoresSilhueta(Canvas canvas, Offset center, double r, double minDim) {
    // Árvores que brotam nas bordas e criam o contorno do planeta
    final treeDark = const Color(0xFF1E5E14);
    final treeLight = const Color(0xFF388E24);

    // Grupo superior esquerdo (ao lado da casa)
    _desenharPuffArvore(canvas, Offset(center.dx - r * 0.75, center.dy - r * 0.65), minDim * 0.12, treeDark, treeLight);
    _desenharPuffArvore(canvas, Offset(center.dx - r * 0.62, center.dy - r * 0.78), minDim * 0.14, treeDark, treeLight);

    // Grupo superior direito
    _desenharPuffArvore(canvas, Offset(center.dx + r * 0.40, center.dy - r * 0.88), minDim * 0.12, treeDark, treeLight);
    _desenharPuffArvore(canvas, Offset(center.dx + r * 0.55, center.dy - r * 0.75), minDim * 0.14, treeDark, treeLight);

    // Grupo lateral esquerdo
    _desenharPuffArvore(canvas, Offset(center.dx - r * 0.95, center.dy + r * 0.25), minDim * 0.11, treeDark, treeLight);

    // Grupo inferior (no polo sul)
    _desenharPuffArvore(canvas, Offset(center.dx + r * 0.15, center.dy + r * 0.92), minDim * 0.13, treeDark, treeLight);
  }

  void _desenharArvoresInternas(Canvas canvas, Offset center, double r, double minDim) {
    final treeDark = const Color(0xFF1B5312);
    final treeLight = const Color(0xFF3B9426);

    // Árvores menores no hemisfério sul interno
    _desenharPuffArvore(canvas, Offset(center.dx + r * 0.35, center.dy + r * 0.70), minDim * 0.15, treeDark, treeLight);
    _desenharPuffArvore(canvas, Offset(center.dx - r * 0.50, center.dy + r * 0.35), minDim * 0.10, treeDark, treeLight);
  }

  void _desenharPuffArvore(Canvas canvas, Offset pos, double radius, Color cDark, Color cLight) {
    final trunkPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = radius * 0.25
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pos, Offset(pos.dx, pos.dy + radius * 0.4), trunkPaint);

    final pDark = Paint()..color = cDark;
    final pLight = Paint()..color = cLight;

    // Camadas de copa puffy
    canvas.drawCircle(Offset(pos.dx, pos.dy), radius * 0.75, pDark);
    canvas.drawCircle(Offset(pos.dx - radius * 0.28, pos.dy + radius * 0.1), radius * 0.55, pDark);
    canvas.drawCircle(Offset(pos.dx + radius * 0.28, pos.dy + radius * 0.1), radius * 0.55, pDark);

    // Highlights cel-shaded da folhagem
    canvas.drawCircle(Offset(pos.dx - radius * 0.12, pos.dy - radius * 0.2), radius * 0.45, pLight);
    canvas.drawCircle(Offset(pos.dx + radius * 0.18, pos.dy - radius * 0.15), radius * 0.35, pLight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
