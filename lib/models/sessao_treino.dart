import 'exercicio.dart';

class SessaoTreino {
  final List<Exercicio> exerciciosConcluidosHoje;
  Exercicio? exercicioAtual;

  SessaoTreino({
    required this.exerciciosConcluidosHoje,
    this.exercicioAtual,
  });

  factory SessaoTreino.vazia() {
    return SessaoTreino(exerciciosConcluidosHoje: []);
  }
}
