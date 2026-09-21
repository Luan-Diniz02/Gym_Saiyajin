import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/models/ficha_treino.dart';

void main() {
  group('Modelo de FichaTreino', () {
    test('Deve serializar e deserializar FichaTreino com sucesso', () {
      final ficha = FichaTreino(
        id: 10,
        nome: 'Ficha B - Costas e Bíceps',
        descricao: 'Foco em dorsal e bíceps braquial',
        exercicios: [
          FichaExercicioItem(
            id: 1,
            fichaId: 10,
            nome: 'Puxada Frontal',
            grupo: 'COSTAS',
            ordem: 0,
            seriesPadrao: 4,
          ),
          FichaExercicioItem(
            id: 2,
            fichaId: 10,
            nome: 'Rosca Direta Barra W',
            grupo: 'BÍCEPS',
            ordem: 1,
            seriesPadrao: 3,
          ),
        ],
      );

      final json = ficha.toJson();
      final restaurada = FichaTreino.fromJson(json);

      expect(restaurada.id, equals(10));
      expect(restaurada.nome, equals('Ficha B - Costas e Bíceps'));
      expect(restaurada.descricao, equals('Foco em dorsal e bíceps braquial'));
      expect(restaurada.exercicios.length, equals(2));
      expect(restaurada.exercicios[0].nome, equals('Puxada Frontal'));
      expect(restaurada.exercicios[0].seriesPadrao, equals(4));
      expect(restaurada.exercicios[1].nome, equals('Rosca Direta Barra W'));
      expect(restaurada.exercicios[1].seriesPadrao, equals(3));
    });
  });
}
