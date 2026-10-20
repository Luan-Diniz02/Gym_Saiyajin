import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/catalogo_exercicios.dart';

/// Mídia associada a um exercício personalizado:
/// - `tipo == 'catalogo'`: reutiliza um dos 88 GIFs oficiais 100% offline do `CatalogoExercicios`
/// - `tipo == 'arquivo'`: foto ou GIF enviado pelo usuário via Galeria ou Câmera
class MidiaExercicioCustom {
  final String nomeExercicio;
  final String tipo; // 'catalogo' | 'arquivo'
  final String? codigoMidia;
  final String? nomeReferenciaCatalogo;
  final String? equipamento;
  final String? musculoAlvo;
  final String? thumbLocalPath;
  final String? gifLocalPath;

  const MidiaExercicioCustom({
    required this.nomeExercicio,
    required this.tipo,
    this.codigoMidia,
    this.nomeReferenciaCatalogo,
    this.equipamento,
    this.musculoAlvo,
    this.thumbLocalPath,
    this.gifLocalPath,
  });

  String? get thumbAsset => codigoMidia != null && codigoMidia!.isNotEmpty
      ? 'assets/exercises/thumbs/$codigoMidia.jpg'
      : null;

  String? get gifAsset => codigoMidia != null && codigoMidia!.isNotEmpty
      ? 'assets/exercises/gifs/$codigoMidia.gif'
      : null;

  Map<String, dynamic> toJson() => {
        'nomeExercicio': nomeExercicio,
        'tipo': tipo,
        'codigoMidia': codigoMidia,
        'nomeReferenciaCatalogo': nomeReferenciaCatalogo,
        'equipamento': equipamento,
        'musculoAlvo': musculoAlvo,
        'thumbLocalPath': thumbLocalPath,
        'gifLocalPath': gifLocalPath,
      };

  factory MidiaExercicioCustom.fromJson(Map<String, dynamic> json) {
    return MidiaExercicioCustom(
      nomeExercicio: (json['nomeExercicio'] as String? ?? '').trim(),
      tipo: (json['tipo'] as String? ?? 'catalogo').trim(),
      codigoMidia: json['codigoMidia'] as String?,
      nomeReferenciaCatalogo:
          (json['nomeReferenciaCatalogo'] ?? json['nomeOriginalDataset'])
              as String?,
      equipamento: json['equipamento'] as String?,
      musculoAlvo: json['musculoAlvo'] as String?,
      thumbLocalPath: json['thumbLocalPath'] as String?,
      gifLocalPath: json['gifLocalPath'] as String?,
    );
  }

  MidiaExercicioCustom copyWith({
    String? nomeExercicio,
    String? thumbLocalPath,
    String? gifLocalPath,
  }) {
    return MidiaExercicioCustom(
      nomeExercicio: nomeExercicio ?? this.nomeExercicio,
      tipo: tipo,
      codigoMidia: codigoMidia,
      nomeReferenciaCatalogo: nomeReferenciaCatalogo,
      equipamento: equipamento,
      musculoAlvo: musculoAlvo,
      thumbLocalPath: thumbLocalPath ?? this.thumbLocalPath,
      gifLocalPath: gifLocalPath ?? this.gifLocalPath,
    );
  }
}

/// Serviço responsável por gerenciar mídias de exercícios personalizados:
/// - Reutilizar qualquer animação do Catálogo Offline Expandido (88 exercícios)
/// - Fazer upload de foto/GIF da Galeria ou Câmera do usuário
class ExercicioCustomMidiaService extends ChangeNotifier {
  static final ExercicioCustomMidiaService instance =
      ExercicioCustomMidiaService._();

  ExercicioCustomMidiaService._();

  static const String _prefsKey = 'exercicios_customizados_midia_v1';

  final Map<String, MidiaExercicioCustom> _midiasPorChave = {};
  bool _inicializado = false;

