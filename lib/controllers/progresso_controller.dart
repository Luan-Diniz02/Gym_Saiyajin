import 'dart:collection';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';

import '../models/exercicio.dart';
import '../models/sessao_treino.dart';
import '../models/serie.dart';
import '../repositories/treino_repository.dart';

class ProgressoController extends ChangeNotifier {
  final TreinoRepository _repository;

  ProgressoController({required TreinoRepository repository}) : _repository = repository;

  double _pesoAtual = 69.0;
  double _altura = 1.70;
  int _diasTreinadosNaSemana = 0;
  int _metaDiasSemana = 3;

  String _exercicioFiltro = 'SUPINO RETO';
  final List<String> _exerciciosDisponiveis = ['SUPINO RETO'];
  final List<FlSpot> _pontosDoGraficoFiltrado = [];
  final List<String> _datasDoGrafico = [];
  List<SessaoTreino> _historicoCache = [];

  double get pesoAtual => _pesoAtual;
  double get altura => _altura;
  int get diasTreinadosNaSemana => _diasTreinadosNaSemana;
  int get metaDiasSemana => _metaDiasSemana;

  String get exercicioFiltro => _exercicioFiltro;
  List<String> get exerciciosDisponiveis => UnmodifiableListView(_exerciciosDisponiveis);
  List<String> get datasDoGrafico => UnmodifiableListView(_datasDoGrafico);

  List<FlSpot> get pontosDoGraficoFiltrado => UnmodifiableListView(_pontosDoGraficoFiltrado);

  double calcularIMC() => _pesoAtual / (_altura * _altura);

  double get imc => calcularIMC();

  String get classificacaoImc => imc < 25 ? 'PESO NORMAL' : 'SOBREPESO';

  Future<void> carregarDados() async {
    final historico = await _repository.buscarHistoricoTreinos();
    _historicoCache = historico;

    _calcularDiasAtivos(historico);
    _atualizarListaExercicios(historico);
    _recalcularDadosGrafico();

    notifyListeners();
  }

  void _calcularDiasAtivos(List<SessaoTreino> historico) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final inicioJanela = hoje.subtract(const Duration(days: 6));

    final Set<String> diasUnicos = {};
    for (final sessao in historico) {
      final data = sessao.data;
      if (data == null) continue;

      final diaSessao = DateTime(data.year, data.month, data.day);
      if (diaSessao.isBefore(inicioJanela) || diaSessao.isAfter(hoje)) continue;

      diasUnicos.add('${diaSessao.year}-${diaSessao.month}-${diaSessao.day}');
    }

    _diasTreinadosNaSemana = diasUnicos.length;
  }

  void _atualizarListaExercicios(List<SessaoTreino> historico) {
    final Set<String> unicos = {};
    for (final sessao in historico) {
      for (final exercicio in sessao.exerciciosConcluidosHoje) {
        if (exercicio.nome.trim().isNotEmpty) {
          unicos.add(exercicio.nome);
        }
      }
    }

    _exerciciosDisponiveis
      ..clear()
      ..addAll(unicos.isEmpty ? ['SUPINO RETO'] : unicos.toList()..sort());

    if (!_exerciciosDisponiveis.contains(_exercicioFiltro)) {
      _exercicioFiltro = _exerciciosDisponiveis.first;
    }
  }

  void _recalcularDadosGrafico() {
    final sessoesComExercicio = _historicoCache
        .where((sessao) => sessao.exerciciosConcluidosHoje.any((ex) => ex.nome == _exercicioFiltro))
        .toList()
      ..sort((a, b) {
        final dataA = a.data;
        final dataB = b.data;
        if (dataA == null && dataB == null) return (a.id ?? 0).compareTo(b.id ?? 0);
        if (dataA == null) return -1;
        if (dataB == null) return 1;
        return dataA.compareTo(dataB);
      });

    _pontosDoGraficoFiltrado.clear();
    _datasDoGrafico.clear();

    for (int i = 0; i < sessoesComExercicio.length; i++) {
      final sessao = sessoesComExercicio[i];
      final double? pesoMaximo = _buscarPesoMaximo(sessao.exerciciosConcluidosHoje, _exercicioFiltro);
      if (pesoMaximo == null) continue;

      _pontosDoGraficoFiltrado.add(FlSpot(i.toDouble(), pesoMaximo));

      final data = sessao.data;
      if (data == null) {
        _datasDoGrafico.add('--/--');
      } else {
        final dia = data.day.toString().padLeft(2, '0');
        final mes = data.month.toString().padLeft(2, '0');
        _datasDoGrafico.add('$dia/$mes');
      }
    }
  }

  double? _buscarPesoMaximo(List<Exercicio> exercicios, String nomeExercicio) {
    final Iterable<Serie> series = exercicios
        .where((exercicio) => exercicio.nome == nomeExercicio)
        .expand((exercicio) => exercicio.seriesDetalhes);

    double? maximo;
    for (final serie in series) {
      final peso = serie.peso;
      if (peso == null) continue;
      if (maximo == null || peso > maximo) {
        maximo = peso;
      }
    }
    return maximo;
  }

  void mudarExercicioFiltro(String novoExercicio) {
    if (!_exerciciosDisponiveis.contains(novoExercicio)) return;
    _exercicioFiltro = novoExercicio;
    _recalcularDadosGrafico();
    notifyListeners();
  }

  void atualizarFiltroExercicio(String novoExercicio) {
    mudarExercicioFiltro(novoExercicio);
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
