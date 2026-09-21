import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../models/exercicio.dart';
import '../models/ficha_treino.dart';
import '../models/serie.dart';
import '../models/sessao_treino.dart';
import '../repositories/treino_repository.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';

class TreinoController extends ChangeNotifier with WidgetsBindingObserver {
  final TreinoRepository _repository;
  final PreferencesService _preferencesService;
  final NotificationService _notificationService;
  final SessaoTreino _sessaoTreino = SessaoTreino.vazia();

  String? _nomeTreino;
  String? get nomeTreino => _nomeTreino;

  final Map<String, List<Serie>> _ultimasSeriesCache = {};
  List<FichaTreino> _fichas = [];
  List<FichaTreino> get fichas => UnmodifiableListView(_fichas);
  List<FichaExercicioItem> _exerciciosFichaPendentes = [];
  List<FichaExercicioItem> get exerciciosFichaPendentes =>
      UnmodifiableListView(_exerciciosFichaPendentes);

  List<Map<String, String>> _exerciciosCustomizados = [];
  List<Map<String, String>> get exerciciosCustomizados => _exerciciosCustomizados;

  TreinoController({
    required TreinoRepository repository,
    required PreferencesService preferencesService,
    required NotificationService notificationService,
  }) : _repository = repository,
       _preferencesService = preferencesService,
       _notificationService = notificationService {
    WidgetsBinding.instance.addObserver(this);
    _carregarPreferencias();
    carregarFichas();
  }

  Timer? _timer;
  DateTime? _timerEndTime;
  int _tempoDescansoPadrao = 90;
  int _tempoAtual = 90;
  bool _isTimerRodando = false;
  int _descansoFinalizadoEvento = 0;
  DateTime _dataSessao = DateTime.now();

  int _duracaoTreinoSegundos = 0;
  int _descansoTotalSegundos = 0;
  DateTime? _inicioTreino;
  Timer? _sessaoTimer;
  DateTime? _ultimoCicloTreino;
  bool _treinoPausado = false;

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

  int get duracaoTreinoSegundos => _duracaoTreinoSegundos;
  int get descansoTotalSegundos => _descansoTotalSegundos;
  bool get isTreinoEmAndamento => _inicioTreino != null;
  bool get isTreinoPausado => _treinoPausado;

  String get duracaoTreinoFormatada => formatarTempoLegivel(_duracaoTreinoSegundos);
  String get descansoTotalFormatado => formatarTempoLegivel(_descansoTotalSegundos);

