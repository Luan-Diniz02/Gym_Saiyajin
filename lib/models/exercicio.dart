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
}
