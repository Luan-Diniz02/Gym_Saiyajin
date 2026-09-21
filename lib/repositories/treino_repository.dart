import '../database/db_helper.dart';
import '../models/exercicio.dart';
import '../models/ficha_treino.dart';
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
          'nome_treino': sessao.nomeTreino,
          'duracao_segundos': sessao.duracaoSegundos,
          'descanso_total_segundos': sessao.descansoTotalSegundos,
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

  Future<List<Map<String, String>>> buscarExerciciosUnicosRegistrados() async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, Object?>> rows = await db.rawQuery(
        'SELECT DISTINCT nome, grupo FROM exercicios ORDER BY nome ASC',
      );
      return rows.map((row) => {
        'nome': row['nome'] as String? ?? '',
        'grupo': row['grupo'] as String? ?? '',
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<SessaoTreino>> buscarHistoricoTreinos() async {
    try {
      final db = await _databaseHelper.database;

      final List<Map<String, Object?>> sessoesRows = await db.query(
        'sessoes',
        orderBy: 'data DESC',
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
            nomeTreino: row['nome_treino'] as String?,
            duracaoSegundos: (row['duracao_segundos'] as num?)?.toInt() ?? 0,
            descansoTotalSegundos:
                (row['descanso_total_segundos'] as num?)?.toInt() ?? 0,
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

  Future<void> limparTodoHistorico() async {
    try {
      final db = await _databaseHelper.database;
      await db.transaction((txn) async {
        await txn.delete('series');
        await txn.delete('exercicios');
        await txn.delete('sessoes');
      });
    } catch (e) {
      throw Exception('Erro ao limpar histórico: $e');
    }
  }

  Future<int> importarSessoes(List<SessaoTreino> sessoesNovas, {bool mesclar = true}) async {
    try {
      final db = await _databaseHelper.database;

      return await db.transaction<int>((txn) async {
        if (!mesclar) {
          await txn.delete('series');
          await txn.delete('exercicios');
          await txn.delete('sessoes');
        }

        final List<Map<String, Object?>> sessoesExistentes = mesclar
            ? await txn.query('sessoes', columns: ['data'])
            : [];
        final Set<String> datasExistentes = sessoesExistentes
            .map((r) => r['data'] as String? ?? '')
            .where((d) => d.isNotEmpty)
            .toSet();

        int importadas = 0;
        for (final sessao in sessoesNovas) {
          final dataIso = (sessao.data ?? DateTime.now()).toIso8601String();
          if (mesclar && datasExistentes.contains(dataIso)) {
            // Sessão já existe com mesma data ISO, pula para não duplicar
            continue;
          }

          final int sessaoId = await txn.insert('sessoes', {
            'data': dataIso,
            'nome_treino': sessao.nomeTreino,
            'duracao_segundos': sessao.duracaoSegundos,
            'descanso_total_segundos': sessao.descansoTotalSegundos,
          });

          for (final exercicio in sessao.exerciciosConcluidosHoje) {
            final int exercicioId = await txn.insert('exercicios', {
              'sessao_id': sessaoId,
              'nome': exercicio.nome,
              'grupo': exercicio.grupo,
            });

            for (final serie in exercicio.seriesDetalhes) {
              await txn.insert('series', {
                'exercicio_id': exercicioId,
                'peso': serie.peso ?? 0.0,
                'reps': serie.reps ?? 0,
                'concluida': serie.concluida ? 1 : 0,
              });
            }
          }

          datasExistentes.add(dataIso);
          importadas++;
        }

        return importadas;
      });
    } catch (e) {
      throw Exception('Erro ao importar sessões de treino: $e');
    }
  }

  Future<List<Serie>> buscarUltimasSeriesExercicio(String nomeExercicio) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, Object?>> exRows = await db.rawQuery('''
        SELECT e.id as ex_id
        FROM exercicios e
        JOIN sessoes s ON e.sessao_id = s.id
        WHERE LOWER(TRIM(e.nome)) = LOWER(TRIM(?))
        ORDER BY s.data DESC, e.id DESC
        LIMIT 1
      ''', [nomeExercicio]);

      if (exRows.isEmpty) return [];

      final exId = (exRows.first['ex_id'] as num).toInt();
      final List<Map<String, Object?>> seriesRows = await db.query(
        'series',
        where: 'exercicio_id = ?',
        whereArgs: [exId],
        orderBy: 'id ASC',
      );

      return seriesRows.map((row) => Serie(
        peso: (row['peso'] as num?)?.toDouble(),
        reps: (row['reps'] as num?)?.toInt(),
        concluida: ((row['concluida'] as num?)?.toInt() ?? 0) == 1,
      )).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<FichaTreino>> buscarFichas() async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, Object?>> fichasRows = await db.query('fichas', orderBy: 'nome ASC');
      if (fichasRows.isEmpty) return [];

      final List<Map<String, Object?>> itensRows = await db.query('ficha_exercicios', orderBy: 'ordem ASC, id ASC');

      final Map<int, List<FichaExercicioItem>> itensPorFicha = {};
      for (final row in itensRows) {
        final fId = (row['ficha_id'] as num).toInt();
        itensPorFicha.putIfAbsent(fId, () => []).add(
          FichaExercicioItem(
            id: (row['id'] as num?)?.toInt(),
            fichaId: fId,
            nome: row['nome'] as String? ?? '',
            grupo: row['grupo'] as String? ?? '',
            ordem: (row['ordem'] as num?)?.toInt() ?? 0,
            seriesPadrao: (row['series_padrao'] as num?)?.toInt() ?? 3,
          ),
        );
      }

      return fichasRows.map((row) {
        final fId = (row['id'] as num).toInt();
        return FichaTreino(
          id: fId,
          nome: row['nome'] as String? ?? '',
          descricao: row['descricao'] as String?,
          exercicios: itensPorFicha[fId] ?? [],
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> salvarFicha(FichaTreino ficha) async {
    try {
      final db = await _databaseHelper.database;

      return await db.transaction<int>((txn) async {
        int fichaId;
        if (ficha.id == null) {
          fichaId = await txn.insert('fichas', {
            'nome': ficha.nome.trim(),
            'descricao': ficha.descricao?.trim(),
          });
        } else {
          fichaId = ficha.id!;
          await txn.update(
            'fichas',
            {
              'nome': ficha.nome.trim(),
              'descricao': ficha.descricao?.trim(),
            },
            where: 'id = ?',
            whereArgs: [fichaId],
          );
          await txn.delete(
            'ficha_exercicios',
            where: 'ficha_id = ?',
            whereArgs: [fichaId],
          );
        }

        for (int i = 0; i < ficha.exercicios.length; i++) {
          final item = ficha.exercicios[i];
          await txn.insert('ficha_exercicios', {
            'ficha_id': fichaId,
            'nome': item.nome.trim(),
            'grupo': item.grupo.trim(),
            'ordem': i,
            'series_padrao': item.seriesPadrao,
          });
        }

        return fichaId;
      });
    } catch (e) {
      throw Exception('Erro ao salvar ficha de treino: $e');
    }
  }

  Future<void> excluirFicha(int fichaId) async {
    try {
      final db = await _databaseHelper.database;
      await db.transaction((txn) async {
        await txn.delete('ficha_exercicios', where: 'ficha_id = ?', whereArgs: [fichaId]);
        await txn.delete('fichas', where: 'id = ?', whereArgs: [fichaId]);
      });
    } catch (e) {
      throw Exception('Erro ao excluir ficha de treino: $e');
    }
  }
}
