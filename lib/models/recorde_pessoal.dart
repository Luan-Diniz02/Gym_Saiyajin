/// Entidade de domínio para Recorde Pessoal (PR) de um exercício.
class RecordePessoal {
  final String exercicioNome;
  final String grupo;
  final double cargaMaxima;
  final int repsCargaMaxima;
  final double umRepMaxEstimado;
  final double peso1RM;
  final int reps1RM;
  final DateTime? dataRecorde;
  final int? sessaoId;

  const RecordePessoal({
    required this.exercicioNome,
    required this.grupo,
    required this.cargaMaxima,
    required this.repsCargaMaxima,
    required this.umRepMaxEstimado,
    required this.peso1RM,
    required this.reps1RM,
    this.dataRecorde,
    this.sessaoId,
  });

  /// Calcula o 1RM estimado através da fórmula refinada de Epley.
  /// 
  /// Para 1 repetição, o 1RM real é 100% da carga levantada.
  /// Para > 1 repetições, aplica-se peso * (1 + reps/30), com teto
  /// de segurança em 15 reps para evitar extrapolações distorcidas.
  static double calcular1RM(double peso, int reps) {
    if (peso <= 0 || reps <= 0) return 0.0;
    if (reps == 1) return peso;

    final repsLimitadas = reps > 15 ? 15 : reps;
    final valor = peso * (1.0 + (repsLimitadas / 30.0));
    // Arredonda para 1 casa decimal
    return (valor * 10).round() / 10.0;
  }

  /// Formata peso para exibição limpa (ex: '100' ou '102.5')
  static String formatarPeso(double peso) {
    if (peso % 1 == 0) {
      return peso.toInt().toString();
    }
    return peso.toStringAsFixed(1);
  }

  RecordePessoal copyWith({
    String? exercicioNome,
    String? grupo,
    double? cargaMaxima,
    int? repsCargaMaxima,
    double? umRepMaxEstimado,
    double? peso1RM,
    int? reps1RM,
    DateTime? dataRecorde,
    int? sessaoId,
  }) {
    return RecordePessoal(
      exercicioNome: exercicioNome ?? this.exercicioNome,
      grupo: grupo ?? this.grupo,
      cargaMaxima: cargaMaxima ?? this.cargaMaxima,
      repsCargaMaxima: repsCargaMaxima ?? this.repsCargaMaxima,
      umRepMaxEstimado: umRepMaxEstimado ?? this.umRepMaxEstimado,
      peso1RM: peso1RM ?? this.peso1RM,
      reps1RM: reps1RM ?? this.reps1RM,
      dataRecorde: dataRecorde ?? this.dataRecorde,
      sessaoId: sessaoId ?? this.sessaoId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exercicioNome': exercicioNome,
      'grupo': grupo,
      'cargaMaxima': cargaMaxima,
      'repsCargaMaxima': repsCargaMaxima,
      'umRepMaxEstimado': umRepMaxEstimado,
      'peso1RM': peso1RM,
      'reps1RM': reps1RM,
      'dataRecorde': dataRecorde?.toIso8601String(),
      'sessaoId': sessaoId,
    };
  }

  factory RecordePessoal.fromMap(Map<String, dynamic> map) {
    return RecordePessoal(
      exercicioNome: map['exercicioNome'] as String? ?? '',
      grupo: map['grupo'] as String? ?? '',
      cargaMaxima: (map['cargaMaxima'] as num?)?.toDouble() ?? 0.0,
      repsCargaMaxima: (map['repsCargaMaxima'] as num?)?.toInt() ?? 0,
      umRepMaxEstimado: (map['umRepMaxEstimado'] as num?)?.toDouble() ?? 0.0,
      peso1RM: (map['peso1RM'] as num?)?.toDouble() ?? 0.0,
      reps1RM: (map['reps1RM'] as num?)?.toInt() ?? 0,
      dataRecorde: map['dataRecorde'] != null
          ? DateTime.tryParse(map['dataRecorde'] as String)
          : null,
      sessaoId: (map['sessaoId'] as num?)?.toInt(),
    );
  }
}
