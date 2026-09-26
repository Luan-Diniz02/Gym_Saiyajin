import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/models/exercicio.dart';
import 'package:gym_saiyajin/models/serie.dart';
import 'package:gym_saiyajin/models/sessao_treino.dart';

void main() {
  group('SessaoTreino - Volume e Séries Unificados', () {
    test('Calcula volume total e séries considerando todas as séries válidas mesmo que concluida seja false', () {
      final sessao = SessaoTreino(
        nomeTreino: 'Peito e Tríceps',
        data: DateTime(2026, 9, 25),
        duracaoSegundos: 6780, // 1h 53m
        descansoTotalSegundos: 2880, // 48 min
        exerciciosConcluidosHoje: [
          Exercicio(
            nome: 'Supino Reto',
            grupo: 'PEITO',
            seriesDetalhes: [
              Serie(peso: 70, reps: 10, concluida: true),   // 700
              Serie(peso: 70, reps: 10, concluida: true),   // 700
              Serie(peso: 70, reps: 10, concluida: true),   // 700
              Serie(peso: 70, reps: 10, concluida: true),   // 700 -> 2800 kg
            ],
          ),
          Exercicio(
            nome: 'Supino Inclinado (halteres)',
            grupo: 'PEITO',
            seriesDetalhes: [
              Serie(peso: 35, reps: 10, concluida: true),   // 350
              Serie(peso: 35, reps: 10, concluida: true),   // 350
              Serie(peso: 35, reps: 10, concluida: true),   // 350
              Serie(peso: 35, reps: 10, concluida: true),   // 350 -> 1400 kg
            ],
          ),
          Exercicio(
            nome: 'Desenvolvimento Halteres',
            grupo: 'OMBROS',
            seriesDetalhes: [
              Serie(peso: 25, reps: 10, concluida: true),   // 250
              Serie(peso: 25, reps: 10, concluida: true),   // 250
              Serie(peso: 25, reps: 10, concluida: true),   // 250
              Serie(peso: 25, reps: 10, concluida: true),   // 250 -> 1000 kg
            ],
          ),
          Exercicio(
            nome: 'Elevação Lateral (Polia)',
            grupo: 'OMBROS',
            seriesDetalhes: [
              Serie(peso: 12, reps: 10, concluida: true),   // 120
              Serie(peso: 12, reps: 10, concluida: true),   // 120
              Serie(peso: 12, reps: 10, concluida: true),   // 120 -> 360 kg
            ],
          ),
          Exercicio(
            nome: 'Voador',
            grupo: 'PEITO',
            seriesDetalhes: [
              Serie(peso: 30, reps: 10, concluida: true),   // 300
              Serie(peso: 30, reps: 10, concluida: true),   // 300
              Serie(peso: 30, reps: 10, concluida: true),   // 300
              Serie(peso: 31, reps: 10, concluida: true),   // 310 -> 1210 kg
            ],
          ),
          Exercicio(
            nome: 'Tríceps Corda',
            grupo: 'TRÍCEPS',
            seriesDetalhes: [
              Serie(peso: 25, reps: 10, concluida: true),   // 250
              Serie(peso: 25, reps: 10, concluida: true),   // 250
              Serie(peso: 25, reps: 10, concluida: true),   // 250 -> total checked = 7520 kg (22 series, 6 exercicios)
            ],
          ),
          Exercicio(
            nome: 'Tríceps Testa',
            grupo: 'TRÍCEPS',
            seriesDetalhes: [
              // 4 séries não marcadas com check (por exemplo, finalizou direto): 920 kg (4 series, 7º exercicio)
              Serie(peso: 23, reps: 10, concluida: false),  // 230
              Serie(peso: 23, reps: 10, concluida: false),  // 230
              Serie(peso: 23, reps: 10, concluida: false),  // 230
              Serie(peso: 23, reps: 10, concluida: false),  // 230
            ],
          ),
        ],
      );

      // Total de exercícios: 7
      expect(sessao.exerciciosConcluidosHoje.length, 7);

      // Total de séries: 22 + 4 = 26 séries
      expect(sessao.totalSeries, 26);

      // Volume total: 7520 + 920 = 8440 kg
      expect(sessao.volumeTotal, 8440.0);

      // Formatação padronizada com pontuação de milhar (igual em Histórico e Compartilhamento)
      expect(sessao.volumeFormatado, '8.440 kg');
    });

    test('formatarVolume lida corretamente com zero, valores menores que 1000 e decimais', () {
      expect(SessaoTreino.formatarVolume(0), '0 kg');
      expect(SessaoTreino.formatarVolume(950), '950 kg');
      expect(SessaoTreino.formatarVolume(1000), '1.000 kg');
      expect(SessaoTreino.formatarVolume(7520), '7.520 kg');
      expect(SessaoTreino.formatarVolume(8440), '8.440 kg');
      expect(SessaoTreino.formatarVolume(12500), '12.500 kg');
    });
  });
}
