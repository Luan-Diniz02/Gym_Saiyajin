import 'exercicio.dart';

class SessaoTreino {
  final int? id;
  final DateTime? data;
  final List<Exercicio> exerciciosConcluidosHoje;
  Exercicio? exercicioAtual;

  SessaoTreino({
    this.id,
    this.data,
    required this.exerciciosConcluidosHoje,
    this.exercicioAtual,
  });

  factory SessaoTreino.vazia() {
    return SessaoTreino(exerciciosConcluidosHoje: []);
  }
}
