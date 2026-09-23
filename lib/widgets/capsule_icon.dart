import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Ícone vetorial canônico da Cápsula Hoi-Poi da Capsule Corp de Dragon Ball.
///
/// Desenvolvido sob medida com CustomPainter para renderizar a geometria completa:
/// - Botão de acionamento metálico no topo (push trigger com haste e anel)
/// - Cúpula superior e inferior arredondadas (branco perolado com reflexo especular)
/// - Faixas coloridas vibrantes (com suporte a cores clássicas da Capsule Corp)
/// - Faixa central escura com o logotipo circular estendido da Capsule Corp (C concêntrico)
/// - Brilho de reflexo curvo de vidro/plástico de alta tecnologia
class CapsuleIcon extends StatelessWidget {
  /// Diâmetro / tamanho da caixa delimitadora do ícone.
  final double size;

  /// Cor principal das faixas da cápsula. Padrão: Azul Capsule Corp (#00A3FF).
  final Color color;

  /// Ângulo de inclinação em graus. Padrão: 35 graus (isometria canônica de Dragon Ball).
  final double angleDegrees;

  const CapsuleIcon({
    super.key,
    this.size = 32.0,
    this.color = const Color(0xFF00A3FF),
    this.angleDegrees = 35.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: CapsulePainter(
          color: color,
          angleDegrees: angleDegrees,
        ),
      ),
    );
  }
}

class CapsulePainter extends CustomPainter {
  final Color color;
  final double angleDegrees;

