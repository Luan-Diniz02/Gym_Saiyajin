import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/exercicio.dart';
import '../models/serie.dart';
import '../models/sessao_treino.dart';
import '../repositories/treino_repository.dart';

class TreinoController extends ChangeNotifier {
  final TreinoRepository _repository;
  final SessaoTreino _sessaoTreino = SessaoTreino.vazia();

  TreinoController({required TreinoRepository repository}) : _repository = repository;

  Timer? _timer;
  int _tempoDescansoPadrao = 90;
  int _tempoAtual = 90;
  bool _isTimerRodando = false;
  int _descansoFinalizadoEvento = 0;

  final TextInputFormatter _pesoInputFormatter = TextInputFormatter.withFunction((oldValue, newValue) {
    final texto = newValue.text;
    if (texto.isEmpty || RegExp(r'^\d+([.,]\d{0,2})?$').hasMatch(texto)) {
      return newValue;
    }
    return oldValue;
  });

  final TextInputFormatter _repsInputFormatter = FilteringTextInputFormatter.digitsOnly;

  final List<Exercicio> _exerciciosCadastrados = [
    Exercicio(nome: 'Crucifixo', grupo: 'PEITO', seriesDetalhes: []),
    Exercicio(nome: 'Agachamento Livre', grupo: 'PERNAS', seriesDetalhes: []),
    Exercicio(nome: 'Leg Press', grupo: 'PERNAS', seriesDetalhes: []),
    Exercicio(nome: 'Remada Curvada', grupo: 'COSTAS', seriesDetalhes: []),
    Exercicio(nome: 'Puxada Frontal', grupo: 'COSTAS', seriesDetalhes: []),
    Exercicio(nome: 'Rosca Direta', grupo: 'BÍCEPS', seriesDetalhes: []),
    Exercicio(nome: 'Supino Reto', grupo: 'PEITO', seriesDetalhes: []),
  ];

  int get tempoDescansoPadrao => _tempoDescansoPadrao;
  int get tempoAtual => _tempoAtual;
  bool get isTimerRodando => _isTimerRodando;
  int get descansoFinalizadoEvento => _descansoFinalizadoEvento;

  Exercicio? get exercicioAtual => _sessaoTreino.exercicioAtual;
  List<Exercicio> get exerciciosConcluidosHoje => UnmodifiableListView(_sessaoTreino.exerciciosConcluidosHoje);
  List<Exercicio> get exerciciosCadastrados => UnmodifiableListView(_exerciciosCadastrados);

  TextInputFormatter get pesoInputFormatter => _pesoInputFormatter;
  TextInputFormatter get repsInputFormatter => _repsInputFormatter;

  String get tempoFormatado {
    final minutos = _tempoAtual ~/ 60;
    final segundos = _tempoAtual % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  String formatarSegundos(int totalSegundos) {
    final minutos = totalSegundos ~/ 60;
    final segundos = totalSegundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  void iniciarNovoExercicio(String nome, String grupo) {
    _sessaoTreino.exercicioAtual = Exercicio(
      nome: nome,
      grupo: grupo,
      seriesDetalhes: [Serie()],
    );
    notifyListeners();
  }

  String? finalizarExercicioAtual() {
    final atual = _sessaoTreino.exercicioAtual;
    if (atual == null) return null;

    final temSerieIncompleta = atual.seriesDetalhes.any((serie) => serie.peso == null || serie.reps == null);
    if (temSerieIncompleta) {
      return 'Preencha o peso e as repetições de TODAS as séries antes de finalizar!';
    }

    _sessaoTreino.exerciciosConcluidosHoje.add(
      atual.copyWith(
        seriesDetalhes: atual.seriesDetalhes.map((serie) => serie.copy()).toList(),
      ),
    );
    _sessaoTreino.exercicioAtual = null;
    notifyListeners();
    return null;
  }

  Future<void> encerrarTreino() async {
    if (_sessaoTreino.exerciciosConcluidosHoje.isEmpty) return;

    final sessaoParaSalvar = SessaoTreino(
      data: DateTime.now(),
      exerciciosConcluidosHoje: _sessaoTreino.exerciciosConcluidosHoje
          .map(
            (exercicio) => exercicio.copyWith(
              seriesDetalhes: exercicio.seriesDetalhes.map((serie) => serie.copy()).toList(),
            ),
          )
          .toList(),
    );

    await _repository.salvarSessaoTreino(sessaoParaSalvar);

    _sessaoTreino.exerciciosConcluidosHoje.clear();
    _sessaoTreino.exercicioAtual = null;
    _timer?.cancel();
    _tempoAtual = _tempoDescansoPadrao;
    _isTimerRodando = false;
    notifyListeners();
  }

  void adicionarSerie() {
    final atual = _sessaoTreino.exercicioAtual;
    if (atual == null) return;

    atual.seriesDetalhes.add(Serie());
    notifyListeners();
  }

  void atualizarPesoSerie(int index, String valor) {
    final atual = _sessaoTreino.exercicioAtual;
    if (atual == null || index < 0 || index >= atual.seriesDetalhes.length) return;

    final v = valor.replaceAll(',', '.').trim();
    atual.seriesDetalhes[index].peso = v.isEmpty ? null : double.tryParse(v);
  }

  void atualizarRepsSerie(int index, String valor) {
    final atual = _sessaoTreino.exercicioAtual;
    if (atual == null || index < 0 || index >= atual.seriesDetalhes.length) return;

    final v = valor.trim();
    atual.seriesDetalhes[index].reps = v.isEmpty ? null : int.tryParse(v);
  }

  void toggleConcluidaSerie(int index) {
    final atual = _sessaoTreino.exercicioAtual;
    if (atual == null || index < 0 || index >= atual.seriesDetalhes.length) return;

    final serie = atual.seriesDetalhes[index];
    final agoraConcluida = !serie.concluida;
    serie.concluida = agoraConcluida;

    if (agoraConcluida) {
      iniciarTimer();
      return;
    }

    notifyListeners();
  }

  void atualizarTempoDescanso(int tempoSelecionado) {
    _tempoDescansoPadrao = tempoSelecionado;
    _tempoAtual = tempoSelecionado;
    _isTimerRodando = false;
    _timer?.cancel();
    notifyListeners();
  }

  void iniciarTimer() {
    _tempoAtual = _tempoDescansoPadrao;
    _isTimerRodando = true;
    notifyListeners();
    _iniciarTicker();
  }

  void pausarTimer() {
    _timer?.cancel();
    _isTimerRodando = false;
    notifyListeners();
  }

  void continuarTimer() {
    if (_isTimerRodando) return;

    if (_tempoAtual <= 0) {
      _tempoAtual = _tempoDescansoPadrao;
    }
    _isTimerRodando = true;
    notifyListeners();
    _iniciarTicker();
  }

  void reiniciarTimer() {
    _timer?.cancel();
    _tempoAtual = _tempoDescansoPadrao;
    _isTimerRodando = false;
    notifyListeners();
  }

  void _iniciarTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_tempoAtual > 0) {
        _tempoAtual--;
        notifyListeners();
        return;
      }

      _timer?.cancel();
      _isTimerRodando = false;
      _descansoFinalizadoEvento++;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
