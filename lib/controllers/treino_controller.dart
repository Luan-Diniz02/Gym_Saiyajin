import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../models/exercicio.dart';
import '../models/ficha_treino.dart';
import '../models/recorde_pessoal.dart';
import '../models/serie.dart';
import '../models/sessao_treino.dart';
import '../repositories/treino_repository.dart';
import '../services/exercicio_custom_midia_service.dart';
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
  final Map<String, RecordePessoal> _recordesBaseCache = {};
  final Map<String, RecordePessoal> _recordesBatidosHoje = {};

  Map<String, RecordePessoal> get recordesBatidosHoje =>
      UnmodifiableMapView(_recordesBatidosHoje);
  int get totalRecordesBatidosHoje => _recordesBatidosHoje.length;
  RecordePessoal? obterRecordeBase(String nomeExercicio) =>
      _recordesBaseCache[nomeExercicio.toLowerCase().trim()];

  /// Calcula o volume total (kg levantados) da sessão atual.
  double calcularVolumeSessao({bool incluirAtual = true}) {
    double volumeTotal = _sessaoTreino.volumeTotal;

    if (incluirAtual && _sessaoTreino.exercicioAtual != null) {
      for (final serie in _sessaoTreino.exercicioAtual!.seriesDetalhes) {
        final peso = serie.peso ?? 0.0;
        final reps = serie.reps ?? 0;
        if ((serie.concluida || (serie.peso != null && serie.reps != null)) &&
            peso > 0 &&
            reps > 0) {
          volumeTotal += (peso * reps);
        }
      }
    }

    return volumeTotal;
  }

  /// Calcula o Ki gerado na sessão atual.
  int calcularKiSessao({bool incluirAtual = true}) {
    final volume = calcularVolumeSessao(incluirAtual: incluirAtual);
    return (volume / 100.0).round() + (totalRecordesBatidosHoje * 150);
  }

  List<FichaTreino> _fichas = [];
  List<FichaTreino> get fichas => UnmodifiableListView(_fichas);
  List<FichaExercicioItem> _exerciciosFichaPendentes = [];
  List<FichaExercicioItem> get exerciciosFichaPendentes =>
      UnmodifiableListView(_exerciciosFichaPendentes);

  List<Map<String, String>> _exerciciosCustomizados = [];
  List<Map<String, String>> get exerciciosCustomizados =>
      _exerciciosCustomizados;

  TreinoController({
    required TreinoRepository repository,
    required PreferencesService preferencesService,
    required NotificationService notificationService,
  })  : _repository = repository,
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

  /// Notifier isolado para atualização a cada 1s da duração geral do treino sem rebuild da tela.
  final ValueNotifier<int> duracaoTreinoNotifier = ValueNotifier<int>(0);

  /// Notifier isolado para atualização a cada 1s do cronômetro de descanso sem rebuild da tela.
  final ValueNotifier<int> tempoDescansoNotifier = ValueNotifier<int>(90);

  void _atualizarTempoAtual(int valor) {
    _tempoAtual = valor;
    tempoDescansoNotifier.value = valor;
  }

  int _descansoTotalSegundos = 0;
  DateTime? _inicioTreino;
  DateTime? _inicioDescansoAtual;
  Timer? _sessaoTimer;
  bool _treinoPausado = false;
  Duration _tempoPausadoTotal = Duration.zero;
  DateTime? _inicioPausaAtual;

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

  int get duracaoTreinoSegundos {
    if (_inicioTreino == null) return 0;
    if (_treinoPausado && _inicioPausaAtual != null) {
      return (_inicioPausaAtual!.difference(_inicioTreino!) -
              _tempoPausadoTotal)
          .inSeconds
          .clamp(0, 86400 * 7);
    }
    return (DateTime.now().difference(_inicioTreino!) - _tempoPausadoTotal)
        .inSeconds
        .clamp(0, 86400 * 7);
  }

  int get descansoTotalSegundos {
    if (_isTimerRodando && _inicioDescansoAtual != null) {
      final agora = DateTime.now();
      final fim = (_timerEndTime != null && agora.isAfter(_timerEndTime!))
          ? _timerEndTime!
          : agora;
      final decorridoMs = fim.difference(_inicioDescansoAtual!).inMilliseconds;
      final decorrido = (decorridoMs / 1000.0).round();
      return _descansoTotalSegundos + (decorrido > 0 ? decorrido : 0);
    }
    return _descansoTotalSegundos;
  }

  bool get isTreinoEmAndamento => _inicioTreino != null;
  bool get treinoAtivo =>
      isTreinoEmAndamento ||
      temExercicioEmAndamento ||
      _sessaoTreino.exerciciosConcluidosHoje.isNotEmpty;
  bool get isTreinoPausado => _treinoPausado;

  String get duracaoTreinoFormatada =>
      formatarTempoLegivel(duracaoTreinoSegundos);
  String get descansoTotalFormatado =>
      formatarTempoLegivel(descansoTotalSegundos);

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

  String formatarSegundos(int totalSegundos) => formatarSegundosDescanso(totalSegundos);

  static String formatarSegundosDescanso(int totalSegundos) {
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
      _tempoPausadoTotal = Duration.zero;
      _inicioPausaAtual = null;
      _treinoPausado = false;
      duracaoTreinoNotifier.value = 0;
      _iniciarTickerSessao();
      notifyListeners();
    }
  }

  void alternarPausaTreinoGeral() {
    if (_inicioTreino == null) return;
    _treinoPausado = !_treinoPausado;
    if (_treinoPausado) {
      _inicioPausaAtual = DateTime.now();
      _sessaoTimer?.cancel();
    } else {
      if (_inicioPausaAtual != null) {
        _tempoPausadoTotal += DateTime.now().difference(_inicioPausaAtual!);
        _inicioPausaAtual = null;
      }
      _iniciarTickerSessao();
    }
    duracaoTreinoNotifier.value = duracaoTreinoSegundos;
    notifyListeners();
  }

  void _iniciarTickerSessao() {
    _sessaoTimer?.cancel();
    duracaoTreinoNotifier.value = duracaoTreinoSegundos;
    _sessaoTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_treinoPausado) {
        duracaoTreinoNotifier.value = duracaoTreinoSegundos;
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
      final series = await _repository.buscarUltimasSeriesExercicio(
        nomeExercicio,
      );
      _ultimasSeriesCache[chave] = series;

      final pr = await _repository.buscarRecordeHistoricoExercicio(
        nomeExercicio,
      );
      if (pr != null) {
        _recordesBaseCache[chave] = pr;
      }

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

  void iniciarNovoExercicio(
    String nome,
    String grupo, {
    int quantidadeSeries = 1,
  }) {
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

  void substituirExercicioPendente(
    int index,
    String novoNome,
    String novoGrupo,
  ) {
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
      final temSerieFeita = atual.seriesDetalhes.any(
        (s) => s.concluida || (s.peso != null && s.reps != null),
      );
      if (!temSerieFeita) {
        _exerciciosFichaPendentes.add(
          FichaExercicioItem(
            nome: atual.nome,
            grupo: atual.grupo,
            seriesPadrao: atual.seriesDetalhes.length,
          ),
        );
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

    final seriesConcluidas = atual.seriesDetalhes
        .map((serie) {
          final copy = serie.copy();
          if ((copy.peso ?? 0) > 0 && (copy.reps ?? 0) > 0) {
            copy.concluida = true;
          }
          return copy;
        })
        .toList();

    _sessaoTreino.exerciciosConcluidosHoje.add(
      atual.copyWith(
        seriesDetalhes: seriesConcluidas,
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
    if (_sessaoTreino.exercicioAtual == null &&
        _exerciciosFichaPendentes.isNotEmpty) {
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

    final List<Exercicio> todos = List.from(
      _sessaoTreino.exerciciosConcluidosHoje,
    );
    if (_sessaoTreino.exercicioAtual != null) {
      todos.add(_sessaoTreino.exercicioAtual!);
    }
    if (todos.isEmpty) return null;

    final itens = <FichaExercicioItem>[];
    for (int i = 0; i < todos.length; i++) {
      final ex = todos[i];
      itens.add(
        FichaExercicioItem(
          nome: ex.nome,
          grupo: ex.grupo,
          ordem: i,
          seriesPadrao: ex.seriesDetalhes.isNotEmpty
              ? ex.seriesDetalhes.length
              : 3,
        ),
      );
    }

    final novaFicha = FichaTreino(nome: nomeTrimmed, exercicios: itens);
    await salvarFicha(novaFicha);
    return novaFicha;
  }

  Future<SessaoTreino?> encerrarTreino({
    bool descartarAtual = false,
    int? duracaoSegundosPersonalizada,
    int? descansoTotalSegundosPersonalizado,
  }) async {
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
          .map((serie) {
            final copy = serie.copy();
            copy.concluida = true;
            return copy;
          })
          .toList();

      if (seriesFiltradas.isNotEmpty) {
        _sessaoTreino.exerciciosConcluidosHoje.add(
          exercicioAtual.copyWith(seriesDetalhes: seriesFiltradas),
        );
      }
    }

    if (_sessaoTreino.exerciciosConcluidosHoje.isEmpty) return null;

    _acumularDescansoAtual();
    final duracaoFinal = duracaoSegundosPersonalizada ?? duracaoTreinoSegundos;
    final descansoFinal = descansoTotalSegundosPersonalizado ?? descansoTotalSegundos;

    final sessaoParaSalvar = SessaoTreino(
      data: _dataSessao,
      nomeTreino: _nomeTreino,
      duracaoSegundos: duracaoFinal,
      descansoTotalSegundos: descansoFinal,
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
    _recordesBatidosHoje.clear();
    _recordesBaseCache.clear();
    _exerciciosFichaPendentes.clear();
    _timer?.cancel();
    _timerEndTime = null;
    _inicioDescansoAtual = null;
    _sessaoTimer?.cancel();
    _inicioTreino = null;
    _inicioPausaAtual = null;
    _tempoPausadoTotal = Duration.zero;
    _descansoTotalSegundos = 0;
    _treinoPausado = false;
    unawaited(_notificationService.cancelarNotificacao());
    duracaoTreinoNotifier.value = 0;
    _atualizarTempoAtual(_tempoDescansoPadrao);
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

    if (atual.seriesDetalhes.length > 1 &&
        index >= 0 &&
        index < atual.seriesDetalhes.length) {
      atual.seriesDetalhes.removeAt(index);
      _reavaliarRecordesExercicio(atual.nome, atual.grupo, atual.seriesDetalhes);
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
    if (atual.seriesDetalhes[index].concluida) {
      _reavaliarRecordesExercicio(atual.nome, atual.grupo, atual.seriesDetalhes);
    }
  }

  void atualizarRepsSerie(int index, String valor) {
    final atual = _sessaoTreino.exercicioAtual;
    if (atual == null || index < 0 || index >= atual.seriesDetalhes.length) {
      return;
    }

    final v = valor.trim();
    atual.seriesDetalhes[index].reps = v.isEmpty ? null : int.tryParse(v);
    if (atual.seriesDetalhes[index].concluida) {
      _reavaliarRecordesExercicio(atual.nome, atual.grupo, atual.seriesDetalhes);
    }
  }

  /// Atualiza a classificação da série (`normal`, `warmup`, `dropset`, `falha`).
  /// Séries de aquecimento (*Kinto-un* / `warmup`) são excluídas do cálculo de PR e 1RM.
  void atualizarTipoSerie(int index, String novoTipo) {
    final atual = _sessaoTreino.exercicioAtual;
    if (atual == null || index < 0 || index >= atual.seriesDetalhes.length) {
      return;
    }

    final serie = atual.seriesDetalhes[index];
    final eraFalha = serie.isFalha;
    final tipoNormalizado = TipoSerie.fromCodigo(novoTipo);
    serie.tipo = tipoNormalizado.codigo;
    if (tipoNormalizado == TipoSerie.falha) {
      serie.rir = 0;
    } else if (eraFalha && serie.rir == 0) {
      serie.rir = null;
    }
    _reavaliarRecordesExercicio(atual.nome, atual.grupo, atual.seriesDetalhes);
    notifyListeners();
  }

  /// Alterna ciclicamente o tipo da série (`normal` -> `warmup` -> `dropset` -> `falha` -> `normal`).
  void alternarTipoSerie(int index) {
    final atual = _sessaoTreino.exercicioAtual;
    if (atual == null || index < 0 || index >= atual.seriesDetalhes.length) {
      return;
    }
    final proximo = atual.seriesDetalhes[index].tipoEnum.proximo;
    atualizarTipoSerie(index, proximo.codigo);
  }

  /// Atualiza ou limpa a métrica subjetiva de esforço RIR (Reps in Reserve) da série.
  void atualizarRirSerie(int index, int? novoRir) {
    final atual = _sessaoTreino.exercicioAtual;
    if (atual == null || index < 0 || index >= atual.seriesDetalhes.length) {
      return;
    }

    atual.seriesDetalhes[index].rir = novoRir?.clamp(0, 4);
    notifyListeners();
  }

  bool preencherSerieComAnterior(int index) {
    final atual = _sessaoTreino.exercicioAtual;
    if (atual == null || index < 0 || index >= atual.seriesDetalhes.length) {
      return false;
    }

    final serieAnterior = obterSerieAnterior(atual.nome, index);
    if (serieAnterior == null ||
        (serieAnterior.peso == null && serieAnterior.reps == null)) {
      return false;
    }

    if (serieAnterior.peso != null) {
      atual.seriesDetalhes[index].peso = serieAnterior.peso;
    }
    if (serieAnterior.reps != null) {
      atual.seriesDetalhes[index].reps = serieAnterior.reps;
    }
    if (atual.seriesDetalhes[index].concluida) {
      _reavaliarRecordesExercicio(atual.nome, atual.grupo, atual.seriesDetalhes);
    }
    notifyListeners();
    return true;
  }

  void toggleConcluidaSerie(int index) {
    final atual = _sessaoTreino.exercicioAtual;
    if (atual == null || index < 0 || index >= atual.seriesDetalhes.length) {
      return;
    }

    final serie = atual.seriesDetalhes[index];
    final agoraConcluida = !serie.concluida;

    // Se estiver marcando como concluída e os campos estiverem vazios, preenche com os valores da série anterior
    if (agoraConcluida && (serie.peso == null || serie.reps == null)) {
      final serieAnterior = obterSerieAnterior(atual.nome, index);
      if (serieAnterior != null) {
        serie.peso ??= serieAnterior.peso;
        serie.reps ??= serieAnterior.reps;
      }
    }

    serie.concluida = agoraConcluida;
    _reavaliarRecordesExercicio(atual.nome, atual.grupo, atual.seriesDetalhes);

    if (agoraConcluida) {
      iniciarTimer();
      return;
    }

    notifyListeners();
  }

  /// Verifica se uma série do exercício atual supera a marca histórica anterior.
  bool isSerieRecorde(String nomeExercicio, int index) {
    final atual = _sessaoTreino.exercicioAtual;
    if (atual == null || atual.nome != nomeExercicio) return false;
    if (index < 0 || index >= atual.seriesDetalhes.length) return false;

    final serie = atual.seriesDetalhes[index];
    if (serie.isWarmup ||
        serie.peso == null ||
        serie.reps == null ||
        serie.peso! <= 0 ||
        serie.reps! <= 0) {
      return false;
    }

    final chave = nomeExercicio.toLowerCase().trim();
    final base = _recordesBaseCache[chave];
    if (base == null || (base.cargaMaxima <= 0 && base.umRepMaxEstimado <= 0)) {
      return false;
    }

    final p = serie.peso!;
    final r = serie.reps!;

    return base.supera(p, r);
  }

  void _reavaliarRecordesExercicio(
    String nomeExercicio,
    String grupo,
    List<Serie> series,
  ) {
    final chave = nomeExercicio.toLowerCase().trim();
    final base = _recordesBaseCache[chave];

    double melhorPeso = 0;
    int repsMelhorPeso = 0;
    double melhor1RM = 0;
    double pesoMelhor1RM = 0;
    int repsMelhor1RM = 0;
    bool bateuAlgum = false;

    for (final s in series) {
      if (!s.concluida ||
          s.isWarmup ||
          s.peso == null ||
          s.reps == null ||
          s.peso! <= 0 ||
          s.reps! <= 0) {
        continue;
      }

      final p = s.peso!;
      final r = s.reps!;
      final c1RM = RecordePessoal.calcular1RM(p, r);

      if (base != null && base.supera(p, r)) {
        bateuAlgum = true;
      }

      if (RecordePessoal.bateuCarga(
        peso: p,
        reps: r,
        baseCarga: melhorPeso,
        baseReps: repsMelhorPeso,
      )) {
        melhorPeso = p;
        repsMelhorPeso = r;
      }
      if (c1RM > melhor1RM) {
        melhor1RM = c1RM;
        pesoMelhor1RM = p;
        repsMelhor1RM = r;
      }
    }

    if (bateuAlgum) {
      _recordesBatidosHoje[nomeExercicio] = RecordePessoal(
        exercicioNome: nomeExercicio,
        grupo: grupo,
        cargaMaxima: melhorPeso,
        repsCargaMaxima: repsMelhorPeso,
        umRepMaxEstimado: melhor1RM,
        peso1RM: pesoMelhor1RM,
        reps1RM: repsMelhor1RM,
        dataRecorde: DateTime.now(),
      );
    } else {
      _recordesBatidosHoje.remove(nomeExercicio);
    }
  }

  void atualizarTempoDescanso(int tempoSelecionado) {
    if (tempoSelecionado <= 0) return;

    _acumularDescansoAtual();
    _tempoDescansoPadrao = tempoSelecionado;
    _atualizarTempoAtual(tempoSelecionado);
    _isTimerRodando = false;
    _timer?.cancel();
    _timerEndTime = null;
    unawaited(_notificationService.cancelarNotificacao());
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
        _atualizarTempoAtual(tempoSalvo);
      }
    }
    await ExercicioCustomMidiaService.instance.inicializar();
    await carregarExerciciosCustomizados();
    notifyListeners();
  }

  Future<void> carregarExerciciosCustomizados() async {
    try {
      final dbExercicios = await _repository
          .buscarExerciciosUnicosRegistrados();
      final prefsString = await _preferencesService.lerString(
        PreferencesService.keyExerciciosCustomizados,
      );
      final removidosString = await _preferencesService.lerString(
        PreferencesService.keyExerciciosCustomizadosRemovidos,
      );

      final Set<String> removidos = {};
      if (removidosString != null) {
        try {
          final List<dynamic> decodedRemovidos = jsonDecode(removidosString);
          for (final item in decodedRemovidos) {
            if (item is String && item.trim().isNotEmpty) {
              removidos.add(item.trim().toLowerCase());
            }
          }
        } catch (_) {}
      }

      List<Map<String, String>> prefsExercicios = [];
      if (prefsString != null) {
        try {
          final List<dynamic> decoded = jsonDecode(prefsString);
          prefsExercicios = decoded
              .map(
                (e) => {
                  'nome': (e['nome'] as String? ?? '').trim(),
                  'grupo': (e['grupo'] as String? ?? '').trim(),
                },
              )
              .toList();
        } catch (_) {}
      }

      final Map<String, Map<String, String>> merged = {};
      for (final ex in dbExercicios) {
        final nome = ex['nome'] ?? '';
        final grupo = ex['grupo'] ?? '';
        final chave = nome.toLowerCase().trim();
        if (nome.isNotEmpty && grupo.isNotEmpty && !removidos.contains(chave)) {
          merged[chave] = {
            'nome': nome.trim(),
            'grupo': grupo.trim(),
          };
        }
      }
      for (final ex in prefsExercicios) {
        final nome = ex['nome'] ?? '';
        final grupo = ex['grupo'] ?? '';
        final chave = nome.toLowerCase().trim();
        if (nome.isNotEmpty && grupo.isNotEmpty && !removidos.contains(chave)) {
          merged[chave] = {
            'nome': nome.trim(),
            'grupo': grupo.trim(),
          };
        }
      }

      _exerciciosCustomizados = merged.values.toList();
    } catch (_) {}
  }

  Future<void> _removerDaListaIgnorados(String nome) async {
    final chave = nome.trim().toLowerCase();
    if (chave.isEmpty) return;
    try {
      final removidosString = await _preferencesService.lerString(
        PreferencesService.keyExerciciosCustomizadosRemovidos,
      );
      if (removidosString == null) return;
      final List<dynamic> decoded = jsonDecode(removidosString);
      final atualizados = decoded
          .whereType<String>()
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty && e != chave)
          .toSet()
          .toList();
      await _preferencesService.salvarString(
        PreferencesService.keyExerciciosCustomizadosRemovidos,
        jsonEncode(atualizados),
      );
    } catch (_) {}
  }

  Future<void> _adicionarNaListaIgnorados(String nome) async {
    final chave = nome.trim().toLowerCase();
    if (chave.isEmpty) return;
    try {
      final removidosString = await _preferencesService.lerString(
        PreferencesService.keyExerciciosCustomizadosRemovidos,
      );
      final Set<String> removidos = {};
      if (removidosString != null) {
        try {
          final List<dynamic> decoded = jsonDecode(removidosString);
          for (final item in decoded) {
            if (item is String && item.trim().isNotEmpty) {
              removidos.add(item.trim().toLowerCase());
            }
          }
        } catch (_) {}
      }
      removidos.add(chave);
      await _preferencesService.salvarString(
        PreferencesService.keyExerciciosCustomizadosRemovidos,
        jsonEncode(removidos.toList()),
      );
    } catch (_) {}
  }

  Future<void> salvarNovoExercicioCustomizado(String nome, String grupo) async {
    final nomeTrimmed = nome.trim();
    final grupoTrimmed = grupo.trim();
    if (nomeTrimmed.isEmpty || grupoTrimmed.isEmpty) return;

    await _removerDaListaIgnorados(nomeTrimmed);

    final existe = _exerciciosCustomizados.any(
      (e) => e['nome']!.toLowerCase() == nomeTrimmed.toLowerCase(),
    );

    if (!existe) {
      _exerciciosCustomizados.add({'nome': nomeTrimmed, 'grupo': grupoTrimmed});

      try {
        await _preferencesService.salvarString(
          PreferencesService.keyExerciciosCustomizados,
          jsonEncode(_exerciciosCustomizados),
        );
      } catch (_) {}
      notifyListeners();
    }
  }

  /// Edita o nome e/ou grupo muscular de um exercício personalizado,
  /// atualizando também todas as fichas e registros históricos existentes.
  Future<void> editarExercicioCustomizado({
    required String nomeAntigo,
    required String novoNome,
    required String novoGrupo,
  }) async {
    final antigoTrim = nomeAntigo.trim();
    final novoTrim = novoNome.trim();
    final grupoTrim = novoGrupo.trim();
    if (antigoTrim.isEmpty || novoTrim.isEmpty || grupoTrim.isEmpty) return;

    await _removerDaListaIgnorados(novoTrim);
    if (antigoTrim.toLowerCase() != novoTrim.toLowerCase()) {
      await _adicionarNaListaIgnorados(antigoTrim);
      await ExercicioCustomMidiaService.instance.renomearExercicio(
        antigoTrim,
        novoTrim,
      );
    }

    await _repository.fundirExercicio(
      nomeOrigem: antigoTrim,
      nomeDestino: novoTrim,
      grupoDestino: grupoTrim,
    );

    try {
      final prefsString = await _preferencesService.lerString(
        PreferencesService.keyExerciciosCustomizados,
      );
      List<Map<String, String>> listaPrefs = [];
      if (prefsString != null) {
        try {
          final List<dynamic> decoded = jsonDecode(prefsString);
          listaPrefs = decoded
              .map(
                (e) => {
                  'nome': (e['nome'] as String? ?? '').trim(),
                  'grupo': (e['grupo'] as String? ?? '').trim(),
                },
              )
              .where(
                (e) =>
                    e['nome']!.isNotEmpty &&
                    e['nome']!.toLowerCase() != antigoTrim.toLowerCase() &&
                    e['nome']!.toLowerCase() != novoTrim.toLowerCase(),
              )
              .toList();
        } catch (_) {}
      }
      listaPrefs.add({'nome': novoTrim, 'grupo': grupoTrim});
      await _preferencesService.salvarString(
        PreferencesService.keyExerciciosCustomizados,
        jsonEncode(listaPrefs),
      );
    } catch (_) {}

    final chaveAntiga = antigoTrim.toLowerCase();
    final atual = _sessaoTreino.exercicioAtual;
    if (atual != null && atual.nome.trim().toLowerCase() == chaveAntiga) {
      _sessaoTreino.exercicioAtual = atual.copyWith(
        nome: novoTrim,
        grupo: grupoTrim,
      );
    }

    for (int i = 0; i < _sessaoTreino.exerciciosConcluidosHoje.length; i++) {
      final ex = _sessaoTreino.exerciciosConcluidosHoje[i];
      if (ex.nome.trim().toLowerCase() == chaveAntiga) {
        _sessaoTreino.exerciciosConcluidosHoje[i] = ex.copyWith(
          nome: novoTrim,
          grupo: grupoTrim,
        );
      }
    }

    for (int i = 0; i < _exerciciosFichaPendentes.length; i++) {
      final pendente = _exerciciosFichaPendentes[i];
      if (pendente.nome.trim().toLowerCase() == chaveAntiga) {
        _exerciciosFichaPendentes[i] = pendente.copyWith(
          nome: novoTrim,
          grupo: grupoTrim,
        );
      }
    }

    _ultimasSeriesCache.remove(chaveAntiga);
    _recordesBaseCache.remove(chaveAntiga);

    await carregarExerciciosCustomizados();
    await carregarFichas();
    await carregarSeriesAnteriores(novoTrim);
    notifyListeners();
  }

  /// Exclui um exercício personalizado da lista de seleção e das fichas
  /// (e opcionalmente do histórico de treinos se [removerHistorico] for true).
  Future<void> excluirExercicioCustomizado(
    String nome, {
    bool removerHistorico = false,
  }) async {
    final nomeTrim = nome.trim();
    if (nomeTrim.isEmpty) return;
    final chave = nomeTrim.toLowerCase();

    await _adicionarNaListaIgnorados(nomeTrim);
    await ExercicioCustomMidiaService.instance.removerMidia(nomeTrim);
    await _repository.excluirExercicioCustomizado(
      nomeTrim,
      removerHistorico: removerHistorico,
    );

    try {
      final prefsString = await _preferencesService.lerString(
        PreferencesService.keyExerciciosCustomizados,
      );
      if (prefsString != null) {
        final List<dynamic> decoded = jsonDecode(prefsString);
        final atualizados = decoded
            .map(
              (e) => {
                'nome': (e['nome'] as String? ?? '').trim(),
                'grupo': (e['grupo'] as String? ?? '').trim(),
              },
            )
            .where((e) => e['nome']!.toLowerCase() != chave)
            .toList();
        await _preferencesService.salvarString(
          PreferencesService.keyExerciciosCustomizados,
          jsonEncode(atualizados),
        );
      }
    } catch (_) {}

    _exerciciosCustomizados.removeWhere(
      (e) => (e['nome'] ?? '').trim().toLowerCase() == chave,
    );
    _exerciciosFichaPendentes.removeWhere(
      (p) => p.nome.trim().toLowerCase() == chave,
    );
    _ultimasSeriesCache.remove(chave);
    _recordesBaseCache.remove(chave);

    await carregarExerciciosCustomizados();
    await carregarFichas();
    notifyListeners();
  }

  /// Funde/associa um exercício criado previamente ([nomeOrigem]) a um exercício alvo ([nomeDestino] e [grupoDestino]),
  /// preservando todo o histórico de séries, recordes e fichas.
  Future<int> fundirExercicio({
    required String nomeOrigem,
    required String nomeDestino,
    required String grupoDestino,
  }) async {
    final origemTrim = nomeOrigem.trim();
    final destinoTrim = nomeDestino.trim();
    final grupoTrim = grupoDestino.trim();
    if (origemTrim.isEmpty || destinoTrim.isEmpty || grupoTrim.isEmpty) {
      return 0;
    }

    final chaveOrigem = origemTrim.toLowerCase();

    final registrosAfetados = await _repository.fundirExercicio(
      nomeOrigem: origemTrim,
      nomeDestino: destinoTrim,
      grupoDestino: grupoTrim,
    );

    // Atualiza lista de exercícios customizados salva nas preferências
    try {
      final prefsString = await _preferencesService.lerString(
        PreferencesService.keyExerciciosCustomizados,
      );
      if (prefsString != null) {
        final List<dynamic> decoded = jsonDecode(prefsString);
        final atualizados = decoded
            .map(
              (e) => {
                'nome': (e['nome'] as String? ?? '').trim(),
                'grupo': (e['grupo'] as String? ?? '').trim(),
              },
            )
            .where((e) => e['nome']!.toLowerCase() != chaveOrigem)
            .toList();
        await _preferencesService.salvarString(
          PreferencesService.keyExerciciosCustomizados,
          jsonEncode(atualizados),
        );
      }
    } catch (_) {}

    // Atualiza estado da sessão ativa caso o exercício esteja em andamento, concluído hoje ou na fila
    final atual = _sessaoTreino.exercicioAtual;
    if (atual != null && atual.nome.trim().toLowerCase() == chaveOrigem) {
      _sessaoTreino.exercicioAtual = atual.copyWith(
        nome: destinoTrim,
        grupo: grupoTrim,
      );
    }

    for (int i = 0; i < _sessaoTreino.exerciciosConcluidosHoje.length; i++) {
      final ex = _sessaoTreino.exerciciosConcluidosHoje[i];
      if (ex.nome.trim().toLowerCase() == chaveOrigem) {
        _sessaoTreino.exerciciosConcluidosHoje[i] = ex.copyWith(
          nome: destinoTrim,
          grupo: grupoTrim,
        );
      }
    }

    for (int i = 0; i < _exerciciosFichaPendentes.length; i++) {
      final pendente = _exerciciosFichaPendentes[i];
      if (pendente.nome.trim().toLowerCase() == chaveOrigem) {
        _exerciciosFichaPendentes[i] = pendente.copyWith(
          nome: destinoTrim,
          grupo: grupoTrim,
        );
      }
    }

    _ultimasSeriesCache.remove(chaveOrigem);
    _recordesBaseCache.remove(chaveOrigem);

    await carregarExerciciosCustomizados();
    await carregarFichas();
    await carregarSeriesAnteriores(destinoTrim);

    notifyListeners();
    return registrosAfetados;
  }

  void _acumularDescansoAtual() {
    if (_isTimerRodando && _inicioDescansoAtual != null) {
      final agora = DateTime.now();
      final fim = (_timerEndTime != null && agora.isAfter(_timerEndTime!))
          ? _timerEndTime!
          : agora;
      final decorridoMs = fim.difference(_inicioDescansoAtual!).inMilliseconds;
      final decorrido = (decorridoMs / 1000.0).round();
      if (decorrido > 0) {
        _descansoTotalSegundos += decorrido;
      }
      _inicioDescansoAtual = null;
    }
  }

  void iniciarTimer() {
    _acumularDescansoAtual();
    final agora = DateTime.now();
    _atualizarTempoAtual(_tempoDescansoPadrao);
    _timerEndTime = agora.add(Duration(seconds: _tempoAtual));
    _inicioDescansoAtual = agora;
    _isTimerRodando = true;
    unawaited(_notificationService.agendarNotificacaoDescanso(_tempoAtual));
    notifyListeners();
    _iniciarTicker();
  }

  void pausarTimer() {
    _acumularDescansoAtual();
    if (_timerEndTime != null) {
      final diffMs = _timerEndTime!.difference(DateTime.now()).inMilliseconds;
      final restante = (diffMs / 1000.0).ceil();
      _atualizarTempoAtual(restante > 0 ? restante : 0);
    }
    _timer?.cancel();
    _timerEndTime = null;
    _isTimerRodando = false;
    unawaited(_notificationService.cancelarNotificacao());
    notifyListeners();
  }

  void continuarTimer() {
    if (_isTimerRodando) return;

    if (_tempoAtual <= 0) {
      _atualizarTempoAtual(_tempoDescansoPadrao);
    }
    final agora = DateTime.now();
    _timerEndTime = agora.add(Duration(seconds: _tempoAtual));
    _inicioDescansoAtual = agora;
    _isTimerRodando = true;
    unawaited(_notificationService.agendarNotificacaoDescanso(_tempoAtual));
    notifyListeners();
    _iniciarTicker();
  }

  void reiniciarTimer() {
    _acumularDescansoAtual();
    _timer?.cancel();
    _timerEndTime = null;
    _atualizarTempoAtual(_tempoDescansoPadrao);
    _isTimerRodando = false;
    unawaited(_notificationService.cancelarNotificacao());
    notifyListeners();
  }

  void _iniciarTicker() {
    _timer?.cancel();
    tempoDescansoNotifier.value = _tempoAtual;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timerEndTime != null) {
        final diffMs = _timerEndTime!.difference(DateTime.now()).inMilliseconds;
        final remaining = (diffMs / 1000.0).ceil();
        if (remaining > 0) {
          _atualizarTempoAtual(remaining);
        } else {
          _timer?.cancel();
          _acumularDescansoAtual();
          _isTimerRodando = false;
          _timerEndTime = null;
          _atualizarTempoAtual(0);
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
      if (_inicioTreino != null && !_treinoPausado) {
        duracaoTreinoNotifier.value = duracaoTreinoSegundos;
        if (_sessaoTimer == null || !_sessaoTimer!.isActive) {
          _iniciarTickerSessao();
        }
      }

      if (_isTimerRodando && _timerEndTime != null) {
        final diffMs = _timerEndTime!.difference(DateTime.now()).inMilliseconds;
        final remaining = (diffMs / 1000.0).ceil();
        if (remaining > 0) {
          _atualizarTempoAtual(remaining);
          if (_timer == null || !_timer!.isActive) {
            _iniciarTicker();
          }
        } else {
          _timer?.cancel();
          _acumularDescansoAtual();
          _isTimerRodando = false;
          _timerEndTime = null;
          _atualizarTempoAtual(0);
          _descansoFinalizadoEvento++;
        }
      }

      notifyListeners();
    }
  }

  @visibleForTesting
  void setInicioTreinoParaTeste(DateTime inicio) {
    _inicioTreino = inicio;
  }

  @visibleForTesting
  void setInicioPausaAtualParaTeste(DateTime? inicioPausa) {
    _inicioPausaAtual = inicioPausa;
  }

  @visibleForTesting
  void setTempoPausadoTotalParaTeste(Duration duracao) {
    _tempoPausadoTotal = duracao;
  }

  @visibleForTesting
  void setInicioDescansoParaTeste(DateTime? inicio, {DateTime? endTime}) {
    _inicioDescansoAtual = inicio;
    if (endTime != null) {
      _timerEndTime = endTime;
    }
  }

  bool _disposed = false;

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _sessaoTimer?.cancel();
    duracaoTreinoNotifier.dispose();
    tempoDescansoNotifier.dispose();
    super.dispose();
  }
}