  const CapsulePainter({
    required this.color,
    this.angleDegrees = 35.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double s = math.min(size.width, size.height);
    final Offset center = Offset(size.width / 2, size.height / 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angleDegrees * math.pi / 180.0);

    // Proporções da cápsula no sistema de coordenadas local (-H/2 a +H/2)
    // Largura da cápsula ~ 0.36 * s, Altura do corpo ~ 0.72 * s
    final double capW = s * 0.36;
    final double capH = s * 0.70;
    final double radius = capW / 2.0;
    final double halfH = capH / 2.0;

    // 1. Sombra projetada suave abaixo da cápsula
    final Path shadowPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(s * 0.04, s * 0.04),
            width: capW,
            height: capH,
          ),
          Radius.circular(radius),
        ),
      );
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    // 2. Botão superior de clique (Push Trigger)
    _drawTopButton(canvas, capW, halfH, s);

    // 3. Contorno e clipe do corpo da cápsula
    final Rect bodyRect = Rect.fromCenter(
      center: Offset.zero,
      width: capW,
      height: capH,
    );
    final RRect bodyRRect = RRect.fromRectAndRadius(bodyRect, Radius.circular(radius));

    canvas.save();
    canvas.clipRRect(bodyRRect);

    // 4. Desenho das faixas da cápsula
    _drawBodyBands(canvas, capW, capH, halfH, radius);

    // 5. Logo Capsule Corp na faixa central escura
    _drawCapsuleCorpLogo(canvas, capW, s);

    // 6. Reflexo especular 3D de luz (gradiente curvo longitudinal)
    _draw3DSpecularHighlight(canvas, bodyRect, radius);

    canvas.restore(); // remove clip

    // 7. Borda externa / Linha de junção técnica
    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, s * 0.035)
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.9);
    canvas.drawRRect(bodyRRect, strokePaint);

    canvas.restore(); // remove rotation & translation
  }

  /// Desenha o botão de acionamento no topo da cápsula (haste e botão de pressão)
  void _drawTopButton(Canvas canvas, double capW, double halfH, double s) {
    final double stemW = capW * 0.32;
    final double stemH = s * 0.08;
    final double buttonW = capW * 0.54;
    final double buttonH = s * 0.07;
    final double buttonRadius = buttonH * 0.45;

    // Haste metálica conectora
    final Rect stemRect = Rect.fromCenter(
      center: Offset(0, -halfH - (stemH / 2.0) + (s * 0.015)),
      width: stemW,
      height: stemH,
    );
    final Paint stemPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF94A3B8), Color(0xFFCBD5E1), Color(0xFF64748B)],
        stops: [0.0, 0.4, 1.0],
      ).createShader(stemRect);
    canvas.drawRect(stemRect, stemPaint);

    final Paint stemStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, s * 0.025)
      ..color = const Color(0xFF1E293B);
    canvas.drawRect(stemRect, stemStroke);

    // Cabeça do botão de pressão
    final Rect buttonRect = Rect.fromCenter(
      center: Offset(0, -halfH - stemH - (buttonH / 2.0) + (s * 0.015)),
      width: buttonW,
      height: buttonH,
    );
    final RRect buttonRRect = RRect.fromRectAndRadius(buttonRect, Radius.circular(buttonRadius));

    final Paint buttonPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFE2E8F0), Color(0xFF94A3B8)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(buttonRect);
    canvas.drawRRect(buttonRRect, buttonPaint);

    canvas.drawRRect(
      buttonRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, s * 0.025)
        ..color = const Color(0xFF1E293B),
    );
  }

  /// Desenha as 5 faixas da cápsula: Cúpula Topo, Faixa Colorida Superior, Faixa Preta, Faixa Colorida Inferior, Cúpula Base
  void _drawBodyBands(Canvas canvas, double capW, double capH, double halfH, double radius) {
    // Proporções longitudinais relativas da cápsula:
    // [-halfH ... +halfH]
    // Topo branco: [-halfH, -halfH + radius]
    // Faixa colorida superior: [-halfH + radius, -capH * 0.14]
    // Faixa preta com logo: [-capH * 0.14, +capH * 0.14]
    // Faixa colorida inferior: [+capH * 0.14, +halfH - radius]
    // Base branca: [+halfH - radius, +halfH]

    final double yTopWhiteEnd = -halfH + radius;
    final double yBlackStart = -capH * 0.15;
    final double yBlackEnd = capH * 0.15;
    final double yBottomWhiteStart = halfH - radius;

    // 1. Fundo base esbranquiçado de todo o corpo
    final Paint whiteDomePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9), Color(0xFFCBD5E1)],
        stops: [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(-capW / 2, -halfH, capW, capH));
    canvas.drawRect(Rect.fromLTWH(-capW / 2, -halfH, capW, capH), whiteDomePaint);

    // 2. Faixa Colorida Superior
    final Rect upperColorRect = Rect.fromLTRB(-capW / 2, yTopWhiteEnd, capW / 2, yBlackStart);
    final Paint upperColorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          color.withValues(alpha: 0.9),
          color,
          _darken(color, 0.35),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(upperColorRect);
    canvas.drawRect(upperColorRect, upperColorPaint);

    // 3. Faixa Preta Central (Base do Logo)
    final Rect blackRect = Rect.fromLTRB(-capW / 2, yBlackStart, capW / 2, yBlackEnd);
    final Paint blackPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF232A34), Color(0xFF131820), Color(0xFF090D13)],
        stops: [0.0, 0.4, 1.0],
      ).createShader(blackRect);
    canvas.drawRect(blackRect, blackPaint);

    // 4. Faixa Colorida Inferior
    final Rect lowerColorRect = Rect.fromLTRB(-capW / 2, yBlackEnd, capW / 2, yBottomWhiteStart);
    final Paint lowerColorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          color.withValues(alpha: 0.9),
          color,
          _darken(color, 0.35),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(lowerColorRect);
    canvas.drawRect(lowerColorRect, lowerColorPaint);

    // 5. Linhas pretas de separação técnica das seções
    final Paint dividerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, capW * 0.04)
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.7);

    canvas.drawLine(Offset(-capW / 2, yTopWhiteEnd), Offset(capW / 2, yTopWhiteEnd), dividerPaint);
    canvas.drawLine(Offset(-capW / 2, yBlackStart), Offset(capW / 2, yBlackStart), dividerPaint);
    canvas.drawLine(Offset(-capW / 2, yBlackEnd), Offset(capW / 2, yBlackEnd), dividerPaint);
    canvas.drawLine(Offset(-capW / 2, yBottomWhiteStart), Offset(capW / 2, yBottomWhiteStart), dividerPaint);
  }

  /// Desenha o monograma do logo da Capsule Corp no centro exato da faixa preta
  void _drawCapsuleCorpLogo(Canvas canvas, double capW, double s) {
    final double logoR = capW * 0.32;
    final Offset logoCenter = Offset.zero;

    // Círculo branco de base do logotipo
    final Paint whiteRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, s * 0.038)
      ..color = Colors.white;
    canvas.drawCircle(logoCenter, logoR, whiteRingPaint);

    // Anel interno com abertura em formato de "C"
    final double innerR = logoR * 0.58;
    final Paint cPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.1, s * 0.032)
      ..color = color; // Cor da própria cápsula!

    // Arco em C abrindo para a direita (de 45° a 315°, varredura de 270°)
    final Rect cRect = Rect.fromCircle(center: logoCenter, radius: innerR);
    canvas.drawArc(
      cRect,
      math.pi * 0.25,
      math.pi * 1.50,
      false,
      cPaint,
    );

    // Ponto central branco
    canvas.drawCircle(
      logoCenter,
      math.max(0.8, s * 0.016),
      Paint()..color = Colors.white,
    );
  }

  /// Desenha a iluminação 3D curvada (luz longitudinal na esquerda e vinheta na direita)
  void _draw3DSpecularHighlight(Canvas canvas, Rect bodyRect, double radius) {
    // Brilho especular longitudinal na lateral esquerda
    final double shineW = bodyRect.width * 0.18;
    final Rect shineRect = Rect.fromLTWH(
      bodyRect.left + (bodyRect.width * 0.12),
      bodyRect.top + (radius * 0.2),
      shineW,
      bodyRect.height - (radius * 0.4),
    );

    final Paint shinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(shineRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(shineRect, Radius.circular(shineW / 2)),
      shinePaint,
    );

    // Sombra de oclusão na borda direita do cilindro
    final Rect rimShadowRect = Rect.fromLTWH(
      bodyRect.right - (bodyRect.width * 0.22),
      bodyRect.top,
      bodyRect.width * 0.22,
      bodyRect.height,
    );
    final Paint rimShadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.black.withValues(alpha: 0.0),
          Colors.black.withValues(alpha: 0.45),
        ],
      ).createShader(rimShadowRect);

    canvas.drawRect(rimShadowRect, rimShadowPaint);
  }

  Color _darken(Color c, double factor) {
    final double f = (1.0 - factor).clamp(0.0, 1.0);
    return Color.from(
      alpha: c.a,
      red: (c.r * f).clamp(0.0, 1.0),
      green: (c.g * f).clamp(0.0, 1.0),
      blue: (c.b * f).clamp(0.0, 1.0),
    );
  }

  @override
  bool shouldRepaint(covariant CapsulePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.angleDegrees != angleDegrees;
  }
}
