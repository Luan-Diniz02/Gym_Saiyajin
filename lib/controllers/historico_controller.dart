import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/sessao_treino.dart';
import '../repositories/treino_repository.dart';

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
  final List<SessaoTreino> _sessoesTreino = [];

  HistoricoController({required TreinoRepository repository}) : _repository = repository;

  Future<void> carregarHistorico() async {
    final sessoes = await _repository.buscarHistoricoTreinos();
    _sessoesTreino
      ..clear()
      ..addAll(sessoes);
    notifyListeners();
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
