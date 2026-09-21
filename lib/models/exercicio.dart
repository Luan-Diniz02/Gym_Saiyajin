import 'serie.dart';

class Exercicio {
  final String nome;
  final String grupo;
  final List<Serie> seriesDetalhes;

  Exercicio({
    required this.nome,
    required this.grupo,
    required this.seriesDetalhes,
  });

  Exercicio copyWith({
    String? nome,
    String? grupo,
    List<Serie>? seriesDetalhes,
  }) {
    return Exercicio(
      nome: nome ?? this.nome,
      grupo: grupo ?? this.grupo,
      seriesDetalhes: seriesDetalhes ?? this.seriesDetalhes.map((serie) => serie.copy()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'grupo': grupo,
      'seriesDetalhes': seriesDetalhes.map((s) => s.toJson()).toList(),
    };
  }

  factory Exercicio.fromJson(Map<String, dynamic> json) {
    final seriesList = (json['seriesDetalhes'] as List<dynamic>?) ?? [];
    return Exercicio(
      nome: json['nome'] as String? ?? '',
      grupo: json['grupo'] as String? ?? '',
      seriesDetalhes: seriesList
          .map((s) => Serie.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
