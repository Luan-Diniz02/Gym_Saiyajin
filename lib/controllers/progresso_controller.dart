import 'dart:collection';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';

import '../models/exercicio.dart';
import '../models/poder_luta.dart';
import '../models/recorde_pessoal.dart';
import '../models/serie.dart';
import '../models/sessao_treino.dart';
import '../repositories/treino_repository.dart';
import '../services/preferences_service.dart';

enum PeriodoGrafico {
  ultimos10('ÚLTIMOS 10'),
  tresMeses('3 MESES'),
  tudo('TUDO');

  final String label;
  const PeriodoGrafico(this.label);
}

enum PeriodoMapaMuscular {
  seteDias(7, '7 DIAS'),
  trintaDias(30, '30 DIAS');

  final int dias;
  final String label;
  const PeriodoMapaMuscular(this.dias, this.label);
}

enum NivelAtivacaoMuscular {
  inativo('SEM ESTÍMULO'),
  manutencao('ATIVADO'),
  ideal('ZONA IDEAL'),
  altaDemanda('SOBRECARGA');

  final String label;
  const NivelAtivacaoMuscular(this.label);
}

class TelemetriaMuscular {
  final String grupo;
  final int seriesValidas;
  final double volumeTotalKg;
  final double maior1RM;
  final NivelAtivacaoMuscular nivel;
  final double intensidadeNormalizada;

  const TelemetriaMuscular({
    required this.grupo,
    required this.seriesValidas,
    required this.volumeTotalKg,
    required this.maior1RM,
    required this.nivel,
    required this.intensidadeNormalizada,
  });
}

class ProgressoController extends ChangeNotifier {
  final TreinoRepository _repository;
  final PreferencesService _preferencesService;

  ProgressoController({
    required TreinoRepository repository,
    required PreferencesService preferencesService,
  }) : _repository = repository,
       _preferencesService = preferencesService;

  double _pesoAtual = 69.0;
  double _altura = 1.70;
  double? _percentualGordura;
  int _diasTreinadosNaSemana = 0;
  int _metaDiasSemana = 3;
  DateTime? _dataUltimaAtualizacaoPeso;

  double? get percentualGordura => _percentualGordura;

  String? get classificacaoGordura {
    final bf = _percentualGordura;
    if (bf == null) return null;
    if (bf < 10.0) return 'MUITO DEFINIDO';
    if (bf < 15.0) return 'FÍSICO ATLÉTICO';
    if (bf < 20.0) return 'MODERADO';
    if (bf < 25.0) return 'ELEVADO';
    return 'ALTO';
  }

  PoderLuta _poderLuta = PoderLuta.zero();
  PoderLuta get poderLuta => _poderLuta;

  List<RecordePessoal> _recordesPessoais = [];
  List<RecordePessoal> get recordesPessoais =>
      UnmodifiableListView(_recordesPessoais);
  int get totalRecordes => _recordesPessoais.length;

  String _exercicioFiltro = 'Nenhum exercício';
  PeriodoGrafico _periodoGrafico = PeriodoGrafico.tudo;
  PeriodoMapaMuscular _periodoMapaMuscular = PeriodoMapaMuscular.seteDias;
  String? _grupoMuscularSelecionado;
  final List<String> _exerciciosDisponiveis = ['Nenhum exercício'];
  final List<FlSpot> _pontosDoGraficoFiltrado = [];
  final List<String> _datasDoGrafico = [];
  final List<String> _datasCompletasDoGrafico = [];
  final List<int?> _repsDoGrafico = [];
  List<SessaoTreino> _historicoCache = [];

  double get pesoAtual => _pesoAtual;
  double get altura => _altura;
  int get diasTreinadosNaSemana => _diasTreinadosNaSemana;
  int get metaDiasSemana => _metaDiasSemana;
  PeriodoGrafico get periodoGrafico => _periodoGrafico;
  PeriodoMapaMuscular get periodoMapaMuscular => _periodoMapaMuscular;
  String? get grupoMuscularSelecionado => _grupoMuscularSelecionado;

  static const List<String> gruposMuscularesCanonicos = [
    'PEITO',
    'COSTAS',
    'PERNAS',
    'OMBROS',
    'BÍCEPS',
    'TRÍCEPS',
    'ABDÔMEN',
  ];

