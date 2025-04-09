import 'package:flutter/material.dart'; // Importa a biblioteca do Flutter
import 'dart:convert'; // Importa a biblioteca para manipulação de JSON
import 'dart:math'; // Importa para gerar números aleatórios
import 'dart:async'; // Importa para uso de temporizadores
import 'package:http/http.dart' as http; // Importa para fazer requisições HTTP
import 'package:flutter_application_1/services/storage_service.dart'; // Importa o serviço de armazenamento dos tempos

class FingerGameScreen extends StatefulWidget {
  final int gameTimer;

  const FingerGameScreen({super.key, required this.gameTimer}); // Construtor da tela

  @override
  // ignore: library_private_types_in_public_api
  _FingerGameScreenState createState() => _FingerGameScreenState(); // Cria o estado do jogo
}

class _FingerGameScreenState extends State<FingerGameScreen> {
  final String esp32Url = "http://192.168.4.1/status"; // URL do ESP32
  final List<String> fingers = ["Polegar", "Indicador", "Médio", "Anelar", "Mindinho"]; // Lista de dedos

  late String targetFinger; // Dedo que deve ser pressionado
  late int timeLeft; // Tempo restante do exercício
  bool success = false, gameOver = false; // Variáveis de controle
  Timer? gameTimer, checkTimer; // Timers do jogo
  DateTime? startTime; // Momento em que o dedo foi mostrado
  List<int> reactionTimes = []; // Lista de tempos de reação em milissegundos

  final Random _random = Random(); // Gerador de números aleatórios

  @override
  void initState() {
    super.initState();
    startGame(); // Inicia o jogo
  }

@override
  void dispose() {
    gameTimer?.cancel(); // Cancela o timer do jogo ao sair da tela
    checkTimer?.cancel(); // Cancela o timer de verificação ao sair da tela
    super.dispose();
  }

  void startGame() {
    gameOver = false;
    timeLeft = widget.gameTimer; // Reinicia o tempo restante
    reactionTimes.clear();
    pickRandomFinger();
    startTimers();
  }

  void pickRandomFinger() {
    setState(() {
      success = false;
      targetFinger = fingers[_random.nextInt(fingers.length)];
      startTime = DateTime.now();
    });
  }

  void startTimers() {
    gameTimer?.cancel();
    checkTimer?.cancel();

    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) { // Verifica se ainda há tempo restante
        setState(() => timeLeft--); // Decrementa o tempo restante
      } else {
        endGame(); // Encerra o jogo se o tempo acabar
      }
    });
    checkTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => checkFingerPress());
  }

  Future<void> checkFingerPress() async {
    if (gameOver) return;

    try {
      final response = await http.get(Uri.parse(esp32Url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> fingerStates = json.decode(utf8.decode(response.bodyBytes));

        if (fingerStates[targetFinger] == 1 && !success) {
          int reactionTime = DateTime.now().difference(startTime!).inMilliseconds;
          reactionTimes.add(reactionTime);
          setState(() => success = true);

          // Gera um delay aleatório entre 100 ms e 5000 ms (5 s)
          int randomDelay = 100 + _random.nextInt(4900);

          Future.delayed(Duration(milliseconds: randomDelay), pickRandomFinger);
        }
      }
    } catch (_) {
      debugPrint("Erro ao conectar ao ESP32.");
    }
  }

  void endGame() {
    gameTimer?.cancel();
    checkTimer?.cancel();
    setState(() => gameOver = true);

    if (reactionTimes.isNotEmpty) {
      double avgTime = (reactionTimes.reduce((a, b) => a + b) / reactionTimes.length);
      StorageService.saveReactionTime(avgTime);
    }
  }
  
@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pressione o dedo certo"), backgroundColor: Colors.blue), // Barra superior da tela
      body: Center(
        child: gameOver
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("⏳ Tempo Esgotado!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 20),
                  reactionTimes.isEmpty
                      ?Text("Nenhum dedo foi pressionado.", style: const TextStyle(fontSize: 20))
                      :Text("Média: ${(reactionTimes.reduce((a, b) => a + b) / reactionTimes.length).toStringAsFixed(2)} ms", style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: startGame, child: const Text("🔄 Reiniciar exercício", style: TextStyle(fontSize: 20))),
                  const SizedBox(height: 10),
                  ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Voltar ao Menu", style: TextStyle(fontSize: 20))),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Tempo Restante: $timeLeft s", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Text("Pressione: $targetFinger", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  if (success) const Text("✅ Acertou!", style: TextStyle(fontSize: 30, color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }

}
