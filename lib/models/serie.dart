class Serie {
  double? peso;
  int? reps;
  bool concluida;

  Serie({
    this.peso,
    this.reps,
    this.concluida = false,
  });

  Serie copy() {
    return Serie(
      peso: peso,
      reps: reps,
      concluida: concluida,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'peso': peso,
      'reps': reps,
      'concluida': concluida,
    };
  }

  factory Serie.fromJson(Map<String, dynamic> json) {
    return Serie(
      peso: (json['peso'] as num?)?.toDouble(),
      reps: (json['reps'] as num?)?.toInt(),
      concluida: json['concluida'] as bool? ?? false,
    );
  }
}
