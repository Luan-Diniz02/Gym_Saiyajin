import 'dart:collection';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';

class ProgressoController extends ChangeNotifier {
  double _pesoAtual = 69.0;
  double _altura = 1.70;
  final int _diasTreinadosNaSemana = 2;
  int _metaDiasSemana = 3;

  String _exercicioFiltro = 'SUPINO RETO';

  final List<String> _exerciciosDisponiveis = ['SUPINO RETO', 'AGACHAMENTO', 'REMADA CURVADA'];

  final Map<String, List<FlSpot>> _historicoGrafico = {
    'SUPINO RETO': [const FlSpot(0, 50), const FlSpot(1, 60), const FlSpot(2, 64)],
    'AGACHAMENTO': [const FlSpot(0, 70), const FlSpot(1, 80), const FlSpot(2, 84)],
    'REMADA CURVADA': [const FlSpot(0, 40), const FlSpot(1, 45), const FlSpot(2, 50)],
  };

  static const List<String> _datasDoGrafico = ['26/03', '28/03', '30/03'];

  double get pesoAtual => _pesoAtual;
  double get altura => _altura;
  int get diasTreinadosNaSemana => _diasTreinadosNaSemana;
  int get metaDiasSemana => _metaDiasSemana;

  String get exercicioFiltro => _exercicioFiltro;
  List<String> get exerciciosDisponiveis => UnmodifiableListView(_exerciciosDisponiveis);
  List<String> get datasDoGrafico => UnmodifiableListView(_datasDoGrafico);

  Map<String, List<FlSpot>> get historicoGrafico => UnmodifiableMapView(_historicoGrafico);

  List<FlSpot> get pontosDoGraficoFiltrado => _historicoGrafico[_exercicioFiltro] ?? const [];

  double calcularIMC() => _pesoAtual / (_altura * _altura);

  double get imc => calcularIMC();

  String get classificacaoImc => imc < 25 ? 'PESO NORMAL' : 'SOBREPESO';

  void atualizarFiltroExercicio(String novoExercicio) {
    if (!_historicoGrafico.containsKey(novoExercicio)) return;
    _exercicioFiltro = novoExercicio;
    notifyListeners();
  }

  void atualizarMedidas({required double peso, required double altura}) {
    _pesoAtual = peso;
    _altura = altura;
    notifyListeners();
  }

  void atualizarMetaDiasSemana(int novaMeta) {
    if (novaMeta < 1 || novaMeta > 7) return;
    _metaDiasSemana = novaMeta;
    notifyListeners();
  }
}
