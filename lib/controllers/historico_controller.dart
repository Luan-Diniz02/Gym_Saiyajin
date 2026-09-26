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
  bool _isLoading = true;

  HistoricoController({
    required TreinoRepository repository,
    BackupService? backupService,
  })  : _repository = repository,
        _backupService = backupService ?? BackupService(repository: repository);

  bool get isProcessandoBackup => _isProcessandoBackup;
  bool get isLoading => _isLoading;

  Future<void> carregarHistorico() async {
    _isLoading = true;
    notifyListeners();
    try {
      final sessoes = await _repository.buscarHistoricoTreinos();
      _sessoesTreino
        ..clear()
        ..addAll(sessoes);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> excluirSessao(int sessaoId) async {
    await _repository.excluirSessaoTreino(sessaoId);
    _sessoesTreino.removeWhere((sessao) => sessao.id == sessaoId);
    notifyListeners();
  }

  Future<void> atualizarSessao(SessaoTreino sessaoAtualizada) async {
    await _repository.atualizarSessaoTreino(sessaoAtualizada);
    final index = _sessoesTreino.indexWhere((s) => s.id == sessaoAtualizada.id);
    if (index != -1) {
      _sessoesTreino[index] = sessaoAtualizada;
    }
    _sessoesTreino.sort((a, b) {
      final dataA = a.data ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dataB = b.data ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dataB.compareTo(dataA);
    });
    notifyListeners();
  }

  /// Volume total consolidado de todas as sessões do histórico em kg
  double get volumeTotalGeral {
    double total = 0.0;
    for (final sessao in _sessoesTreino) {
      total += sessao.volumeTotal;
    }
    return total;
  }

  /// Tempo total de treino de todas as sessões em minutos
  int get tempoTotalMinutosGeral {
    int totalSegundos = 0;
    for (final sessao in _sessoesTreino) {
      totalSegundos += sessao.duracaoSegundos;
    }
    return totalSegundos ~/ 60;
  }

  /// Distância calculada em quilômetros no Caminho da Serpente (Meta: 1.000.000 km)
  double get distanciaCaminhoSerpenteKm {
    return (volumeTotalGeral / 10.0) + (tempoTotalMinutosGeral * 2.0);
  }

  /// Progresso percentual da travessia rumo ao planeta do Sr. Kaioh (0.0 a 1.0)
  double get progressoCaminhoSerpente {
    return (distanciaCaminhoSerpenteKm / 1000000.0).clamp(0.0, 1.0);
  }

  /// Marco canônico atual da jornada no Caminho da Serpente
  String get marcoCaminhoSerpente {
    final km = distanciaCaminhoSerpenteKm;
    if (km >= 1000000.0) {
      return 'Planeta do Sr. Kaioh (Travessia Concluída!)';
    } else if (km >= 800000.0) {
      return 'Cabeça da Serpente (Aterrissagem Iminente)';
    } else if (km >= 500000.0) {
      return 'Fim do Nevoeiro do Outro Mundo';
    } else if (km >= 200000.0) {
      return 'Palácio da Princesa Serpente';
    } else if (km >= 50000.0) {
      return 'Região das Nuvens Amarelas';
    } else {
      return 'Cauda da Serpente (Início da Jornada)';
    }
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
