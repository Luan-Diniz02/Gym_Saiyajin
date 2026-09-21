import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
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
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _createDB,
      onUpgrade: _onUpgradeDB,
    );
  }

  Future _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE sessoes ADD COLUMN duracao_segundos INTEGER DEFAULT 0;',
      );
      await db.execute(
        'ALTER TABLE sessoes ADD COLUMN descanso_total_segundos INTEGER DEFAULT 0;',
      );
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS fichas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL,
          descricao TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS ficha_exercicios (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ficha_id INTEGER NOT NULL,
          nome TEXT NOT NULL,
          grupo TEXT NOT NULL,
          ordem INTEGER NOT NULL DEFAULT 0,
          series_padrao INTEGER NOT NULL DEFAULT 3,
          FOREIGN KEY (ficha_id) REFERENCES fichas (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('CREATE INDEX IF NOT EXISTS idx_ficha_exercicios_ficha_id ON ficha_exercicios (ficha_id)');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT NOT NULL,
        nome_treino TEXT,
        duracao_segundos INTEGER DEFAULT 0,
        descanso_total_segundos INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE exercicios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sessao_id INTEGER NOT NULL,
        nome TEXT NOT NULL,
        grupo TEXT NOT NULL,
        FOREIGN KEY (sessao_id) REFERENCES sessoes (id) ON DELETE CASCADE
      )
    ''');

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

    await db.execute('''
      CREATE TABLE fichas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        descricao TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ficha_exercicios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ficha_id INTEGER NOT NULL,
        nome TEXT NOT NULL,
        grupo TEXT NOT NULL,
        ordem INTEGER NOT NULL DEFAULT 0,
        series_padrao INTEGER NOT NULL DEFAULT 3,
        FOREIGN KEY (ficha_id) REFERENCES fichas (id) ON DELETE CASCADE
      )
    ''');

    // Criação de índices para otimizar buscas e o ON DELETE CASCADE
    await db.execute('CREATE INDEX idx_exercicios_sessao_id ON exercicios (sessao_id)');
    await db.execute('CREATE INDEX idx_series_exercicio_id ON series (exercicio_id)');
    await db.execute('CREATE INDEX idx_ficha_exercicios_ficha_id ON ficha_exercicios (ficha_id)');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}