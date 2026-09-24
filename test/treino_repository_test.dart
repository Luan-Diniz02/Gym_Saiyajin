import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/database/db_helper.dart';
import 'package:gym_saiyajin/models/exercicio.dart';
import 'package:gym_saiyajin/models/ficha_treino.dart';
import 'package:gym_saiyajin/models/serie.dart';
import 'package:gym_saiyajin/models/sessao_treino.dart';
import 'package:gym_saiyajin/repositories/treino_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late DatabaseHelper dbHelper;
  late TreinoRepository repository;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
          await DatabaseHelper.createSchema(db);
        },
      ),
    );

    dbHelper = DatabaseHelper.withDatabase(db);
    repository = TreinoRepository(databaseHelper: dbHelper);
  });

  tearDown(() async {
    await db.close();
  });

  group('TreinoRepository - Sessões de Treino', () {
    test('deve salvar e recuperar uma sessão de treino completa', () async {
      final sessao = SessaoTreino(
        data: DateTime(2026, 9, 23, 10, 0),
        nomeTreino: 'Treino A - Super Saiyajin',
        duracaoSegundos: 3600,
        descansoTotalSegundos: 600,
        exerciciosConcluidosHoje: [
          Exercicio(
            nome: 'Supino Reto',
            grupo: 'Peito',
            seriesDetalhes: [
              Serie(peso: 80.0, reps: 10, concluida: true),
              Serie(peso: 90.0, reps: 8, concluida: true),
              Serie(peso: 100.0, reps: 5, concluida: true),
            ],
          ),
          Exercicio(
            nome: 'Desenvolvimento Militar',
            grupo: 'Ombros',
            seriesDetalhes: [
              Serie(peso: 50.0, reps: 8, concluida: true),
            ],
          ),
        ],
      );

      await repository.salvarSessaoTreino(sessao);

      final historico = await repository.buscarHistoricoTreinos();
      expect(historico.length, 1);

      final salva = historico.first;
      expect(salva.nomeTreino, 'Treino A - Super Saiyajin');
      expect(salva.duracaoSegundos, 3600);
      expect(salva.descansoTotalSegundos, 600);
      expect(salva.exerciciosConcluidosHoje.length, 2);

      final supino = salva.exerciciosConcluidosHoje.firstWhere((e) => e.nome == 'Supino Reto');
      expect(supino.grupo, 'Peito');
      expect(supino.seriesDetalhes.length, 3);
      expect(supino.seriesDetalhes[0].peso, 80.0);
      expect(supino.seriesDetalhes[0].reps, 10);
      expect(supino.seriesDetalhes[0].concluida, isTrue);
      expect(supino.seriesDetalhes[2].peso, 100.0);
      expect(supino.seriesDetalhes[2].reps, 5);
    });

    test('deve lançar ArgumentError ao tentar salvar série com peso ou reps nulos', () async {
      final sessao = SessaoTreino(
        data: DateTime.now(),
        nomeTreino: 'Treino Invalido',
        exerciciosConcluidosHoje: [
          Exercicio(
            nome: 'Agachamento',
            grupo: 'Pernas',
            seriesDetalhes: [
              Serie(peso: null, reps: 10, concluida: true),
            ],
          ),
        ],
      );

      expect(
        () async => await repository.salvarSessaoTreino(sessao),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('deve excluir sessão e respeitar exclusão em cascata (ON DELETE CASCADE)', () async {
      final sessao = SessaoTreino(
        data: DateTime.now(),
        nomeTreino: 'Treino para Excluir',
        exerciciosConcluidosHoje: [
          Exercicio(
            nome: 'Levantamento Terra',
            grupo: 'Costas',
            seriesDetalhes: [
              Serie(peso: 120.0, reps: 5, concluida: true),
            ],
          ),
        ],
      );

      await repository.salvarSessaoTreino(sessao);
      final sessoes = await repository.buscarHistoricoTreinos();
      expect(sessoes.length, 1);
      final sessaoId = sessoes.first.id!;

      await repository.excluirSessaoTreino(sessaoId);

      final sessoesApos = await repository.buscarHistoricoTreinos();
      expect(sessoesApos.isEmpty, isTrue);

      final exerciciosNoBanco = await db.query('exercicios', where: 'sessao_id = ?', whereArgs: [sessaoId]);
      expect(exerciciosNoBanco.isEmpty, isTrue);

      final seriesNoBanco = await db.query('series');
      expect(seriesNoBanco.isEmpty, isTrue);
    });

    test('deve buscar últimas séries de um exercício específico com ordenação correta', () async {
      // Sessão 1 (mais antiga)
      await repository.salvarSessaoTreino(
        SessaoTreino(
          data: DateTime(2026, 9, 1),
          nomeTreino: 'Treino Antigo',
          exerciciosConcluidosHoje: [
            Exercicio(
              nome: 'Barra Fixa',
              grupo: 'Costas',
              seriesDetalhes: [
                Serie(peso: 0.0, reps: 8, concluida: true),
              ],
            ),
          ],
        ),
      );

      // Sessão 2 (mais recente)
      await repository.salvarSessaoTreino(
        SessaoTreino(
          data: DateTime(2026, 9, 20),
          nomeTreino: 'Treino Recente',
          exerciciosConcluidosHoje: [
            Exercicio(
              nome: 'Barra Fixa',
              grupo: 'Costas',
              seriesDetalhes: [
                Serie(peso: 10.0, reps: 10, concluida: true),
                Serie(peso: 15.0, reps: 8, concluida: true),
              ],
            ),
          ],
        ),
      );

      final ultimasSeries = await repository.buscarUltimasSeriesExercicio('Barra Fixa');
      expect(ultimasSeries.length, 2);
      expect(ultimasSeries[0].peso, 10.0);
      expect(ultimasSeries[0].reps, 10);
      expect(ultimasSeries[1].peso, 15.0);
      expect(ultimasSeries[1].reps, 8);
    });
  });

  group('TreinoRepository - Recordes Pessoais (PRs)', () {
    test('deve calcular e retornar recordes pessoais detalhados agregados', () async {
      await repository.salvarSessaoTreino(
        SessaoTreino(
          data: DateTime(2026, 9, 10),
          nomeTreino: 'Treino 1',
          exerciciosConcluidosHoje: [
            Exercicio(
              nome: 'Agachamento Livre',
              grupo: 'Pernas',
              seriesDetalhes: [
                Serie(peso: 100.0, reps: 10, concluida: true), // 1RM ~ 133.3
              ],
            ),
          ],
        ),
      );

      await repository.salvarSessaoTreino(
        SessaoTreino(
          data: DateTime(2026, 9, 15),
          nomeTreino: 'Treino 2',
          exerciciosConcluidosHoje: [
            Exercicio(
              nome: 'Agachamento Livre',
              grupo: 'Pernas',
              seriesDetalhes: [
                Serie(peso: 130.0, reps: 1, concluida: true), // Carga maior, mas 1RM = 130
              ],
            ),
          ],
        ),
      );

      final recordes = await repository.buscarRecordesPessoais();
      expect(recordes.length, 1);

      final recordeAgachamento = recordes.first;
      expect(recordeAgachamento.exercicioNome, 'Agachamento Livre');
      expect(recordeAgachamento.grupo, 'Pernas');
      expect(recordeAgachamento.cargaMaxima, 130.0);
      expect(recordeAgachamento.repsCargaMaxima, 1);
      expect(recordeAgachamento.umRepMaxEstimado, 133.3);
      expect(recordeAgachamento.peso1RM, 100.0);
      expect(recordeAgachamento.reps1RM, 10);
    });

    test('deve buscar recorde histórico prévio de um exercício', () async {
      await repository.salvarSessaoTreino(
        SessaoTreino(
          data: DateTime(2026, 8, 1),
          nomeTreino: 'Treino Base',
          exerciciosConcluidosHoje: [
            Exercicio(
              nome: 'Supino Inclinado',
              grupo: 'Peito',
              seriesDetalhes: [
                Serie(peso: 70.0, reps: 8, concluida: true),
              ],
            ),
          ],
        ),
      );

      final prHistorico = await repository.buscarRecordeHistoricoExercicio('Supino Inclinado');
      expect(prHistorico, isNotNull);
      expect(prHistorico!.cargaMaxima, 70.0);
      expect(prHistorico.repsCargaMaxima, 8);
    });
  });

  group('TreinoRepository - Fichas de Treino', () {
    test('deve executar CRUD completo de Fichas de Treino', () async {
      // 1. Inserir nova ficha
      final novaFicha = FichaTreino(
        nome: 'Ficha Saiyajin Hipertrofia',
        descricao: 'Treino pesado de hipertrofia',
        exercicios: [
          FichaExercicioItem(
            nome: 'Puxada Frontal',
            grupo: 'Costas',
            ordem: 0,
            seriesPadrao: 4,
          ),
          FichaExercicioItem(
            nome: 'Remada Curvada',
            grupo: 'Costas',
            ordem: 1,
            seriesPadrao: 3,
          ),
        ],
      );

      final fichaId = await repository.salvarFicha(novaFicha);
      expect(fichaId, isPositive);

      // 2. Buscar fichas cadastradas
      final fichas = await repository.buscarFichas();
      expect(fichas.length, 1);
      expect(fichas.first.id, fichaId);
      expect(fichas.first.nome, 'Ficha Saiyajin Hipertrofia');
      expect(fichas.first.descricao, 'Treino pesado de hipertrofia');
      expect(fichas.first.exercicios.length, 2);
      expect(fichas.first.exercicios[0].nome, 'Puxada Frontal');
      expect(fichas.first.exercicios[0].seriesPadrao, 4);
      expect(fichas.first.exercicios[1].nome, 'Remada Curvada');
      expect(fichas.first.exercicios[1].seriesPadrao, 3);

      // 3. Atualizar ficha (com mesmo ID)
      final fichaAtualizada = FichaTreino(
        id: fichaId,
        nome: 'Ficha Hipertrofia Z',
        descricao: 'Nova descrição',
        exercicios: [
          FichaExercicioItem(
            nome: 'Remada Unilateral (Serrote)',
            grupo: 'Costas',
            ordem: 0,
            seriesPadrao: 4,
          ),
        ],
      );

      await repository.salvarFicha(fichaAtualizada);

      final fichasAtualizadas = await repository.buscarFichas();
      expect(fichasAtualizadas.first.nome, 'Ficha Hipertrofia Z');
      expect(fichasAtualizadas.first.descricao, 'Nova descrição');
      expect(fichasAtualizadas.first.exercicios.length, 1);
      expect(fichasAtualizadas.first.exercicios.first.nome, 'Remada Unilateral (Serrote)');

      // 4. Excluir ficha e validar cascata
      await repository.excluirFicha(fichaId);
      final fichasAposExclusao = await repository.buscarFichas();
      expect(fichasAposExclusao.isEmpty, isTrue);

      final exerciciosOrfaos = await db.query('ficha_exercicios', where: 'ficha_id = ?', whereArgs: [fichaId]);
      expect(exerciciosOrfaos.isEmpty, isTrue);
    });
  });
}
