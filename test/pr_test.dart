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

  group('RecordePessoal - Regras Unificadas de Superação de PR', () {
    const recordeBase = RecordePessoal(
      exercicioNome: 'Supino Reto',
      grupo: 'Peito',
      cargaMaxima: 100.0,
      repsCargaMaxima: 5,
      umRepMaxEstimado: 116.7, // 100 * (1 + 5/30) = 116.7
      peso1RM: 100.0,
      reps1RM: 5,
    );

    test('bateuCarga deve retornar true se o peso for maior ou se mesmo peso com mais reps', () {
      // Peso maior
      expect(RecordePessoal.bateuCarga(peso: 105.0, reps: 3, baseCarga: 100.0, baseReps: 5), isTrue);
      // Mesmo peso com mais reps
      expect(RecordePessoal.bateuCarga(peso: 100.0, reps: 6, baseCarga: 100.0, baseReps: 5), isTrue);
      // Mesmo peso com mesmas reps
      expect(RecordePessoal.bateuCarga(peso: 100.0, reps: 5, baseCarga: 100.0, baseReps: 5), isFalse);
      // Peso menor
      expect(RecordePessoal.bateuCarga(peso: 90.0, reps: 10, baseCarga: 100.0, baseReps: 5), isFalse);
      // Valores não positivos
      expect(RecordePessoal.bateuCarga(peso: 0.0, reps: 10, baseCarga: 100.0, baseReps: 5), isFalse);
      expect(RecordePessoal.bateuCarga(peso: 100.0, reps: 0, baseCarga: 100.0, baseReps: 5), isFalse);
    });

    test('bateu1RM deve retornar true quando o 1RM estimado for estritamente maior', () {
      // 95kg x 8 reps -> 95 * (1 + 8/30) = 120.3 > 116.7
      expect(RecordePessoal.bateu1RM(peso: 95.0, reps: 8, base1RM: 116.7), isTrue);
      // 90kg x 6 reps -> 90 * (1 + 6/30) = 108.0 < 116.7
      expect(RecordePessoal.bateu1RM(peso: 90.0, reps: 6, base1RM: 116.7), isFalse);
      // Valores não positivos
      expect(RecordePessoal.bateu1RM(peso: -10.0, reps: 5, base1RM: 116.7), isFalse);
    });

    test('supera deve detectar quebra de recorde por carga ou por 1RM', () {
      // Quebrou por carga máxima absoluta (110kg x 2) -> 1RM = 117.3
      expect(recordeBase.supera(110.0, 2), isTrue);
      expect(recordeBase.superaCarga(110.0, 2), isTrue);

      // Quebrou por 1RM com carga menor mas alto volume (95kg x 8 reps -> 1RM 120.3)
      expect(recordeBase.supera(95.0, 8), isTrue);
      expect(recordeBase.superaCarga(95.0, 8), isFalse);
      expect(recordeBase.supera1RM(95.0, 8), isTrue);

      // Não quebrou nem carga nem 1RM (90kg x 5 -> 1RM 105.0)
      expect(recordeBase.supera(90.0, 5), isFalse);
      expect(recordeBase.superaCarga(90.0, 5), isFalse);
      expect(recordeBase.supera1RM(90.0, 5), isFalse);
    });

    test('superaMarca estático deve avaliar corretamente os critérios base', () {
      expect(
        RecordePessoal.superaMarca(
          peso: 80.0,
          reps: 12, // 1RM: 80 * 1.4 = 112.0
          baseCarga: 90.0,
          baseReps: 5, // 1RM: 90 * 1.166 = 105.0
          base1RM: 105.0,
        ),
        isTrue, // 112.0 > 105.0
      );
    });
  });
}