  static String normalizarChave(String nome) {
    return nome
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[()\[\]\-/_,.;:]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> inicializar() async {
    if (_inicializado) return;
    _inicializado = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        decoded.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            _midiasPorChave[key] = MidiaExercicioCustom.fromJson(value);
          } else if (value is Map) {
            _midiasPorChave[key] = MidiaExercicioCustom.fromJson(
              Map<String, dynamic>.from(value),
            );
          }
        });
        notifyListeners();
      }
    } catch (_) {}
  }

  MidiaExercicioCustom? obterMidia(String nomeExercicio) {
    if (!_inicializado) {
      inicializar();
    }
    final chave = normalizarChave(nomeExercicio);
    if (chave.isEmpty) return null;
    return _midiasPorChave[chave];
  }

  Future<void> _salvarNoPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapJson = <String, dynamic>{};
      _midiasPorChave.forEach((k, v) {
        mapJson[k] = v.toJson();
      });
      await prefs.setString(_prefsKey, jsonEncode(mapJson));
    } catch (_) {}
  }

  /// Associa um exercício personalizado a uma animação oficial do catálogo offline (zero uso de rede).
  Future<MidiaExercicioCustom> salvarMidiaDoCatalogo({
    required String nomeExercicio,
    required InfoExercicioCatalogo itemCatalogo,
  }) async {
    await inicializar();
    final chave = normalizarChave(nomeExercicio);

    final midia = MidiaExercicioCustom(
      nomeExercicio: nomeExercicio.trim(),
      tipo: 'catalogo',
      codigoMidia: itemCatalogo.codigoMidia,
      nomeReferenciaCatalogo: itemCatalogo.nome,
      equipamento: itemCatalogo.equipamento,
      musculoAlvo: itemCatalogo.musculoAlvo,
    );

    _midiasPorChave[chave] = midia;
    await _salvarNoPrefs();
    notifyListeners();
    return midia;
  }

  /// Seleciona uma foto/imagem/GIF da Câmera ou Galeria do celular e salva localmente.
  Future<MidiaExercicioCustom?> selecionarEAssociarDaGaleriaOuCamera({
    required String nomeExercicio,
    required ImageSource source,
    String? grupo,
  }) async {
    await inicializar();
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      maxWidth: 720,
      maxHeight: 720,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final docDir = await getApplicationDocumentsDirectory();
    final userDir = Directory(
      p.join(docDir.path, 'custom_exercises', 'user_media'),
    );
    if (!await userDir.exists()) {
      await userDir.create(recursive: true);
    }

    final ext = p.extension(picked.path).isNotEmpty
        ? p.extension(picked.path).toLowerCase()
        : '.jpg';
    final chave = normalizarChave(nomeExercicio);
    final nomeArquivo =
        'user_${chave.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final destino = File(p.join(userDir.path, nomeArquivo));

    final bytes = await picked.readAsBytes();
    await destino.writeAsBytes(bytes, flush: true);

    final midia = MidiaExercicioCustom(
      nomeExercicio: nomeExercicio.trim(),
      tipo: 'arquivo',
      equipamento: 'Personalizado',
      musculoAlvo: grupo ?? 'Personalizado',
      thumbLocalPath: destino.path,
      gifLocalPath: destino.path,
    );

    _midiasPorChave[chave] = midia;
    await _salvarNoPrefs();
    notifyListeners();
    return midia;
  }

  /// Migra a mídia quando um exercício personalizado é renomeado.
  Future<void> renomearExercicio(String nomeAntigo, String novoNome) async {
    await inicializar();
    final chaveAntiga = normalizarChave(nomeAntigo);
    final chaveNova = normalizarChave(novoNome);
    if (chaveAntiga.isEmpty ||
        chaveNova.isEmpty ||
        chaveAntiga == chaveNova) {
      return;
    }
    final existente = _midiasPorChave.remove(chaveAntiga);
    if (existente != null) {
      _midiasPorChave[chaveNova] = existente.copyWith(
        nomeExercicio: novoNome.trim(),
      );
      await _salvarNoPrefs();
      notifyListeners();
    }
  }

  /// Remove a mídia associada a um exercício personalizado.
  Future<void> removerMidia(String nomeExercicio) async {
    await inicializar();
    final chave = normalizarChave(nomeExercicio);
    if (_midiasPorChave.remove(chave) != null) {
      await _salvarNoPrefs();
      notifyListeners();
    }
  }
}
