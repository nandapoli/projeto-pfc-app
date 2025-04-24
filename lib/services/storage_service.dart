import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Método estático para salvar uma média e taxa de acerto de uma partida
  static Future<void> saveMatch(double avgReactionTime, double accuracy) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Carrega listas existentes ou inicia vazias
    List<String> reactionList = prefs.getStringList('reactionHistory') ?? [];
    List<String> accuracyList = prefs.getStringList('accuracyHistory') ?? [];

    // Adiciona os novos dados convertidos para string
    reactionList.add(avgReactionTime.toStringAsFixed(2));
    accuracyList.add(accuracy.toStringAsFixed(1));

    // Salva de volta no SharedPreferences
    await prefs.setStringList('reactionHistory', reactionList);
    await prefs.setStringList('accuracyHistory', accuracyList);
  }

  // Método estático para carregar os dados salvos
  static Future<List<Map<String, String>>> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String> reactionList = prefs.getStringList('reactionHistory') ?? [];
    List<String> accuracyList = prefs.getStringList('accuracyHistory') ?? [];

    List<Map<String, String>> history = [];

    for (int i = 0; i < reactionList.length; i++) {
      history.add({
        'reaction': reactionList[i],
        'accuracy': i < accuracyList.length ? accuracyList[i] : '0',
      });
    }

    return history;
  }

  // Método para apagar os dados
  static Future<void> clearHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('reactionHistory');
    await prefs.remove('accuracyHistory');
  }
}



