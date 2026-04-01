import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // Padrão Singleton: garante que só exista uma conexão aberta com o banco
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gym_saiyajin.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1, // Se precisarmos adicionar colunas no futuro, mudamos a versão
      onCreate: _createDB,
    );
  }

  // Criação das Tabelas usando SQL puro
  Future _createDB(Database db, int version) async {
    // Tabela 1: Sessoes de Treino (O "Pai")
    await db.execute('''
      CREATE TABLE sessoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT NOT NULL,
        nome_treino TEXT
      )
    ''');

    // Tabela 2: Exercicios realizados na Sessão (O "Filho")
    await db.execute('''
      CREATE TABLE exercicios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sessao_id INTEGER NOT NULL,
        nome TEXT NOT NULL,
        grupo TEXT NOT NULL,
        FOREIGN KEY (sessao_id) REFERENCES sessoes (id) ON DELETE CASCADE
      )
    ''');

    // Tabela 3: Séries de cada Exercicio (O "Neto")
    await db.execute('''
      CREATE TABLE series (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercicio_id INTEGER NOT NULL,
        peso REAL NOT NULL,
        reps INTEGER NOT NULL,
        concluida INTEGER NOT NULL,
        FOREIGN KEY (exercicio_id) REFERENCES exercicios (id) ON DELETE CASCADE
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}