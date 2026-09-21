import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/sessao_treino.dart';
import '../repositories/treino_repository.dart';
import 'preferences_service.dart';

class BackupResult {
  final bool sucesso;
  final String mensagem;
  final int totalSessoes;

  const BackupResult({
    required this.sucesso,
    required this.mensagem,
    this.totalSessoes = 0,
  });
}

class BackupService {
  final TreinoRepository _repository;
  final PreferencesService _preferencesService;

  BackupService({
    TreinoRepository? repository,
    PreferencesService? preferencesService,
  })  : _repository = repository ?? TreinoRepository(),
        _preferencesService = preferencesService ?? PreferencesService();

  Future<BackupResult> exportarBackup() async {
    try {
      final sessoes = await _repository.buscarHistoricoTreinos();
      final prefsExerciciosRaw = await _preferencesService
          .lerString(PreferencesService.keyExerciciosCustomizados);

      List<dynamic> exerciciosCustomizados = [];
      if (prefsExerciciosRaw != null && prefsExerciciosRaw.isNotEmpty) {
        try {
          exerciciosCustomizados = jsonDecode(prefsExerciciosRaw) as List<dynamic>;
        } catch (_) {}
      }

      final Map<String, dynamic> backupData = {
        'app': 'Gym Saiyajin',
        'versao_backup': 1,
        'data_exportacao': DateTime.now().toIso8601String(),
        'total_sessoes': sessoes.length,
        'sessoes': sessoes.map((s) => s.toJson()).toList(),
        'exercicios_customizados': exerciciosCustomizados,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      final tempDir = await getTemporaryDirectory();
      final now = DateTime.now();
      final dataFormatada =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final fileName = 'gym_saiyajin_backup_$dataFormatada.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString);

      final xFile = XFile(
        file.path,
        mimeType: 'application/json',
        name: fileName,
      );

      final shareResult = await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: 'Backup Gym Saiyajin ($dataFormatada)',
          text: 'Backup completo do histórico de treinos do Gym Saiyajin.',
        ),
      );

      return BackupResult(
        sucesso: true,
        mensagem: shareResult.status == ShareResultStatus.success ||
                shareResult.status == ShareResultStatus.dismissed
            ? 'Backup exportado com sucesso!'
            : 'Arquivo de backup gerado.',
        totalSessoes: sessoes.length,
      );
    } catch (e) {
      return BackupResult(
        sucesso: false,
        mensagem: 'Falha ao exportar backup: $e',
      );
    }
  }

  Future<BackupResult> importarBackup({required bool mesclar}) async {
    try {
      final selectedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (selectedFiles.isEmpty) {
        return const BackupResult(
          sucesso: false,
          mensagem: 'Nenhum arquivo selecionado.',
        );
      }

      final filePicked = selectedFiles.first;
      final jsonContent = await filePicked.xFile.readAsString();

      if (jsonContent.trim().isEmpty) {
        return const BackupResult(
          sucesso: false,
          mensagem: 'O arquivo selecionado está vazio.',
        );
      }

      final Map<String, dynamic> data =
          jsonDecode(jsonContent) as Map<String, dynamic>;

      if (!data.containsKey('sessoes') || data['sessoes'] is! List) {
        return const BackupResult(
          sucesso: false,
          mensagem: 'Formato de backup inválido: lista de sessões não encontrada.',
        );
      }

      final List<dynamic> sessoesJson = data['sessoes'] as List<dynamic>;
      final List<SessaoTreino> sessoesParaImportar = [];

      for (final item in sessoesJson) {
        if (item is Map<String, dynamic>) {
          sessoesParaImportar.add(SessaoTreino.fromJson(item));
        }
      }

      final totalImportadas = await _repository.importarSessoes(
        sessoesParaImportar,
        mesclar: mesclar,
      );

      // Restaurar exercícios customizados se existirem
      if (data.containsKey('exercicios_customizados') &&
          data['exercicios_customizados'] is List) {
        final List<dynamic> customizadosJson =
            data['exercicios_customizados'] as List<dynamic>;
        if (customizadosJson.isNotEmpty) {
          final prefsString = await _preferencesService
              .lerString(PreferencesService.keyExerciciosCustomizados);
          List<dynamic> existentes = [];
          if (prefsString != null) {
            try {
              existentes = jsonDecode(prefsString) as List<dynamic>;
            } catch (_) {}
          }

          final Set<String> nomesExistentes = existentes
              .map((e) => (e['nome'] as String? ?? '').toLowerCase().trim())
              .toSet();

          for (final ex in customizadosJson) {
            final nome = (ex['nome'] as String? ?? '').trim();
            if (nome.isNotEmpty && !nomesExistentes.contains(nome.toLowerCase())) {
              existentes.add(ex);
              nomesExistentes.add(nome.toLowerCase());
            }
          }

          await _preferencesService.salvarString(
            PreferencesService.keyExerciciosCustomizados,
            jsonEncode(existentes),
          );
        }
      }

      return BackupResult(
        sucesso: true,
        mensagem: mesclar
            ? '$totalImportadas nova(s) sessão(ões) importada(s) com sucesso!'
            : 'Histórico restaurado com sucesso ($totalImportadas sessões)!',
        totalSessoes: totalImportadas,
      );
    } catch (e) {
      return BackupResult(
        sucesso: false,
        mensagem: 'Erro ao processar arquivo de backup: $e',
      );
    }
  }
}
