import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/sessao_treino.dart';
import '../repositories/treino_repository.dart';
import '../services/backup_service.dart';

class HistoricoDia {
  final String dataLabel;
  final SessaoTreino sessao;

  const HistoricoDia({
    required this.dataLabel,
    required this.sessao,
  });
}

class HistoricoController extends ChangeNotifier {
  final TreinoRepository _repository;
  final BackupService _backupService;
  final List<SessaoTreino> _sessoesTreino = [];
  bool _isProcessandoBackup = false;

  HistoricoController({
    required TreinoRepository repository,
    BackupService? backupService,
  })  : _repository = repository,
        _backupService = backupService ?? BackupService(repository: repository);

  bool get isProcessandoBackup => _isProcessandoBackup;

  Future<void> carregarHistorico() async {
    final sessoes = await _repository.buscarHistoricoTreinos();
    _sessoesTreino
      ..clear()
      ..addAll(sessoes);
    notifyListeners();
  }

  Future<void> excluirSessao(int sessaoId) async {
    await _repository.excluirSessaoTreino(sessaoId);
    _sessoesTreino.removeWhere((sessao) => sessao.id == sessaoId);
    notifyListeners();
  }

  Future<BackupResult> exportarBackup() async {
    _isProcessandoBackup = true;
    notifyListeners();
    try {
      return await _backupService.exportarBackup();
    } finally {
      _isProcessandoBackup = false;
      notifyListeners();
    }
  }

  Future<BackupResult> importarBackup({required bool mesclar}) async {
    _isProcessandoBackup = true;
    notifyListeners();
    try {
      final resultado = await _backupService.importarBackup(mesclar: mesclar);
      if (resultado.sucesso) {
        await carregarHistorico();
      }
      return resultado;
    } finally {
      _isProcessandoBackup = false;
      notifyListeners();
    }
  }

  String _formatarData(DateTime? data) {
    if (data == null) return 'Sem data';
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();
    return '$dia/$mes/$ano';
  }

  List<SessaoTreino> get sessoesTreino => UnmodifiableListView(_sessoesTreino);

  List<HistoricoDia> get historicoTreinos => UnmodifiableListView(
        _sessoesTreino
            .map(
              (sessao) => HistoricoDia(
                dataLabel: _formatarData(sessao.data),
                sessao: sessao,
              ),
            )
            .toList(),
      );
}
