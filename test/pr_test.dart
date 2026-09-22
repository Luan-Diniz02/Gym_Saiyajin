import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/models/recorde_pessoal.dart';

void main() {
  group('RecordePessoal - Cálculo de 1RM (Fórmula de Epley Refinada)', () {
    test('Deve retornar 0 para valores não positivos de peso ou reps', () {
      expect(RecordePessoal.calcular1RM(0, 10), 0.0);
      expect(RecordePessoal.calcular1RM(-50, 10), 0.0);
      expect(RecordePessoal.calcular1RM(100, 0), 0.0);
      expect(RecordePessoal.calcular1RM(100, -2), 0.0);
    });

    test('Para 1 repetição máxima, o 1RM deve ser exatamente o peso levantado (100%)', () {
      expect(RecordePessoal.calcular1RM(100, 1), 100.0);
      expect(RecordePessoal.calcular1RM(142.5, 1), 142.5);
    });

    test('Deve calcular corretamente 1RM para repetições usuais', () {
      // 90 kg x 8 reps: 90 * (1 + 8/30) = 90 * 1.26666... = 114.0
      expect(RecordePessoal.calcular1RM(90, 8), 114.0);

      // 100 kg x 5 reps: 100 * (1 + 5/30) = 100 * 1.16666... = 116.7
      expect(RecordePessoal.calcular1RM(100, 5), 116.7);

      // 60 kg x 10 reps: 60 * (1 + 10/30) = 60 * 1.3333... = 80.0
      expect(RecordePessoal.calcular1RM(60, 10), 80.0);
    });

    test('Deve limitar reps em 15 para evitar distorções estatísticas irreais', () {
      final rm15 = RecordePessoal.calcular1RM(50, 15);
      final rm25 = RecordePessoal.calcular1RM(50, 25);
      expect(rm25, equals(rm15));
      expect(rm15, 50 * (1 + 15 / 30.0)); // 75.0
    });

    test('formatarPeso deve retornar números inteiros sem .0 e decimais limpos', () {
      expect(RecordePessoal.formatarPeso(100.0), '100');
      expect(RecordePessoal.formatarPeso(102.5), '102.5');
      expect(RecordePessoal.formatarPeso(85.0), '85');
    });

    test('Serialização e Deserialização de RecordePessoal', () {
      final data = DateTime(2026, 9, 22, 10, 30);
      final pr = RecordePessoal(
        exercicioNome: 'Supino Reto',
        grupo: 'Peito',
        cargaMaxima: 110.0,
        repsCargaMaxima: 5,
        umRepMaxEstimado: 128.3,
        peso1RM: 110.0,
        reps1RM: 5,
        dataRecorde: data,
        sessaoId: 42,
      );

      final map = pr.toMap();
      final reconstruido = RecordePessoal.fromMap(map);

      expect(reconstruido.exercicioNome, 'Supino Reto');
      expect(reconstruido.grupo, 'Peito');
      expect(reconstruido.cargaMaxima, 110.0);
      expect(reconstruido.repsCargaMaxima, 5);
      expect(reconstruido.umRepMaxEstimado, 128.3);
      expect(reconstruido.peso1RM, 110.0);
      expect(reconstruido.reps1RM, 5);
      expect(reconstruido.dataRecorde, data);
      expect(reconstruido.sessaoId, 42);
    });
  });
}
