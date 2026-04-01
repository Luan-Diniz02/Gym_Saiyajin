import '../database/db_helper.dart';
import '../models/exercicio.dart';
import '../models/serie.dart';
import '../models/sessao_treino.dart';

class TreinoRepository {
  final DatabaseHelper _databaseHelper;

  TreinoRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<void> salvarSessaoTreino(SessaoTreino sessao) async {
    try {
      final db = await _databaseHelper.database;

      await db.transaction((txn) async {
        final int sessaoId = await txn.insert('sessoes', {
          'data': DateTime.now().toIso8601String(),
          'nome_treino': null,
        });

        for (final exercicio in sessao.exerciciosConcluidosHoje) {
          final int exercicioId = await txn.insert('exercicios', {
            'sessao_id': sessaoId,
            'nome': exercicio.nome,
            'grupo': exercicio.grupo,
          });

          for (final serie in exercicio.seriesDetalhes) {
            if (serie.peso == null || serie.reps == null) {
              throw ArgumentError(
                'Serie invalida para o exercicio "${exercicio.nome}": peso e reps nao podem ser nulos ao salvar.',
              );
            }

            await txn.insert('series', {
              'exercicio_id': exercicioId,
              'peso': serie.peso,
              'reps': serie.reps,
              'concluida': serie.concluida ? 1 : 0,
            });
          }
        }
      });
    } catch (e) {
      throw Exception('Erro ao salvar sessao de treino: $e');
    }
  }

  Future<List<SessaoTreino>> buscarHistoricoTreinos() async {
    try {
      final db = await _databaseHelper.database;

      final List<Map<String, Object?>> sessoesRows = await db.query(
        'sessoes',
        orderBy: 'id DESC',
      );

      final List<SessaoTreino> historico = [];

      for (final sessaoRow in sessoesRows) {
        final int sessaoId = (sessaoRow['id'] as num).toInt();

        final List<Map<String, Object?>> exerciciosRows = await db.query(
          'exercicios',
          where: 'sessao_id = ?',
          whereArgs: [sessaoId],
          orderBy: 'id ASC',
        );

        final List<Exercicio> exercicios = [];

        for (final exercicioRow in exerciciosRows) {
          final int exercicioId = (exercicioRow['id'] as num).toInt();

          final List<Map<String, Object?>> seriesRows = await db.query(
            'series',
            where: 'exercicio_id = ?',
            whereArgs: [exercicioId],
            orderBy: 'id ASC',
          );

          final List<Serie> series = seriesRows
              .map(
                (serieRow) => Serie(
                  peso: (serieRow['peso'] as num).toDouble(),
                  reps: (serieRow['reps'] as num).toInt(),
                  concluida: ((serieRow['concluida'] as num).toInt()) == 1,
                ),
              )
              .toList();

          exercicios.add(
            Exercicio(
              nome: exercicioRow['nome'] as String,
              grupo: exercicioRow['grupo'] as String,
              seriesDetalhes: series,
            ),
          );
        }

        historico.add(
          SessaoTreino(
            id: sessaoId,
            data: DateTime.parse(sessaoRow['data'] as String),
            exerciciosConcluidosHoje: exercicios,
          ),
        );
      }

      return historico;
    } catch (e) {
      throw Exception('Erro ao buscar historico de treinos: $e');
    }
  }
}
