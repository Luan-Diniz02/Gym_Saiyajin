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
          'data': (sessao.data ?? DateTime.now()).toIso8601String(),
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
      
      if (sessoesRows.isEmpty) return [];

      final List<Map<String, Object?>> exerciciosRows = await db.query(
        'exercicios',
        orderBy: 'id ASC',
      );
      
      final List<Map<String, Object?>> seriesRows = await db.query(
        'series',
        orderBy: 'id ASC',
      );

      // Agrupando series por exercicio_id
      final Map<int, List<Serie>> seriesMap = {};
      for (final row in seriesRows) {
        final exId = (row['exercicio_id'] as num).toInt();
        seriesMap.putIfAbsent(exId, () => []).add(Serie(
          peso: (row['peso'] as num).toDouble(),
          reps: (row['reps'] as num).toInt(),
          concluida: ((row['concluida'] as num).toInt()) == 1,
        ));
      }

      // Agrupando exercicios por sessao_id
      final Map<int, List<Exercicio>> exerciciosMap = {};
      for (final row in exerciciosRows) {
        final sessaoId = (row['sessao_id'] as num).toInt();
        final exId = (row['id'] as num).toInt();
        exerciciosMap.putIfAbsent(sessaoId, () => []).add(Exercicio(
          nome: row['nome'] as String,
          grupo: row['grupo'] as String,
          seriesDetalhes: seriesMap[exId] ?? [],
        ));
      }

      // Construindo o historico
      final List<SessaoTreino> historico = [];
      for (final row in sessoesRows) {
        final sessaoId = (row['id'] as num).toInt();
        historico.add(
          SessaoTreino(
            id: sessaoId,
            data: DateTime.parse(row['data'] as String),
            exerciciosConcluidosHoje: exerciciosMap[sessaoId] ?? [],
          ),
        );
      }

      return historico;
    } catch (e) {
      throw Exception('Erro ao buscar historico de treinos: $e');
    }
  }

  Future<void> excluirSessaoTreino(int sessaoId) async {
    try {
      final db = await _databaseHelper.database;

      await db.transaction((txn) async {
        await txn.rawDelete(
          'DELETE FROM series WHERE exercicio_id IN (SELECT id FROM exercicios WHERE sessao_id = ?)',
          [sessaoId],
        );
        await txn.delete('exercicios', where: 'sessao_id = ?', whereArgs: [sessaoId]);
        await txn.delete('sessoes', where: 'id = ?', whereArgs: [sessaoId]);
      });
    } catch (e) {
      throw Exception('Erro ao excluir sessao de treino: $e');
    }
  }
}
