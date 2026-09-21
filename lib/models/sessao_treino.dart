import 'exercicio.dart';

class SessaoTreino {
  final int? id;
  final DateTime? data;
  final String? nomeTreino;
  final int duracaoSegundos;
  final int descansoTotalSegundos;
  final List<Exercicio> exerciciosConcluidosHoje;
  Exercicio? exercicioAtual;

  SessaoTreino({
    this.id,
    this.data,
    this.nomeTreino,
    this.duracaoSegundos = 0,
    this.descansoTotalSegundos = 0,
    required this.exerciciosConcluidosHoje,
    this.exercicioAtual,
  });

  factory SessaoTreino.vazia() {
    return SessaoTreino(exerciciosConcluidosHoje: []);
  }

  SessaoTreino copyWith({
    int? id,
    DateTime? data,
    String? nomeTreino,
    int? duracaoSegundos,
    int? descansoTotalSegundos,
    List<Exercicio>? exerciciosConcluidosHoje,
    Exercicio? exercicioAtual,
  }) {
    return SessaoTreino(
      id: id ?? this.id,
      data: data ?? this.data,
      nomeTreino: nomeTreino ?? this.nomeTreino,
      duracaoSegundos: duracaoSegundos ?? this.duracaoSegundos,
      descansoTotalSegundos: descansoTotalSegundos ?? this.descansoTotalSegundos,
      exerciciosConcluidosHoje: exerciciosConcluidosHoje ?? this.exerciciosConcluidosHoje,
      exercicioAtual: exercicioAtual ?? this.exercicioAtual,
    );
  }

  static String formatarSegundosLegivel(int segundos) {
    if (segundos <= 0) return '0 min';
    final horas = segundos ~/ 3600;
    final minutos = (segundos % 3600) ~/ 60;
    if (horas > 0) {
      return minutos > 0 ? '${horas}h ${minutos}m' : '${horas}h';
    }
    return '${minutos > 0 ? minutos : 1} min';
  }

  String get duracaoFormatada => formatarSegundosLegivel(duracaoSegundos);
  String get descansoFormatado => formatarSegundosLegivel(descansoTotalSegundos);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data?.toIso8601String(),
      'nomeTreino': nomeTreino,
      'duracaoSegundos': duracaoSegundos,
      'descansoTotalSegundos': descansoTotalSegundos,
      'exercicios': exerciciosConcluidosHoje.map((e) => e.toJson()).toList(),
    };
  }

  factory SessaoTreino.fromJson(Map<String, dynamic> json) {
    final exerciciosList = (json['exercicios'] as List<dynamic>?) ?? [];
    return SessaoTreino(
      id: json['id'] as int?,
      data: json['data'] != null ? DateTime.tryParse(json['data'] as String) : null,
      nomeTreino: json['nomeTreino'] as String?,
      duracaoSegundos: (json['duracaoSegundos'] as num?)?.toInt() ?? 0,
      descansoTotalSegundos: (json['descansoTotalSegundos'] as num?)?.toInt() ?? 0,
      exerciciosConcluidosHoje: exerciciosList
          .map((e) => Exercicio.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
