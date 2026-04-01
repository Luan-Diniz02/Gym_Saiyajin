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
}
