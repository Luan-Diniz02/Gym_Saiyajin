import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CardShareService {
  static Future<bool> compartilharWidgetComoImagem({
    required GlobalKey boundaryKey,
    required String nomeArquivo,
    String? textoCompartilhamento,
  }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return false;

      // Renderiza com pixelRatio 3.0 para alta nitidez em Stories / WhatsApp
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return false;

      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$nomeArquivo.png');
      await file.writeAsBytes(pngBytes);

      final xFile = XFile(
        file.path,
        mimeType: 'image/png',
        name: '$nomeArquivo.png',
      );

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: textoCompartilhamento ?? '🔥 Treino concluído no Gym Saiyajin! 💪⚡',
          subject: 'Card de Treino - Gym Saiyajin',
        ),
      );

      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> compartilharTexto(String texto) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          text: texto,
          subject: 'Treino - Gym Saiyajin',
        ),
      );
      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    } catch (_) {
      return false;
    }
  }
}
