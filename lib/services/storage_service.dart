import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Modelo do resultado do jogo
class GameResult {
  final double avgReaction; // Tempo médio de reação (ms)
  final double accuracyRate;         // Taxa de acertos (%)
  final int? gameTime;               // Tempo do jogo em segundos ou nulo (ilimitado)
  final DateTime dateTime;         // Data e hora da partida
  final List<double> reactionTimes;

  GameResult({
    required this.avgReaction,
    required this.accuracyRate,
    required this.gameTime,
    required this.dateTime,
    required this.reactionTimes,
  });

  // Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'averageReactionTime': avgReaction,
      'accuracyRate': accuracyRate,
      'gameTime': gameTime,
      'dateTime': dateTime.toIso8601String(),
      'reactionTimes': reactionTimes,
    };
  }

  // Cria a partir de JSON
  factory GameResult.fromJson(Map<String, dynamic> json) {
    return GameResult(
      avgReaction: json['averageReactionTime'],
      accuracyRate: json['accuracyRate'],
      gameTime: json['gameTime'],
      dateTime: DateTime.parse(json['dateTime']),
      reactionTimes: List<double>.from(json['reactionTimes'] ?? []),
    );
  }
}

// Serviço de armazenamento dos resultados
class StorageService {
  static const String _storageKey = 'game_results';

  /// Salva os resultados agrupados por tempo de jogo
  static Future<void> saveMatch(Map<String, List<GameResult>> data) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, List<String>> stringMap = {};

    data.forEach((key, list) {
      stringMap[key] = list.map((e) => jsonEncode(e.toJson())).toList();
    });

    final jsonString = jsonEncode(stringMap);
    await prefs.setString(_storageKey, jsonString);
  }

  /// Carrega os resultados agrupados por tempo de jogo
  static Future<Map<String, List<GameResult>>> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null) return {};

    final Map<String, dynamic> rawMap = jsonDecode(jsonString);
    final Map<String, List<GameResult>> result = {};

    rawMap.forEach((key, value) {
      final List<dynamic> list = value;
      result[key] = list
          .map((e) => GameResult.fromJson(jsonDecode(e as String)))
          .toList();
    });

    return result;
  }
}




