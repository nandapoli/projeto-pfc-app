import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static Future<void> saveReactionTime(double time) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> times = prefs.getStringList('reactionTimes') ?? [];
    times.add(time.toString());
    await prefs.setStringList('reactionTimes', times);
  }

  static Future<List<double>> loadReactionTimes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('reactionTimes')?.map(double.parse).toList() ?? [];
  }

  static Future<void> clearReactionTimes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('reactionTimes');
    prefs.clear;
    loadReactionTimes();
  }
}