  /// Normaliza o nome de qualquer grupo muscular para uma das 7 chaves canônicas.
  static String normalizarGrupoMuscular(String grupoRaw) {
    final g = grupoRaw
        .trim()
        .toUpperCase()
        .replaceAll('Í', 'I')
        .replaceAll('Ú', 'U')
        .replaceAll('Á', 'A')
        .replaceAll('Ç', 'C')
        .replaceAll('Ô', 'O')
        .replaceAll('Ã', 'A')
        .replaceAll('É', 'E');

    if (g.contains('PEITO') || g.contains('PEITORAL')) return 'PEITO';
    if (g.contains('COSTA') || g.contains('DORSAL') || g.contains('LOMBAR')) {
      return 'COSTAS';
    }
    if (g.contains('PERNA') ||
        g.contains('QUADRICEPS') ||
        g.contains('GLUTE') ||
        g.contains('POSTERIOR') ||
        g.contains('PANTURRILHA') ||
        g.contains('COXA')) {
      return 'PERNAS';
    }
    if (g.contains('OMBRO') || g.contains('DELTOIDE') || g.contains('TRAPEZIO')) {
      return 'OMBROS';
    }
    if (g.contains('BICEPS') || g.contains('ANTEBRACO')) return 'BÍCEPS';
    if (g.contains('TRICEPS')) return 'TRÍCEPS';
    if (g.contains('ABDOM') || g.contains('CORE')) return 'ABDÔMEN';
    return grupoRaw.trim().toUpperCase();
  }

  void mudarPeriodoMapaMuscular(PeriodoMapaMuscular novoPeriodo) {
    if (_periodoMapaMuscular == novoPeriodo) return;
    _periodoMapaMuscular = novoPeriodo;
    notifyListeners();
  }

  void selecionarGrupoMapaMuscular(String? grupo) {
    if (_grupoMuscularSelecionado == grupo) {
      _grupoMuscularSelecionado = null;
    } else {
      _grupoMuscularSelecionado = grupo;
    }
    notifyListeners();
  }

  /// Calcula a telemetria anatômica de séries válidas (excluindo aquecimentos)
  /// por grupo muscular dentro da janela temporal selecionada.
  Map<String, TelemetriaMuscular> calcularTelemetriaMuscular({
    int? dias,
    DateTime? dataReferencia,
  }) {
    final janelaDias = dias ?? _periodoMapaMuscular.dias;
    final ref = dataReferencia ?? DateTime.now();
    final hojeFim = DateTime(ref.year, ref.month, ref.day, 23, 59, 59);
    final dataInicio = DateTime(ref.year, ref.month, ref.day)
        .subtract(Duration(days: janelaDias - 1));

    final Map<String, int> contagemSeries = {
      for (final g in gruposMuscularesCanonicos) g: 0,
    };
    final Map<String, double> somaVolume = {
      for (final g in gruposMuscularesCanonicos) g: 0.0,
    };

    for (final sessao in _historicoCache) {
      final d = sessao.data;
      if (d == null) continue;
      if (d.isBefore(dataInicio) || d.isAfter(hojeFim)) continue;

      for (final ex in sessao.exerciciosConcluidosHoje) {
        final grupoKey = normalizarGrupoMuscular(ex.grupo);
        if (!contagemSeries.containsKey(grupoKey)) continue;

        for (final s in ex.seriesDetalhes) {
          // Séries de aquecimento (warmup) não contam como séries válidas de trabalho
          if (!s.concluida || s.isWarmup) continue;
          final reps = s.reps ?? 0;
          final peso = s.peso ?? 0.0;
          if (reps <= 0) continue;

          contagemSeries[grupoKey] = (contagemSeries[grupoKey] ?? 0) + 1;
          if (peso > 0) {
            somaVolume[grupoKey] = (somaVolume[grupoKey] ?? 0.0) + (peso * reps);
          }
        }
      }
    }

    // Escala de referência proporcional à janela (1x para 7 dias, 4x para 30 dias)
    final int fatorEscala = janelaDias >= 28 ? 4 : 1;
    final int limiarIdeal = 6 * fatorEscala;
    final int limiarSobrecarga = 13 * fatorEscala;
    final int tetoVisual = 16 * fatorEscala;

    final Map<String, TelemetriaMuscular> resultado = {};
    for (final grupo in gruposMuscularesCanonicos) {
      final int series = contagemSeries[grupo] ?? 0;
      final double volume = somaVolume[grupo] ?? 0.0;
      final double max1RM = _poderLuta.maiores1RMPorGrupo[grupo] ?? 0.0;

      NivelAtivacaoMuscular nivel;
      if (series <= 0) {
        nivel = NivelAtivacaoMuscular.inativo;
      } else if (series < limiarIdeal) {
        nivel = NivelAtivacaoMuscular.manutencao;
      } else if (series < limiarSobrecarga) {
        nivel = NivelAtivacaoMuscular.ideal;
      } else {
        nivel = NivelAtivacaoMuscular.altaDemanda;
      }

      final double intensidade =
          series <= 0 ? 0.0 : (series / tetoVisual).clamp(0.15, 1.0);

      resultado[grupo] = TelemetriaMuscular(
        grupo: grupo,
        seriesValidas: series,
        volumeTotalKg: volume,
        maior1RM: max1RM,
        nivel: nivel,
        intensidadeNormalizada: intensidade,
      );
    }

    return resultado;
  }

