import 'package:http/http.dart' as http;

class Esp32Service {
  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(Uri.parse("http://192.168.4.1/status"));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
