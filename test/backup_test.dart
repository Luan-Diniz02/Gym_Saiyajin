import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/models/exercicio.dart';
import 'package:gym_saiyajin/models/serie.dart';
import 'package:gym_saiyajin/models/sessao_treino.dart';

void main() {
  group('Serialização e Modelo de SessaoTreino (Backup)', () {
    test('Deve serializar e deserializar Serie com sucesso', () {
      final serie = Serie(peso: 80.5, reps: 10, concluida: true);
      final json = serie.toJson();

      expect(json['peso'], 80.5);
      expect(json['reps'], 10);
      expect(json['concluida'], true);

      final serieRestaurada = Serie.fromJson(json);
      expect(serieRestaurada.peso, 80.5);
      expect(serieRestaurada.reps, 10);
      expect(serieRestaurada.concluida, true);
    });

    test('Deve serializar e deserializar Exercicio com suas séries', () {
      final exercicio = Exercicio(
        nome: 'Supino Reto',
        grupo: 'PEITO',
        seriesDetalhes: [
          Serie(peso: 60.0, reps: 12, concluida: true),
          Serie(peso: 70.0, reps: 10, concluida: true),
        ],
      );

      final json = exercicio.toJson();
      expect(json['nome'], 'Supino Reto');
      expect(json['grupo'], 'PEITO');
      expect((json['seriesDetalhes'] as List).length, 2);

      final exercicioRestaurado = Exercicio.fromJson(json);
      expect(exercicioRestaurado.nome, 'Supino Reto');
      expect(exercicioRestaurado.grupo, 'PEITO');
      expect(exercicioRestaurado.seriesDetalhes.length, 2);
      expect(exercicioRestaurado.seriesDetalhes[1].peso, 70.0);
    });

    test('Deve serializar e deserializar SessaoTreino preservando tempo total e descanso', () {
      final data = DateTime(2026, 9, 21, 10, 30);
      final sessao = SessaoTreino(
        id: 1,
        data: data,
        nomeTreino: 'Treino A - Peito e Tríceps',
        duracaoSegundos: 3600, // 1 hora
        descansoTotalSegundos: 720, // 12 minutos
        exerciciosConcluidosHoje: [
          Exercicio(
            nome: 'Supino Reto',
            grupo: 'PEITO',
            seriesDetalhes: [
              Serie(peso: 80.0, reps: 8, concluida: true),
            ],
          ),
        ],
      );

      final json = sessao.toJson();
      expect(json['duracaoSegundos'], 3600);
      expect(json['descansoTotalSegundos'], 720);
      expect(json['nomeTreino'], 'Treino A - Peito e Tríceps');
      expect(json['data'], data.toIso8601String());

      final sessaoRestaurada = SessaoTreino.fromJson(json);
      expect(sessaoRestaurada.duracaoSegundos, 3600);
      expect(sessaoRestaurada.descansoTotalSegundos, 720);
      expect(sessaoRestaurada.duracaoFormatada, '1h');
      expect(sessaoRestaurada.descansoFormatado, '12 min');
      expect(sessaoRestaurada.exerciciosConcluidosHoje.length, 1);
      expect(sessaoRestaurada.exerciciosConcluidosHoje.first.nome, 'Supino Reto');
    });

    test('formatarSegundosLegivel deve formatar corretamente minutos e horas', () {
      expect(SessaoTreino.formatarSegundosLegivel(0), '0 min');
      expect(SessaoTreino.formatarSegundosLegivel(45), '1 min');
      expect(SessaoTreino.formatarSegundosLegivel(120), '2 min');
      expect(SessaoTreino.formatarSegundosLegivel(3600), '1h');
      expect(SessaoTreino.formatarSegundosLegivel(4500), '1h 15m');
    });
  });
}
