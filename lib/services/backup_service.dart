import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/ficha_treino.dart';
import '../models/sessao_treino.dart';
import '../repositories/treino_repository.dart';
import 'preferences_service.dart';

class BackupResult {
  final bool sucesso;
  final String mensagem;
  final int totalSessoes;
  final int totalFichas;

  const BackupResult({
    required this.sucesso,
    required this.mensagem,
    this.totalSessoes = 0,
    this.totalFichas = 0,
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
      final fichas = await _repository.buscarFichas();
      final prefsExerciciosRaw = await _preferencesService
          .lerString(PreferencesService.keyExerciciosCustomizados);

      List<dynamic> exerciciosCustomizados = [];
      if (prefsExerciciosRaw != null && prefsExerciciosRaw.isNotEmpty) {
        try {
          exerciciosCustomizados = jsonDecode(prefsExerciciosRaw) as List<dynamic>;
        } catch (_) {}
      }

      final metaDias = await _preferencesService.lerInt(PreferencesService.keyMetaDiasSemana);
      final pesoAtual = await _preferencesService.lerDouble(PreferencesService.keyPesoAtual);
      final altura = await _preferencesService.lerDouble(PreferencesService.keyAltura);
      final percentualGordura = await _preferencesService.lerDouble(PreferencesService.keyPercentualGordura);
      final dataAtualizacaoPeso = await _preferencesService.lerString(PreferencesService.keyDataUltimaAtualizacaoPeso);
      final tempoDescanso = await _preferencesService.lerInt(PreferencesService.keyTempoDescanso);

      final Map<String, dynamic> perfilUsuario = {};
      if (metaDias != null) perfilUsuario['meta_dias_semana'] = metaDias;
      if (pesoAtual != null) perfilUsuario['peso_atual'] = pesoAtual;
      if (altura != null) perfilUsuario['altura'] = altura;
      if (percentualGordura != null) perfilUsuario['percentual_gordura'] = percentualGordura;
      if (dataAtualizacaoPeso != null) perfilUsuario['data_atualizacao_peso'] = dataAtualizacaoPeso;
      if (tempoDescanso != null) perfilUsuario['tempo_descanso_padrao'] = tempoDescanso;

      final Map<String, dynamic> backupData = {
        'app': 'Gym Saiyajin',
        'versao_backup': 2,
        'data_exportacao': DateTime.now().toIso8601String(),
        'total_sessoes': sessoes.length,
        'total_fichas': fichas.length,
        'sessoes': sessoes.map((s) => s.toJson()).toList(),
        'fichas': fichas.map((f) => f.toJson()).toList(),
        'perfil_usuario': perfilUsuario,
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
          text: 'Backup completo do histórico de treinos e fichas do Gym Saiyajin.',
        ),
      );

      return BackupResult(
        sucesso: true,
        mensagem: shareResult.status == ShareResultStatus.success ||
                shareResult.status == ShareResultStatus.dismissed
            ? 'Backup exportado com sucesso!'
            : 'Arquivo de backup gerado.',
        totalSessoes: sessoes.length,
        totalFichas: fichas.length,
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

      // 1. Restaurar Sessões de Treino
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

      // 2. Restaurar Fichas de Treino se existirem
      int totalFichasImportadas = 0;
      if (data.containsKey('fichas') && data['fichas'] is List) {
        final List<dynamic> fichasJson = data['fichas'] as List<dynamic>;
        final List<FichaTreino> fichasParaImportar = [];
        for (final item in fichasJson) {
          if (item is Map<String, dynamic>) {
            fichasParaImportar.add(FichaTreino.fromJson(item));
          }
        }
        totalFichasImportadas = await _repository.importarFichas(
          fichasParaImportar,
          mesclar: mesclar,
        );
      }

      // 3. Restaurar Perfil do Usuário e Medidas se existirem
      final perfilJson = data['perfil_usuario'] as Map<String, dynamic>? ??
          data['usuario'] as Map<String, dynamic>?;
      if (perfilJson != null) {
        if (perfilJson.containsKey('meta_dias_semana') &&
            perfilJson['meta_dias_semana'] is int) {
          await _preferencesService.salvarInt(
            PreferencesService.keyMetaDiasSemana,
            perfilJson['meta_dias_semana'] as int,
          );
        }
        if (perfilJson.containsKey('peso_atual') &&
            perfilJson['peso_atual'] is num) {
          await _preferencesService.salvarDouble(
            PreferencesService.keyPesoAtual,
            (perfilJson['peso_atual'] as num).toDouble(),
          );
        }
        if (perfilJson.containsKey('altura') && perfilJson['altura'] is num) {
          await _preferencesService.salvarDouble(
            PreferencesService.keyAltura,
            (perfilJson['altura'] as num).toDouble(),
          );
        }
        if (perfilJson.containsKey('percentual_gordura') &&
            perfilJson['percentual_gordura'] is num) {
          await _preferencesService.salvarDouble(
            PreferencesService.keyPercentualGordura,
            (perfilJson['percentual_gordura'] as num).toDouble(),
          );
        }
        if (perfilJson.containsKey('data_atualizacao_peso') &&
            perfilJson['data_atualizacao_peso'] is String) {
          await _preferencesService.salvarString(
            PreferencesService.keyDataUltimaAtualizacaoPeso,
            perfilJson['data_atualizacao_peso'] as String,
          );
        }
        if (perfilJson.containsKey('tempo_descanso_padrao') &&
            perfilJson['tempo_descanso_padrao'] is int) {
          await _preferencesService.salvarInt(
            PreferencesService.keyTempoDescanso,
            perfilJson['tempo_descanso_padrao'] as int,
          );
        }
      }

      // 4. Restaurar exercícios customizados se existirem
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

      final partes = <String>[];
      partes.add(mesclar
          ? '$totalImportadas nova(s) sessão(ões)'
          : '$totalImportadas sessão(ões)');
      if (totalFichasImportadas > 0 || (!mesclar && data.containsKey('fichas'))) {
        partes.add(mesclar
            ? '$totalFichasImportadas nova(s) ficha(s)'
            : '$totalFichasImportadas ficha(s)');
      }
      if (perfilJson != null && perfilJson.isNotEmpty) {
        partes.add('perfil e metas');
      }

      return BackupResult(
        sucesso: true,
        mensagem: mesclar
            ? 'Importação concluída: ${partes.join(', ')} importada(s) com sucesso!'
            : 'Backup restaurado com sucesso (${partes.join(', ')})!',
        totalSessoes: totalImportadas,
        totalFichas: totalFichasImportadas,
      );
    } catch (e) {
      return BackupResult(
        sucesso: false,
        mensagem: 'Erro ao processar arquivo de backup: $e',
      );
    }
  }
}
