import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/exercicio.dart';
import '../models/serie.dart';
import '../models/sessao_treino.dart';
import '../repositories/treino_repository.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';

class TreinoController extends ChangeNotifier {
  final TreinoRepository _repository;
  final PreferencesService _preferencesService;
  final NotificationService _notificationService;
  final SessaoTreino _sessaoTreino = SessaoTreino.vazia();

  TreinoController({
    required TreinoRepository repository,
    required PreferencesService preferencesService,
    required NotificationService notificationService,
  }) : _repository = repository,
       _preferencesService = preferencesService,
       _notificationService = notificationService {
    _carregarPreferencias();
  }

  Timer? _timer;
  int _tempoDescansoPadrao = 90;
  int _tempoAtual = 90;
  bool _isTimerRodando = false;
  int _descansoFinalizadoEvento = 0;
  DateTime _dataSessao = DateTime.now();

  final TextInputFormatter _pesoInputFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
        final texto = newValue.text;
        if (texto.isEmpty || RegExp(r'^\d+([.,]\d{0,2})?$').hasMatch(texto)) {
          return newValue;
        }
        return oldValue;
      });

  final TextInputFormatter _repsInputFormatter =
      FilteringTextInputFormatter.digitsOnly;

  int get tempoDescansoPadrao => _tempoDescansoPadrao;
  int get tempoAtual => _tempoAtual;
  bool get isTimerRodando => _isTimerRodando;
  int get descansoFinalizadoEvento => _descansoFinalizadoEvento;
  DateTime get dataSessao => _dataSessao;

  String get dataSessaoFormatada {
    if (_mesmoDia(_dataSessao, DateTime.now())) {
      return 'Hoje';
    }

    final dia = _dataSessao.day.toString().padLeft(2, '0');
    final mes = _dataSessao.month.toString().padLeft(2, '0');
    final ano = _dataSessao.year.toString();
    return '$dia/$mes/$ano';
  }

  Exercicio? get exercicioAtual => _sessaoTreino.exercicioAtual;
  bool get temExercicioEmAndamento => _sessaoTreino.exercicioAtual != null;
  List<Exercicio> get exerciciosConcluidosHoje =>
      UnmodifiableListView(_sessaoTreino.exerciciosConcluidosHoje);

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

  void alterarDataSessao(DateTime novaData) {
    _dataSessao = DateTime(novaData.year, novaData.month, novaData.day);
    notifyListeners();
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

    final temSerieIncompleta = atual.seriesDetalhes.any(
      (serie) => serie.peso == null || serie.reps == null,
    );
    if (temSerieIncompleta) {
      return 'Preencha o peso e as repetições de TODAS as séries antes de finalizar!';
    }

    _sessaoTreino.exerciciosConcluidosHoje.add(
      atual.copyWith(
        seriesDetalhes: atual.seriesDetalhes
            .map((serie) => serie.copy())
            .toList(),
      ),
    );
    _sessaoTreino.exercicioAtual = null;
    notifyListeners();
    return null;
  }

  void removerExercicio(Exercicio exercicio) {
    _sessaoTreino.exerciciosConcluidosHoje.remove(exercicio);

    if (identical(_sessaoTreino.exercicioAtual, exercicio)) {
      _sessaoTreino.exercicioAtual = null;
    }

    notifyListeners();
  }

  Future<void> encerrarTreino({bool descartarAtual = false}) async {
    final exercicioAtual = _sessaoTreino.exercicioAtual;

    if (!descartarAtual && exercicioAtual != null) {
      final seriesFiltradas = exercicioAtual.seriesDetalhes
          .where(
            (serie) =>
                serie.peso != null &&
                serie.reps != null &&
                serie.peso! > 0 &&
                serie.reps! > 0,
          )
          .map((serie) => serie.copy())
          .toList();

      if (seriesFiltradas.isNotEmpty) {
        _sessaoTreino.exerciciosConcluidosHoje.add(
          exercicioAtual.copyWith(seriesDetalhes: seriesFiltradas),
        );
      }
    }

    if (_sessaoTreino.exerciciosConcluidosHoje.isEmpty) return;

    final sessaoParaSalvar = SessaoTreino(
      data: _dataSessao,
      exerciciosConcluidosHoje: _sessaoTreino.exerciciosConcluidosHoje
          .map(
            (exercicio) => exercicio.copyWith(
              seriesDetalhes: exercicio.seriesDetalhes
                  .map((serie) => serie.copy())
                  .toList(),
            ),
          )
          .toList(),
    );

    await _repository.salvarSessaoTreino(sessaoParaSalvar);

    _sessaoTreino.exerciciosConcluidosHoje.clear();
    _sessaoTreino.exercicioAtual = null;
    _timer?.cancel();
    unawaited(_notificationService.cancelarNotificacao());
    _tempoAtual = _tempoDescansoPadrao;
    _isTimerRodando = false;
    _dataSessao = DateTime.now();
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
    if (atual == null || index < 0 || index >= atual.seriesDetalhes.length) {
      return;
    }

    final v = valor.replaceAll(',', '.').trim();
    atual.seriesDetalhes[index].peso = v.isEmpty ? null : double.tryParse(v);
  }

  void atualizarRepsSerie(int index, String valor) {
    final atual = _sessaoTreino.exercicioAtual;
    if (atual == null || index < 0 || index >= atual.seriesDetalhes.length) {
      return;
    }

    final v = valor.trim();
    atual.seriesDetalhes[index].reps = v.isEmpty ? null : int.tryParse(v);
  }

  void toggleConcluidaSerie(int index) {
    final atual = _sessaoTreino.exercicioAtual;
    if (atual == null || index < 0 || index >= atual.seriesDetalhes.length) {
      return;
    }

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
    if (tempoSelecionado <= 0) return;

    _tempoDescansoPadrao = tempoSelecionado;
    _tempoAtual = tempoSelecionado;
    _isTimerRodando = false;
    _timer?.cancel();
    _salvarTempoDescansoPadrao();
    notifyListeners();
  }

  Future<void> _salvarTempoDescansoPadrao() async {
    await _preferencesService.salvarInt(
      PreferencesService.keyTempoDescanso,
      _tempoDescansoPadrao,
    );
  }

  Future<void> _carregarPreferencias() async {
    final tempoSalvo = await _preferencesService.lerInt(
      PreferencesService.keyTempoDescanso,
    );
    if (tempoSalvo == null || tempoSalvo <= 0) return;

    _tempoDescansoPadrao = tempoSalvo;
    if (!_isTimerRodando) {
      _tempoAtual = tempoSalvo;
    }
    notifyListeners();
  }

  void iniciarTimer() {
    _tempoAtual = _tempoDescansoPadrao;
    _isTimerRodando = true;
    unawaited(_notificationService.agendarNotificacaoDescanso(_tempoAtual));
    notifyListeners();
    _iniciarTicker();
  }

  void pausarTimer() {
    _timer?.cancel();
    _isTimerRodando = false;
    unawaited(_notificationService.cancelarNotificacao());
    notifyListeners();
  }

  void continuarTimer() {
    if (_isTimerRodando) return;

    if (_tempoAtual <= 0) {
      _tempoAtual = _tempoDescansoPadrao;
    }
    _isTimerRodando = true;
    unawaited(_notificationService.agendarNotificacaoDescanso(_tempoAtual));
    notifyListeners();
    _iniciarTicker();
  }

  void reiniciarTimer() {
    _timer?.cancel();
    _tempoAtual = _tempoDescansoPadrao;
    _isTimerRodando = false;
    unawaited(_notificationService.cancelarNotificacao());
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

  bool _mesmoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