  /// Retorna a lista de grupos musculares negligenciados (0 séries no período)
  /// para alertar o atleta sobre pontos fracos na armadura.
  List<String> obterPontosFracosMusculares({
    Map<String, TelemetriaMuscular>? telemetria,
  }) {
    final mapa = telemetria ?? calcularTelemetriaMuscular();
    final temAlgumTreino = mapa.values.any((t) => t.seriesValidas > 0);
    if (!temAlgumTreino) return const [];
    return mapa.values
        .where((t) => t.seriesValidas == 0)
        .map((t) => t.grupo)
        .toList();
  }

  String get dataUltimaAtualizacaoFormatada {
    final data = _dataUltimaAtualizacaoPeso;
    if (data == null) return '--';

    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final dataSemHorario = DateTime(data.year, data.month, data.day);
    if (dataSemHorario == hoje) {
      return 'Hoje';
    }

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();
    return '$dia/$mes/$ano';
  }

  String get exercicioFiltro => _exercicioFiltro;
  List<String> get exerciciosDisponiveis =>
      UnmodifiableListView(_exerciciosDisponiveis);
  List<String> get datasDoGrafico => UnmodifiableListView(_datasDoGrafico);
  List<String> get datasCompletasDoGrafico =>
      UnmodifiableListView(_datasCompletasDoGrafico);
  List<int?> get repsDoGrafico => UnmodifiableListView(_repsDoGrafico);

  List<FlSpot> get pontosDoGraficoFiltrado =>
      UnmodifiableListView(_pontosDoGraficoFiltrado);

  /// Calcula até [maxLabels] índices espaçados uniformemente no eixo X,
  /// garantindo sempre o primeiro (0) e o último (total - 1) ponto.
  static Set<int> calcularIndicesVisiveisEixoX(
    int totalPontos, {
    int maxLabels = 5,
  }) {
    if (totalPontos <= 0) return const {};
    if (totalPontos <= maxLabels) {
      return Set<int>.from(List<int>.generate(totalPontos, (i) => i));
    }
    final Set<int> indices = {};
    for (int k = 0; k < maxLabels; k++) {
      final idx = ((k * (totalPontos - 1)) / (maxLabels - 1)).round();
      indices.add(idx);
    }
    return indices;
  }

  double calcularIMC() => _pesoAtual / (_altura * _altura);

  double get imc => calcularIMC();

  String get classificacaoImc {
    final valorImc = imc;
    if (valorImc < 18.5) return 'ABAIXO DO PESO';
    if (valorImc < 25.0) return 'PESO NORMAL';
    if (valorImc < 30.0) return 'SOBREPESO';
    if (valorImc < 35.0) return 'OBESIDADE GRAU I';
    if (valorImc < 40.0) return 'OBESIDADE GRAU II';
    return 'OBESIDADE GRAU III';
  }

  Future<void> carregarDados() async {
    await _carregarPreferencias();

    final historico = await _repository.buscarHistoricoTreinos();
    _historicoCache = historico;

    _calcularDiasAtivos(historico);
    _atualizarListaExercicios(historico);
    _recalcularDadosGrafico();

    _recordesPessoais = await _repository.buscarRecordesPessoais();
    _poderLuta = PoderLuta.calcular(
      recordes: _recordesPessoais,
      historico: _historicoCache,
    );

    notifyListeners();
  }