  String formatarTempoLegivel(int totalSegundos) {
    final horas = totalSegundos ~/ 3600;
    final minutos = (totalSegundos % 3600) ~/ 60;
    final segundos = totalSegundos % 60;
    if (horas > 0) {
      return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
    }
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

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

  void iniciarTreinoSeNecessario() {
    if (_inicioTreino == null) {
      _inicioTreino = DateTime.now();
      _ultimoCicloTreino = DateTime.now();
      _treinoPausado = false;
      _iniciarTickerSessao();
      notifyListeners();
    }
  }

  void alternarPausaTreinoGeral() {
    if (_inicioTreino == null) return;
    _treinoPausado = !_treinoPausado;
    if (_treinoPausado) {
      _sessaoTimer?.cancel();
    } else {
      _ultimoCicloTreino = DateTime.now();
      _iniciarTickerSessao();
    }
    notifyListeners();
  }

  void _iniciarTickerSessao() {
    _sessaoTimer?.cancel();
    _sessaoTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_treinoPausado) {
        _duracaoTreinoSegundos++;
        if (_isTimerRodando) {
          _descansoTotalSegundos++;
        }
        _ultimoCicloTreino = DateTime.now();
        notifyListeners();
      }
    });
  }

  void definirNomeTreino(String? nome) {
    final valor = nome?.trim();
    _nomeTreino = (valor == null || valor.isEmpty) ? null : valor;
    notifyListeners();
  }

  Future<void> carregarSeriesAnteriores(String nomeExercicio) async {
    final chave = nomeExercicio.toLowerCase().trim();
    if (chave.isEmpty) return;
    try {
      final series = await _repository.buscarUltimasSeriesExercicio(nomeExercicio);
      _ultimasSeriesCache[chave] = series;
      notifyListeners();
    } catch (_) {}
  }

  Serie? obterSerieAnterior(String nomeExercicio, int index) {
    final chave = nomeExercicio.toLowerCase().trim();
    final series = _ultimasSeriesCache[chave];
    if (series == null || series.isEmpty) return null;
    if (index < series.length) {
      return series[index];
    }
    return series.last;
  }

  void iniciarNovoExercicio(String nome, String grupo, {int quantidadeSeries = 1}) {
    iniciarTreinoSeNecessario();
    final qte = quantidadeSeries > 0 ? quantidadeSeries : 1;
    _sessaoTreino.exercicioAtual = Exercicio(
      nome: nome,
      grupo: grupo,
      seriesDetalhes: List.generate(qte, (_) => Serie()),
    );
    unawaited(carregarSeriesAnteriores(nome));
    notifyListeners();
  }

  void substituirExercicioAtual(String novoNome, String novoGrupo) {
    final atual = _sessaoTreino.exercicioAtual;
    if (atual == null) return;
    final qteSeries = atual.seriesDetalhes.length;
    _sessaoTreino.exercicioAtual = Exercicio(
      nome: novoNome,
      grupo: novoGrupo,
      seriesDetalhes: List.generate(qteSeries, (_) => Serie()),
    );
    unawaited(carregarSeriesAnteriores(novoNome));
    notifyListeners();
  }

  void substituirExercicioPendente(int index, String novoNome, String novoGrupo) {
    if (index < 0 || index >= _exerciciosFichaPendentes.length) return;
    final anterior = _exerciciosFichaPendentes[index];
    _exerciciosFichaPendentes[index] = anterior.copyWith(
      nome: novoNome,
      grupo: novoGrupo,
    );
    notifyListeners();
  }

  void removerExercicioPendente(int index) {
    if (index < 0 || index >= _exerciciosFichaPendentes.length) return;
    _exerciciosFichaPendentes.removeAt(index);
    notifyListeners();
  }

  void reordenarExerciciosPendentes(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (oldIndex < 0 ||
        oldIndex >= _exerciciosFichaPendentes.length ||
        newIndex < 0 ||
        newIndex >= _exerciciosFichaPendentes.length) {
      return;
    }
    final item = _exerciciosFichaPendentes.removeAt(oldIndex);
    _exerciciosFichaPendentes.insert(newIndex, item);
    notifyListeners();
  }

  void iniciarExercicioPendente(int index) {
    if (index < 0 || index >= _exerciciosFichaPendentes.length) return;

    final atual = _sessaoTreino.exercicioAtual;
    if (atual != null) {
      final temSerieFeita = atual.seriesDetalhes
          .any((s) => s.concluida || (s.peso != null && s.reps != null));
      if (!temSerieFeita) {
        _exerciciosFichaPendentes.add(FichaExercicioItem(
          nome: atual.nome,
          grupo: atual.grupo,
          seriesPadrao: atual.seriesDetalhes.length,
        ));
      }
    }

    final selecionado = _exerciciosFichaPendentes.removeAt(index);
    iniciarNovoExercicio(
      selecionado.nome,
      selecionado.grupo,
      quantidadeSeries: selecionado.seriesPadrao,
    );
  }

  Future<List<SessaoTreino>> buscarHistoricoParaFichas() async {
    try {
      return await _repository.buscarHistoricoTreinos();
    } catch (_) {
      return [];
    }
  }

  void iniciarProximoExercicioFicha() {
    if (_exerciciosFichaPendentes.isEmpty) return;
    final proximo = _exerciciosFichaPendentes.removeAt(0);
    iniciarNovoExercicio(
      proximo.nome,
      proximo.grupo,
      quantidadeSeries: proximo.seriesPadrao,
    );
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

    if (_exerciciosFichaPendentes.isNotEmpty) {
      iniciarProximoExercicioFicha();
    } else {
      notifyListeners();
    }
    return null;
  }

  void removerExercicio(Exercicio exercicio) {
    _sessaoTreino.exerciciosConcluidosHoje.remove(exercicio);

    if (identical(_sessaoTreino.exercicioAtual, exercicio)) {
      _sessaoTreino.exercicioAtual = null;
    }

    notifyListeners();
  }

  Future<void> carregarFichas() async {
    try {
      _fichas = await _repository.buscarFichas();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> salvarFicha(FichaTreino ficha) async {
    try {
      await _repository.salvarFicha(ficha);
      await carregarFichas();
    } catch (_) {}
  }

  Future<void> excluirFicha(int fichaId) async {
    try {
      await _repository.excluirFicha(fichaId);
      await carregarFichas();
    } catch (_) {}
  }

  void carregarFichaParaTreino(FichaTreino ficha) {
    iniciarTreinoSeNecessario();
    _nomeTreino = ficha.nome;
    _exerciciosFichaPendentes = List.from(ficha.exercicios);
    if (_sessaoTreino.exercicioAtual == null && _exerciciosFichaPendentes.isNotEmpty) {
      final primeiro = _exerciciosFichaPendentes.removeAt(0);
      iniciarNovoExercicio(
        primeiro.nome,
        primeiro.grupo,
        quantidadeSeries: primeiro.seriesPadrao,
      );
    }
    notifyListeners();
  }

  Future<FichaTreino?> salvarTreinoAtualComoFicha(String nomeFicha) async {
    final nomeTrimmed = nomeFicha.trim();
    if (nomeTrimmed.isEmpty) return null;

    final List<Exercicio> todos = List.from(_sessaoTreino.exerciciosConcluidosHoje);
    if (_sessaoTreino.exercicioAtual != null) {
      todos.add(_sessaoTreino.exercicioAtual!);
    }
    if (todos.isEmpty) return null;

    final itens = <FichaExercicioItem>[];
    for (int i = 0; i < todos.length; i++) {
      final ex = todos[i];
      itens.add(FichaExercicioItem(
        nome: ex.nome,
        grupo: ex.grupo,
        ordem: i,
        seriesPadrao: ex.seriesDetalhes.isNotEmpty ? ex.seriesDetalhes.length : 3,
      ));
    }

    final novaFicha = FichaTreino(nome: nomeTrimmed, exercicios: itens);
    await salvarFicha(novaFicha);
    return novaFicha;
  }

  Future<SessaoTreino?> encerrarTreino({bool descartarAtual = false}) async {
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

    if (_sessaoTreino.exerciciosConcluidosHoje.isEmpty) return null;

    final sessaoParaSalvar = SessaoTreino(
      data: _dataSessao,
      nomeTreino: _nomeTreino,
      duracaoSegundos: _duracaoTreinoSegundos,
      descansoTotalSegundos: _descansoTotalSegundos,
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
    _nomeTreino = null;
    _exerciciosFichaPendentes.clear();
    _timer?.cancel();
    _timerEndTime = null;
    _sessaoTimer?.cancel();
    _inicioTreino = null;
    _ultimoCicloTreino = null;
    _duracaoTreinoSegundos = 0;
    _descansoTotalSegundos = 0;
    _treinoPausado = false;
    unawaited(_notificationService.cancelarNotificacao());
    _tempoAtual = _tempoDescansoPadrao;
    _isTimerRodando = false;
    _dataSessao = DateTime.now();
    notifyListeners();

    return sessaoParaSalvar;
  }

  void adicionarSerie() {
    final atual = _sessaoTreino.exercicioAtual;
    if (atual == null) return;

    atual.seriesDetalhes.add(Serie());
    notifyListeners();
  }

  void removerSerie(int index) {
    final atual = _sessaoTreino.exercicioAtual;
    if (atual == null) return;

    if (atual.seriesDetalhes.length > 1 && index >= 0 && index < atual.seriesDetalhes.length) {
      atual.seriesDetalhes.removeAt(index);
      notifyListeners();
    }
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
    _timerEndTime = null;
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
    if (tempoSalvo != null && tempoSalvo > 0) {
      _tempoDescansoPadrao = tempoSalvo;
      if (!_isTimerRodando) {
        _tempoAtual = tempoSalvo;
      }
    }
    await carregarExerciciosCustomizados();
    notifyListeners();
  }

  Future<void> carregarExerciciosCustomizados() async {
    try {
      final dbExercicios = await _repository.buscarExerciciosUnicosRegistrados();
      final prefsString = await _preferencesService.lerString(PreferencesService.keyExerciciosCustomizados);
      
      List<Map<String, String>> prefsExercicios = [];
      if (prefsString != null) {
        try {
          final List<dynamic> decoded = jsonDecode(prefsString);
          prefsExercicios = decoded.map((e) => {
            'nome': (e['nome'] as String? ?? '').trim(),
            'grupo': (e['grupo'] as String? ?? '').trim(),
          }).toList();
        } catch (_) {}
      }

      final Map<String, Map<String, String>> merged = {};
      for (final ex in dbExercicios) {
        final nome = ex['nome'] ?? '';
        final grupo = ex['grupo'] ?? '';
        if (nome.isNotEmpty && grupo.isNotEmpty) {
          merged[nome.toLowerCase().trim()] = {
            'nome': nome.trim(),
            'grupo': grupo.trim(),
          };
        }
      }
      for (final ex in prefsExercicios) {
        final nome = ex['nome'] ?? '';
        final grupo = ex['grupo'] ?? '';
        if (nome.isNotEmpty && grupo.isNotEmpty) {
          merged[nome.toLowerCase().trim()] = {
            'nome': nome.trim(),
            'grupo': grupo.trim(),
          };
        }
      }

      _exerciciosCustomizados = merged.values.toList();
    } catch (_) {}
  }

  Future<void> salvarNovoExercicioCustomizado(String nome, String grupo) async {
    final nomeTrimmed = nome.trim();
    final grupoTrimmed = grupo.trim();
    if (nomeTrimmed.isEmpty || grupoTrimmed.isEmpty) return;

    final existe = _exerciciosCustomizados.any(
      (e) => e['nome']!.toLowerCase() == nomeTrimmed.toLowerCase(),
    );

    if (!existe) {
      _exerciciosCustomizados.add({
        'nome': nomeTrimmed,
        'grupo': grupoTrimmed,
      });

      try {
        await _preferencesService.salvarString(
          PreferencesService.keyExerciciosCustomizados,
          jsonEncode(_exerciciosCustomizados),
        );
      } catch (_) {}
      notifyListeners();
    }
  }

  void iniciarTimer() {
    _tempoAtual = _tempoDescansoPadrao;
    _timerEndTime = DateTime.now().add(Duration(seconds: _tempoAtual));
    _isTimerRodando = true;
    unawaited(_notificationService.agendarNotificacaoDescanso(_tempoAtual));
    notifyListeners();
    _iniciarTicker();
  }

  void pausarTimer() {
    _timer?.cancel();
    _timerEndTime = null;
    _isTimerRodando = false;
    unawaited(_notificationService.cancelarNotificacao());
    notifyListeners();
  }

  void continuarTimer() {
    if (_isTimerRodando) return;

    if (_tempoAtual <= 0) {
      _tempoAtual = _tempoDescansoPadrao;
    }
    _timerEndTime = DateTime.now().add(Duration(seconds: _tempoAtual));
    _isTimerRodando = true;
    unawaited(_notificationService.agendarNotificacaoDescanso(_tempoAtual));
    notifyListeners();
    _iniciarTicker();
  }

  void reiniciarTimer() {
    _timer?.cancel();
    _timerEndTime = null;
    _tempoAtual = _tempoDescansoPadrao;
    _isTimerRodando = false;
    unawaited(_notificationService.cancelarNotificacao());
    notifyListeners();
  }

  void _iniciarTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timerEndTime != null) {
        final remaining = _timerEndTime!.difference(DateTime.now()).inSeconds;
        if (remaining > 0) {
          _tempoAtual = remaining;
          notifyListeners();
        } else {
          _timer?.cancel();
          _isTimerRodando = false;
          _tempoAtual = 0;
          _descansoFinalizadoEvento++;
          notifyListeners();
        }
      }
    });
  }

  bool _mesmoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_inicioTreino != null && !_treinoPausado && _ultimoCicloTreino != null) {
        final elapsed = DateTime.now().difference(_ultimoCicloTreino!).inSeconds;
        if (elapsed > 0) {
          _duracaoTreinoSegundos += elapsed;
          if (_isTimerRodando && _timerEndTime != null) {
            final secondsToTarget = _timerEndTime!.difference(_ultimoCicloTreino!).inSeconds;
            final actualRestAdded = secondsToTarget > elapsed ? elapsed : (secondsToTarget > 0 ? secondsToTarget : 0);
            _descansoTotalSegundos += actualRestAdded;
          }
        }
        _ultimoCicloTreino = DateTime.now();
      }

      if (_isTimerRodando && _timerEndTime != null) {
        final remaining = _timerEndTime!.difference(DateTime.now()).inSeconds;
        if (remaining > 0) {
          _tempoAtual = remaining;
          notifyListeners();
        } else {
          _tempoAtual = 0;
          _timer?.cancel();
          _isTimerRodando = false;
          _descansoFinalizadoEvento++;
          notifyListeners();
        }
      } else {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _sessaoTimer?.cancel();
    super.dispose();
  }
}
