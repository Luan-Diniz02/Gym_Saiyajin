import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String keyTempoDescanso = 'treino_tempo_descanso_padrao';
  static const String keyPesoAtual = 'progresso_peso_atual';
  static const String keyAltura = 'progresso_altura';
  static const String keyMetaDiasSemana = 'progresso_meta_dias_semana';
  static const String keyDataUltimaAtualizacaoPeso = 'progresso_data_ultima_atualizacao_peso';

  Future<void> salvarInt(String chave, int valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(chave, valor);
  }

  Future<int?> lerInt(String chave) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(chave);
  }

  Future<void> salvarDouble(String chave, double valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(chave, valor);
  }

  Future<double?> lerDouble(String chave) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(chave);
  }

  Future<void> salvarString(String chave, String valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(chave, valor);
  }

  Future<String?> lerString(String chave) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(chave);
  }

  Future<void> remover(String chave) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(chave);
  }
}