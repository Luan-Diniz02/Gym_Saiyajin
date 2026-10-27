/// Classificação biomecânica das séries de musculação (padrão Hevy/Strong).
enum TipoSerie {
  normal(
    codigo: 'normal',
    sigla: 'N',
    label: 'Série de Trabalho',
    descricao: 'Série principal que contabiliza 1RM e Recordes Pessoais (PRs).',
  ),
  warmup(
    codigo: 'warmup',
    sigla: 'W',
    label: 'Aquecimento',
    descricao: 'Ativação neuromuscular fluida sem poluir 1RM ou gerar falsos PRs.',
  ),
  dropset(
    codigo: 'dropset',
    sigla: 'D',
    label: 'Drop-set',
    descricao: 'Redução imediata de carga sem descanso para estresse metabólico.',
  ),
  falha(
    codigo: 'falha',
    sigla: 'F',
    label: 'Falha Total',
    descricao: 'Execução até a falha concêntrica momentânea (RIR 0 / RPE 10).',
  );

  final String codigo;
  final String sigla;
  final String label;
  final String descricao;

  const TipoSerie({
    required this.codigo,
    required this.sigla,
    required this.label,
    required this.descricao,
  });

  /// Converte a string persistida no banco/JSON para o enum correspondente.
  static TipoSerie fromCodigo(String? codigo) {
    final norm = codigo?.trim().toLowerCase() ?? 'normal';
    for (final item in TipoSerie.values) {
      if (item.codigo == norm) return item;
    }
    return TipoSerie.normal;
  }

  /// Retorna o próximo tipo na rotação rápida (Normal -> Aquecimento -> Drop-set -> Falha -> Normal).
  TipoSerie get proximo {
    final nextIndex = (index + 1) % TipoSerie.values.length;
    return TipoSerie.values[nextIndex];
  }
}

class Serie {
  double? peso;
  int? reps;
  bool concluida;
  String tipo;
  int? rir;

  Serie({
    this.peso,
    this.reps,
    this.concluida = false,
    String? tipo,
    this.rir,
  }) : tipo = TipoSerie.fromCodigo(tipo).codigo;

  /// Calcula o número sequencial da série de trabalho (1, 2, 3...) ignorando
  /// as séries de aquecimento anteriores na mesma lista (padrão Hevy/Strong).
  static int calcularNumeroSerieTrabalho(List<Serie> series, int index) {
    int contador = 0;
    for (int i = 0; i <= index && i < series.length; i++) {
      if (!series[i].isWarmup) {
        contador++;
      }
    }
    return contador > 0 ? contador : index + 1;
  }

  /// Retorna o tipo tipado como [TipoSerie].
  TipoSerie get tipoEnum => TipoSerie.fromCodigo(tipo);

  /// Indica se a série é de aquecimento.
  /// Séries de aquecimento não contabilizam 1RM estimado nem disparam PRs.
  bool get isWarmup => tipoEnum == TipoSerie.warmup;

  /// Indica se a série é um Drop-set.
  bool get isDropset => tipoEnum == TipoSerie.dropset;

  /// Indica se a série foi levada até a Falha Total.
  bool get isFalha => tipoEnum == TipoSerie.falha;

  /// Indica se é uma série normal de trabalho.
  bool get isNormal => tipoEnum == TipoSerie.normal;

  /// Calcula o RPE (Rate of Perceived Exertion) equivalente ao RIR registrado (`10 - RIR`).
  double? get rpe {
    if (rir == null) return null;
    return (10 - rir!).clamp(1, 10).toDouble();
  }

  /// Formata a tag curta de RIR (ex: `'RIR 2'` ou `'RIR 4+'`).
  String? get rirLabel {
    if (rir == null) return null;
    return rir! >= 4 ? 'RIR 4+' : 'RIR $rir';
  }

  /// Formata a tag curta de RPE equivalente (ex: `'RPE 8'`).
  String? get rpeLabel {
    final valorRpe = rpe;
    if (valorRpe == null) return null;
    return 'RPE ${valorRpe.toInt()}';
  }

  Serie copy() {
    return Serie(
      peso: peso,
      reps: reps,
      concluida: concluida,
      tipo: tipo,
      rir: rir,
    );
  }

  Serie copyWith({
    double? peso,
    int? reps,
    bool? concluida,
    String? tipo,
    int? rir,
    bool limparRir = false,
  }) {
    return Serie(
      peso: peso ?? this.peso,
      reps: reps ?? this.reps,
      concluida: concluida ?? this.concluida,
      tipo: tipo ?? this.tipo,
      rir: limparRir ? null : (rir ?? this.rir),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'peso': peso,
      'reps': reps,
      'concluida': concluida,
      'tipo': tipo,
      if (rir != null) 'rir': rir,
    };
  }

  factory Serie.fromJson(Map<String, dynamic> json) {
    return Serie(
      peso: (json['peso'] as num?)?.toDouble(),
      reps: (json['reps'] as num?)?.toInt(),
      concluida: (json['concluida'] as bool?) ?? false,
      tipo: (json['tipo'] as String?) ?? 'normal',
      rir: (json['rir'] as num?)?.toInt(),
    );
  }
}
