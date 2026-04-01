import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/exercicio.dart';
import '../models/serie.dart';
import '../models/sessao_treino.dart';

class HistoricoDia {
  final String dataLabel;
  final SessaoTreino sessao;

  const HistoricoDia({
    required this.dataLabel,
    required this.sessao,
  });
}

class HistoricoController extends ChangeNotifier {
  final List<HistoricoDia> _historicoTreinos = [
    HistoricoDia(
      dataLabel: '30 de Março de 2026',
      sessao: SessaoTreino(
        exerciciosConcluidosHoje: [
          Exercicio(
            nome: 'SUPINO RETO',
            grupo: 'PEITO',
            seriesDetalhes: [
              Serie(reps: 15, peso: 20),
              Serie(reps: 12, peso: 60),
              Serie(reps: 10, peso: 60),
              Serie(reps: 8, peso: 64),
            ],
          ),
          Exercicio(
            nome: 'CRUCIFIXO',
            grupo: 'PEITO',
            seriesDetalhes: [
              Serie(reps: 12, peso: 16),
              Serie(reps: 12, peso: 16),
              Serie(reps: 10, peso: 18),
            ],
          ),
        ],
      ),
    ),
    HistoricoDia(
      dataLabel: '28 de Março de 2026',
      sessao: SessaoTreino(
        exerciciosConcluidosHoje: [
          Exercicio(
            nome: 'AGACHAMENTO',
            grupo: 'PERNAS',
            seriesDetalhes: [
              Serie(reps: 10, peso: 80),
              Serie(reps: 10, peso: 80),
              Serie(reps: 8, peso: 84),
            ],
          ),
        ],
      ),
    ),
  ];

  List<HistoricoDia> get historicoTreinos => UnmodifiableListView(_historicoTreinos);
}
