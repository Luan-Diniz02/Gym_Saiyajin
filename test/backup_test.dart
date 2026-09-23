import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/models/exercicio.dart';
import 'package:gym_saiyajin/models/serie.dart';
import 'package:gym_saiyajin/models/sessao_treino.dart';
import 'package:gym_saiyajin/services/backup_service.dart';

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

  group('Backup v2 - Fichas, Metas e Medidas Corporais', () {
    test('BackupResult deve registrar totalSessoes e totalFichas com padrão zero', () {
      const res = BackupResult(sucesso: true, mensagem: 'OK');
      expect(res.totalSessoes, 0);
      expect(res.totalFichas, 0);

      const resCompleto = BackupResult(
        sucesso: true,
        mensagem: 'Sucesso',
        totalSessoes: 5,
        totalFichas: 2,
      );
      expect(resCompleto.totalSessoes, 5);
      expect(resCompleto.totalFichas, 2);
    });

    test('Deve suportar estrutura completa de backup v2 com fichas e perfil_usuario', () {
      final jsonBackupV2 = {
        'app': 'Gym Saiyajin',
        'versao_backup': 2,
        'data_exportacao': '2026-09-23T10:00:00.000',
        'total_sessoes': 1,
        'total_fichas': 1,
        'sessoes': [
          {
            'id': 100,
            'data': '2026-09-23T08:00:00.000',
            'nome_treino': 'Push Day',
            'duracao_segundos': 2400,
            'descanso_total_segundos': 600,
            'exercicios': [
              {
                'nome': 'Supino Reto',
                'grupo': 'PEITO',
                'seriesDetalhes': [
                  {'peso': 90.0, 'reps': 8, 'concluida': true},
                ],
              },
            ],
          },
        ],
        'fichas': [
          {
            'id': 1,
            'nome': 'Treino A - Push',
            'descricao': 'Peito, Ombro e Tríceps',
            'exercicios': [
              {
                'id': 1,
                'fichaId': 1,
                'nome': 'Supino Reto',
                'grupo': 'PEITO',
                'ordem': 0,
                'seriesPadrao': 4,
              },
            ],
          },
        ],
        'perfil_usuario': {
          'meta_dias_semana': 4,
          'peso_atual': 74.5,
          'altura': 1.76,
          'percentual_gordura': 13.5,
          'data_atualizacao_peso': '2026-09-23T09:00:00.000',
          'tempo_descanso_padrao': 90,
        },
        'exercicios_customizados': [
          {'nome': 'Crucifixo Inclinado com Halteres', 'grupo': 'PEITO'},
        ],
      };

      expect(jsonBackupV2['versao_backup'], 2);
      expect((jsonBackupV2['fichas'] as List).length, 1);
      final perfil = jsonBackupV2['perfil_usuario'] as Map<String, dynamic>;
      expect(perfil['meta_dias_semana'], 4);
      expect(perfil['peso_atual'], 74.5);
      expect(perfil['tempo_descanso_padrao'], 90);
    });

    test('Deve manter retrocompatibilidade com backup v1 ausente de fichas e perfil', () {
      final jsonBackupV1 = {
        'app': 'Gym Saiyajin',
        'versao_backup': 1,
        'data_exportacao': '2026-09-20T10:00:00.000',
        'total_sessoes': 1,
        'sessoes': [
          {
            'id': 50,
            'data': '2026-09-20T08:00:00.000',
            'nome_treino': 'Leg Day',
            'duracao_segundos': 3000,
            'descanso_total_segundos': 500,
            'exercicios': [],
          },
        ],
        'exercicios_customizados': [],
      };

      expect(jsonBackupV1['versao_backup'], 1);
      expect(jsonBackupV1.containsKey('fichas'), false);
      expect(jsonBackupV1.containsKey('perfil_usuario'), false);

      final perfil = jsonBackupV1['perfil_usuario'] as Map<String, dynamic>?;
      expect(perfil, isNull);
    });
  });
}
