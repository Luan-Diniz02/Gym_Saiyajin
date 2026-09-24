import 'dart:collection';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';

import '../models/exercicio.dart';
import '../models/poder_luta.dart';
import '../models/recorde_pessoal.dart';
import '../models/sessao_treino.dart';
import '../models/serie.dart';
import '../repositories/treino_repository.dart';
import '../services/preferences_service.dart';

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
  final List<String> _exerciciosDisponiveis = ['Nenhum exercício'];
  final List<FlSpot> _pontosDoGraficoFiltrado = [];
  final List<String> _datasDoGrafico = [];
  List<SessaoTreino> _historicoCache = [];

  double get pesoAtual => _pesoAtual;
  double get altura => _altura;
  int get diasTreinadosNaSemana => _diasTreinadosNaSemana;
  int get metaDiasSemana => _metaDiasSemana;
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

  List<FlSpot> get pontosDoGraficoFiltrado =>
      UnmodifiableListView(_pontosDoGraficoFiltrado);

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

    _pontosDoGraficoFiltrado.clear();
    _datasDoGrafico.clear();

    for (int i = 0; i < sessoesComExercicio.length; i++) {
      final sessao = sessoesComExercicio[i];
      final double? pesoMaximo = _buscarPesoMaximo(
        sessao.exerciciosConcluidosHoje,
        _exercicioFiltro,
      );
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

    if (poolSessoes.isEmpty) return 0;

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
        int prsNaSessao = 0;

        for (final ex in sessaoAlvo.exerciciosConcluidosHoje) {
          final chave = ex.nome.trim().toLowerCase();
          final previo = recordesPrevios[chave];

          if (previo != null) {
            bool bateuPR = false;
            for (final s in ex.seriesDetalhes) {
              if (!s.concluida ||
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
                bateuPR = true;
                break;
              }
            }
            if (bateuPR) {
              prsNaSessao++;
            }
          }
        }
        return prsNaSessao;
      }

      // Atualiza os recordes prévios acumulados para os próximos treinos
      for (final ex in sessao.exerciciosConcluidosHoje) {
        final chave = ex.nome.trim().toLowerCase();
        double melhorP = recordesPrevios[chave]?.$1 ?? 0.0;
        int melhorR = recordesPrevios[chave]?.$2 ?? 0;
        double melhor1RM = recordesPrevios[chave]?.$3 ?? 0.0;

        for (final s in ex.seriesDetalhes) {
          if (!s.concluida ||
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

    return 0;
  }
}