  void _calcularDiasAtivos(List<SessaoTreino> historico) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);

    // Obtém o domingo da semana atual
    final diasDesdeDomingo = hoje.weekday % 7;
    final inicioSemana = hoje.subtract(Duration(days: diasDesdeDomingo));

    final Set<String> diasUnicos = {};
    for (final sessao in historico) {
      final data = sessao.data;
      if (data == null) continue;

      final diaSessao = DateTime(data.year, data.month, data.day);
      if (diaSessao.isBefore(inicioSemana) || diaSessao.isAfter(hoje)) continue;

      diasUnicos.add('${diaSessao.year}-${diaSessao.month}-${diaSessao.day}');
    }

    _diasTreinadosNaSemana = diasUnicos.length;
  }

  final Map<String, String> _gruposExercicios = {};
  Map<String, String> get gruposExercicios => _gruposExercicios;

  void _atualizarListaExercicios(List<SessaoTreino> historico) {
    final Set<String> unicos = {};
    _gruposExercicios.clear();
    for (final sessao in historico) {
      for (final exercicio in sessao.exerciciosConcluidosHoje) {
        final nome = exercicio.nome.trim();
        if (nome.isNotEmpty) {
          unicos.add(nome);
          if (exercicio.grupo.trim().isNotEmpty) {
            _gruposExercicios[nome] = exercicio.grupo.trim();
          }
        }
      }
    }

    _exerciciosDisponiveis
      ..clear()
      ..addAll(
        unicos.isEmpty ? ['Nenhum exercício'] : unicos.toList()
          ..sort(),
      );

    if (!_exerciciosDisponiveis.contains(_exercicioFiltro)) {
      _exercicioFiltro = _exerciciosDisponiveis.first;
    }
  }

  void _recalcularDadosGrafico() {
    if (_exercicioFiltro == 'Nenhum exercício') {
      _pontosDoGraficoFiltrado.clear();
      _datasDoGrafico.clear();
      _datasCompletasDoGrafico.clear();
      _repsDoGrafico.clear();
      return;
    }

    final sessoesComExercicio =
        _historicoCache
            .where(
              (sessao) => sessao.exerciciosConcluidosHoje.any(
                (ex) => ex.nome == _exercicioFiltro,
              ),
            )
            .toList()
          ..sort((a, b) {
            final dataA = a.data;
            final dataB = b.data;
            if (dataA == null && dataB == null) {
              return (a.id ?? 0).compareTo(b.id ?? 0);
            }
            if (dataA == null) return -1;
            if (dataB == null) return 1;
            return dataA.compareTo(dataB);
          });

    final List<({double peso, int? reps, DateTime? data})> registrosValidos = [];

    for (final sessao in sessoesComExercicio) {
      final melhorSerie = _buscarMelhorSerie(
        sessao.exerciciosConcluidosHoje,
        _exercicioFiltro,
      );
      if (melhorSerie == null) continue;
      registrosValidos.add((
        peso: melhorSerie.$1,
        reps: melhorSerie.$2,
        data: sessao.data,
      ));
    }

    // Aplica filtro de período selecionado
    List<({double peso, int? reps, DateTime? data})> registrosRecortados;
    switch (_periodoGrafico) {
      case PeriodoGrafico.ultimos10:
        if (registrosValidos.length > 10) {
          registrosRecortados = registrosValidos.sublist(
            registrosValidos.length - 10,
          );
        } else {
          registrosRecortados = registrosValidos;
        }
      case PeriodoGrafico.tresMeses:
        final dataReferencia =
            registrosValidos.lastOrNull?.data ?? DateTime.now();
        final dataCorte = dataReferencia.subtract(const Duration(days: 90));
        final filtrados90d = registrosValidos
            .where((r) => r.data == null || !r.data!.isBefore(dataCorte))
            .toList();
        // Caso o usuário tenha menos de 2 registros nos últimos 3 meses, exibe os últimos disponíveis (até 10)
        if (filtrados90d.length < 2 && registrosValidos.length >= 2) {
          registrosRecortados = registrosValidos.length > 10
              ? registrosValidos.sublist(registrosValidos.length - 10)
              : registrosValidos;
        } else {
          registrosRecortados = filtrados90d;
        }
      case PeriodoGrafico.tudo:
        registrosRecortados = registrosValidos;
    }

    _pontosDoGraficoFiltrado.clear();
    _datasDoGrafico.clear();
    _datasCompletasDoGrafico.clear();
    _repsDoGrafico.clear();

    for (int i = 0; i < registrosRecortados.length; i++) {
      final item = registrosRecortados[i];
      _pontosDoGraficoFiltrado.add(FlSpot(i.toDouble(), item.peso));
      _repsDoGrafico.add(item.reps);

      final data = item.data;
      if (data == null) {
        _datasDoGrafico.add('--/--');
        _datasCompletasDoGrafico.add('--/--/----');
      } else {
        final dia = data.day.toString().padLeft(2, '0');
        final mes = data.month.toString().padLeft(2, '0');
        final ano = data.year.toString();
        _datasDoGrafico.add('$dia/$mes');
        _datasCompletasDoGrafico.add('$dia/$mes/$ano');
      }
    }
  }

  (double, int?)? _buscarMelhorSerie(
    List<Exercicio> exercicios,
    String nomeExercicio,
  ) {
    final Iterable<Serie> series = exercicios
        .where((exercicio) => exercicio.nome == nomeExercicio)
        .expand((exercicio) => exercicio.seriesDetalhes);

    double? maximo;
    int? melhReps;
    for (final serie in series) {
      if (serie.isWarmup) continue;
      final peso = serie.peso;
      if (peso == null) continue;
      if (maximo == null ||
          peso > maximo ||
          (peso == maximo && (serie.reps ?? 0) > (melhReps ?? 0))) {
        maximo = peso;
        melhReps = serie.reps;
      }
    }
    if (maximo == null) return null;
    return (maximo, melhReps);
  }

  void mudarPeriodoGrafico(PeriodoGrafico novoPeriodo) {
    if (_periodoGrafico == novoPeriodo) return;
    _periodoGrafico = novoPeriodo;
    _recalcularDadosGrafico();
    notifyListeners();
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

  void atualizarMedidas({
    required double peso,
    required double altura,
    double? percentualGordura,
  }) {
    _pesoAtual = peso;
    _altura = altura;
    _percentualGordura = percentualGordura;
    _dataUltimaAtualizacaoPeso = DateTime.now();
    _salvarPreferencias();
    notifyListeners();
  }

  void atualizarMetaDiasSemana(int novaMeta) {
    if (novaMeta < 1 || novaMeta > 7) return;
    _metaDiasSemana = novaMeta;
    _salvarPreferencias();
    notifyListeners();
  }

  Future<void> _salvarPreferencias() async {
    await _preferencesService.salvarDouble(
      PreferencesService.keyPesoAtual,
      _pesoAtual,
    );
    await _preferencesService.salvarDouble(
      PreferencesService.keyAltura,
      _altura,
    );
    await _preferencesService.salvarInt(
      PreferencesService.keyMetaDiasSemana,
      _metaDiasSemana,
    );

    final gordura = _percentualGordura;
    if (gordura != null) {
      await _preferencesService.salvarDouble(
        PreferencesService.keyPercentualGordura,
        gordura,
      );
    } else {
      await _preferencesService.remover(
        PreferencesService.keyPercentualGordura,
      );
    }

    final data = _dataUltimaAtualizacaoPeso;
    if (data != null) {
      await _preferencesService.salvarString(
        PreferencesService.keyDataUltimaAtualizacaoPeso,
        data.toIso8601String(),
      );
    } else {
      await _preferencesService.remover(
        PreferencesService.keyDataUltimaAtualizacaoPeso,
      );
    }
  }

  Future<void> _carregarPreferencias() async {
    final pesoSalvo = await _preferencesService.lerDouble(
      PreferencesService.keyPesoAtual,
    );
    if (pesoSalvo != null) {
      _pesoAtual = pesoSalvo;
    }

    final alturaSalva = await _preferencesService.lerDouble(
      PreferencesService.keyAltura,
    );
    if (alturaSalva != null) {
      _altura = alturaSalva;
    }

    final gorduraSalva = await _preferencesService.lerDouble(
      PreferencesService.keyPercentualGordura,
    );
    _percentualGordura = gorduraSalva;

    final metaSalva = await _preferencesService.lerInt(
      PreferencesService.keyMetaDiasSemana,
    );
    if (metaSalva != null) {
      _metaDiasSemana = metaSalva;
    }

    final dataSalva = await _preferencesService.lerString(
      PreferencesService.keyDataUltimaAtualizacaoPeso,
    );
    _dataUltimaAtualizacaoPeso = (dataSalva != null && dataSalva.isNotEmpty)
        ? DateTime.tryParse(dataSalva)
        : null;

    notifyListeners();
  }

  /// Calcula quantos recordes pessoais (PRs) foram superados em uma sessão específica,
  /// reconstituindo cronologicamente o histórico até o momento daquela sessão.
  int obterPRsDaSessao(SessaoTreino sessaoAlvo) {
    return obterMapaPRsDaSessao(sessaoAlvo).length;
  }

  /// Retorna um mapa associando o nome normalizado (lowercase/trimmed) de cada
  /// exercício que bateu PR na [sessaoAlvo] ao índice (`0-based`) da série ápice
  /// que conquistou aquele recorde (Opção A).
  Map<String, int> obterMapaPRsDaSessao(SessaoTreino sessaoAlvo) {
    final poolSessoes = List<SessaoTreino>.from(_historicoCache);
    final jaContem = poolSessoes.any(
      (s) =>
          (sessaoAlvo.id != null && s.id == sessaoAlvo.id) ||
          (sessaoAlvo.data != null &&
              s.data != null &&
              s.data!.isAtSameMomentAs(sessaoAlvo.data!)),
    );
    if (!jaContem) {
      poolSessoes.add(sessaoAlvo);
    }

    if (poolSessoes.isEmpty) return const {};

    // Ordena o histórico cronologicamente crescente
    poolSessoes.sort((a, b) {
      final dataA = a.data ?? DateTime(1970);
      final dataB = b.data ?? DateTime(1970);
      final comp = dataA.compareTo(dataB);
      if (comp != 0) return comp;
      return (a.id ?? 0).compareTo(b.id ?? 0);
    });

    final Map<String, (double maxPeso, int repsMaxPeso, double max1RM)>
    recordesPrevios = {};

    for (final sessao in poolSessoes) {
      final isSessaoAlvo =
          (sessaoAlvo.id != null && sessao.id == sessaoAlvo.id) ||
          (sessao.data != null &&
              sessaoAlvo.data != null &&
              sessao.data!.isAtSameMomentAs(sessaoAlvo.data!));

      if (isSessaoAlvo) {
        final Map<String, int> mapaPRs = {};

        for (final ex in sessaoAlvo.exerciciosConcluidosHoje) {
          final chave = ex.nome.trim().toLowerCase();
          final previo = recordesPrevios[chave];

          if (previo != null) {
            int? indiceSerieApice;
            double apicePeso = 0.0;
            int apiceReps = 0;
            double apice1RM = 0.0;

            for (int i = 0; i < ex.seriesDetalhes.length; i++) {
              final s = ex.seriesDetalhes[i];
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

              if (RecordePessoal.superaMarca(
                peso: p,
                reps: r,
                baseCarga: previo.$1,
                baseReps: previo.$2,
                base1RM: previo.$3,
              )) {
                final umRM = RecordePessoal.calcular1RM(p, r);
                final ehNovaApice =
                    indiceSerieApice == null ||
                    RecordePessoal.bateuCarga(
                      peso: p,
                      reps: r,
                      baseCarga: apicePeso,
                      baseReps: apiceReps,
                    ) ||
                    (p == apicePeso && umRM > apice1RM) ||
                    (apicePeso <= previo.$1 && umRM > apice1RM);

                if (ehNovaApice) {
                  indiceSerieApice = i;
                  apicePeso = p;
                  apiceReps = r;
                  apice1RM = umRM;
                }
              }
            }

            if (indiceSerieApice != null) {
              mapaPRs[chave] = indiceSerieApice;
            }
          }
        }
        return mapaPRs;
      }

      // Atualiza os recordes prévios acumulados para os próximos treinos
      for (final ex in sessao.exerciciosConcluidosHoje) {
        final chave = ex.nome.trim().toLowerCase();
        double melhorP = recordesPrevios[chave]?.$1 ?? 0.0;
        int melhorR = recordesPrevios[chave]?.$2 ?? 0;
        double melhor1RM = recordesPrevios[chave]?.$3 ?? 0.0;

        for (final s in ex.seriesDetalhes) {
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
          final umRM = RecordePessoal.calcular1RM(p, r);

          if (RecordePessoal.bateuCarga(
            peso: p,
            reps: r,
            baseCarga: melhorP,
            baseReps: melhorR,
          )) {
            melhorP = p;
            melhorR = r;
          }
          if (umRM > melhor1RM) {
            melhor1RM = umRM;
          }
        }

        if (melhorP > 0 || melhor1RM > 0) {
          recordesPrevios[chave] = (melhorP, melhorR, melhor1RM);
        }
      }
    }

    return const {};
  }

  @visibleForTesting
  void definirHistoricoParaTeste(
    List<SessaoTreino> historico, {
    PoderLuta? poderLuta,
  }) {
    _historicoCache = List<SessaoTreino>.from(historico);
    if (poderLuta != null) {
      _poderLuta = poderLuta;
    }
    notifyListeners();
  }
}
