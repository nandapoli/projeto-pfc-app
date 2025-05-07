import 'package:flutter/material.dart'; // Importa a biblioteca do Flutter
import 'package:flutter_application_1/screens/menu_screen.dart';
import 'dart:convert'; // Importa a biblioteca para manipulação de JSON
import 'dart:math'; // Importa para gerar números aleatórios
import 'dart:async'; // Importa para uso de temporizadores
import 'package:http/http.dart' as http; // Importa para fazer requisições HTTP
import 'package:flutter_application_1/services/storage_service.dart'; // Importa o serviço de armazenamento dos tempos

class FingerGameScreen extends StatefulWidget {
  final int? gameTimer;
  const FingerGameScreen({super.key, this.gameTimer}); // Construtor da tela

  @override
  // ignore: library_private_types_in_public_api
  _FingerGameScreenState createState() => _FingerGameScreenState(); // Cria o estado do jogo
}

class _FingerGameScreenState extends State<FingerGameScreen> {
  final String esp32Url = "http://192.168.4.1/status"; // URL do ESP32
  final List<String> fingers = ["Polegar", "Indicador", "Médio", "Anelar", "Mindinho"]; // Lista de dedos

  late String targetFinger; // Dedo que deve ser pressionado
  late int timeLeft; // Tempo restante do exercício
  int correctCount = 0, totaltries = 0; // Contador de erros cometidos
  bool success = false, wrong = false, gameOver = false; // Variáveis de controle
  Timer? gameTimer, checkTimer; // Timers do jogo
  DateTime? startTime; // Momento em que o dedo foi mostrado
  List<double> reactionTimes = []; // Lista de tempos de reação em milissegundos

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
    correctCount = 0; // Reinicia o contador de erros
    totaltries = 0;
    if (widget.gameTimer != null) {
    timeLeft = widget.gameTimer!;
  } else {
    timeLeft = -1; // Sem limite de tempo
  }
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
    if (widget.gameTimer != null){
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) { // Verifica se ainda há tempo restante
        setState(() => timeLeft--); // Decrementa o tempo restante
      } else {
        endGame(); // Encerra o jogo se o tempo acabar
      }
    });
    }
    checkTimer = Timer.periodic(const Duration(milliseconds: 50), (_) => checkFingerPress());
  }

  Future<void> checkFingerPress() async {
    if (gameOver) return; // Se o jogo acabou, não verifica nada

    try {
      final response = await http.get(Uri.parse(esp32Url)); // Faz requisição HTTP para o ESP32
      if (response.statusCode == 200) {
        final Map<String, dynamic> fingerStates = json.decode(utf8.decode(response.bodyBytes)); // Decodifica a resposta JSON
        if (!success) {
          // Verifica se o dedo correto foi pressionado
          if (fingerStates[targetFinger] == 1) {
            double reactionTime = DateTime.now().difference(startTime!).inMilliseconds.toDouble(); // Calcula o tempo de reação em milissegundos
            reactionTimes.add(reactionTime); // Adiciona à lista de tempos
            setState(() => success = true);
            totaltries++;
            correctCount++;
            // Gera um delay aleatório entre 100 ms e 3000 ms (3s)
            int randomDelay = 200 + _random.nextInt(2300);
            Future.delayed(Duration(milliseconds: randomDelay), pickRandomFinger);
        } else{
          // Verifica se algum dedo errado foi pressionado
          for (String finger in fingers) {
            if (finger != targetFinger && fingerStates[finger] == 1) {
              setState(() {
                success = false;
                wrong = true;
              });
              // Apaga a mensagem de erro depois de 0,8 segundo
              Future.delayed(const Duration(milliseconds: 800), () {
                if (mounted){
                  setState(() => wrong = false);
                  totaltries++;
                }
              });
              break;
            } 
          }  
        }
        }
      }
    } catch (_) {
      debugPrint("Erro ao conectar ao ESP32.");
    }
  }

  

  Future<void> endGame() async {
    gameTimer?.cancel(); // Para os timers
    checkTimer?.cancel();

    final double avgReaction = reactionTimes.isNotEmpty
        ? reactionTimes.reduce((a, b) => a + b) / reactionTimes.length
        : 0.0; // Calcula média

    final double accuracy = totaltries > 0 ? (correctCount / totaltries) * 100 : 0; // Calcula taxa de acerto
    final result = GameResult(
      avgReaction: avgReaction,
      accuracyRate: accuracy,
      gameTime: widget.gameTimer,
      dateTime: DateTime.now(),
      reactionTimes: List.from(reactionTimes),
    );
    final all = await StorageService.loadData();
    final key = widget.gameTimer?.toString() ?? 'ilimitado';

    if (!all.containsKey(key)) {
      all[key] = [];
    }

    all[key]!.add(result);
    await StorageService.saveMatch(all);

    setState(() => gameOver = true); // Atualiza UI para mostrar o fim do jogo
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
                  const Text("Exercício Encerrado!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 20),
                  totaltries == 0
                      ?Text("Nenhum dedo foi pressionado corretamente.", style: const TextStyle(fontSize: 20), textAlign: TextAlign.center)
                      :Text("Média: ${(reactionTimes.reduce((a, b) => a + b) / reactionTimes.length).toStringAsFixed(2)} ms", style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 10),
                      Text("Taxa de Acertos: $correctCount / $totaltries = ${totaltries == 0 ? 0 : ((correctCount / totaltries) * 100).toStringAsFixed(1)}%"),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: startGame, child: const Text("🔄 Reiniciar exercício", style: TextStyle(fontSize: 20))),
                  const SizedBox(height: 10),
                  ElevatedButton(onPressed: () {Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MenuScreen()),);
                  }, 
                  child: const Text("Voltar ao Menu", style: TextStyle(fontSize: 20))),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  widget.gameTimer != null? Text('Tempo: $timeLeft s', style: const TextStyle(fontSize: 24))
                                          : Text('Tempo: Ilimitado', style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 20),
                  Text("Pressione: $targetFinger", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  if (wrong) const Text("❌ Errou!", style: TextStyle(fontSize: 28, color: Colors.red, fontWeight: FontWeight.bold))
                  else if (success && !wrong) const Text("✅ Acertou!", style: TextStyle(fontSize: 30, color: Colors.green, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 40),
                  ElevatedButton(onPressed: endGame, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), 
                    child: const Text("Encerrar exercício", style: TextStyle(fontSize: 20, color: Colors.white))),
                ],
              ),
      ),
    );
  }

}
