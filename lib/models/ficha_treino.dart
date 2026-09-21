class FichaExercicioItem {
  final int? id;
  final int? fichaId;
  final String nome;
  final String grupo;
  final int ordem;
  final int seriesPadrao;

  FichaExercicioItem({
    this.id,
    this.fichaId,
    required this.nome,
    required this.grupo,
    this.ordem = 0,
    this.seriesPadrao = 3,
  });

  FichaExercicioItem copyWith({
    int? id,
    int? fichaId,
    String? nome,
    String? grupo,
    int? ordem,
    int? seriesPadrao,
  }) {
    return FichaExercicioItem(
      id: id ?? this.id,
      fichaId: fichaId ?? this.fichaId,
      nome: nome ?? this.nome,
      grupo: grupo ?? this.grupo,
      ordem: ordem ?? this.ordem,
      seriesPadrao: seriesPadrao ?? this.seriesPadrao,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fichaId': fichaId,
      'nome': nome,
      'grupo': grupo,
      'ordem': ordem,
      'seriesPadrao': seriesPadrao,
    };
  }

  factory FichaExercicioItem.fromJson(Map<String, dynamic> json) {
    return FichaExercicioItem(
      id: json['id'] as int?,
      fichaId: json['fichaId'] as int?,
      nome: json['nome'] as String? ?? '',
      grupo: json['grupo'] as String? ?? '',
      ordem: (json['ordem'] as num?)?.toInt() ?? 0,
      seriesPadrao: (json['seriesPadrao'] as num?)?.toInt() ?? 3,
    );
  }
}

class FichaTreino {
  final int? id;
  final String nome;
  final String? descricao;
  final List<FichaExercicioItem> exercicios;

  FichaTreino({
    this.id,
    required this.nome,
    this.descricao,
    required this.exercicios,
  });

  FichaTreino copyWith({
    int? id,
    String? nome,
    String? descricao,
    List<FichaExercicioItem>? exercicios,
  }) {
    return FichaTreino(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      exercicios: exercicios ?? this.exercicios,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'exercicios': exercicios.map((e) => e.toJson()).toList(),
    };
  }

  factory FichaTreino.fromJson(Map<String, dynamic> json) {
    final list = (json['exercicios'] as List<dynamic>?) ?? [];
    return FichaTreino(
      id: json['id'] as int?,
      nome: json['nome'] as String? ?? '',
      descricao: json['descricao'] as String?,
      exercicios: list
          .map((e) => FichaExercicioItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
