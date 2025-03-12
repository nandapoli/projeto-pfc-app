// Versão 0.7.0
// Nesta versão é possível apagar as médias de tempo de resposta salvas, e o aplicativo agora identifica se o tempo acabar sem nenhum dedo ser pressionado.
import 'package:flutter/material.dart'; // Importa a biblioteca principal do Flutter para interface gráfica
import 'package:http/http.dart' as http; // Importa a biblioteca para realizar requisições HTTP
import 'dart:convert'; // Importa a biblioteca para converter dados JSON
import 'dart:math'; // Importa a biblioteca para gerar números aleatórios
import 'dart:async'; // Importa a biblioteca para manipular temporizadores
import 'package:shared_preferences/shared_preferences.dart'; // Importa a biblioteca para salvar dados localmente

void main() {
  runApp(const MyApp()); // Inicia o aplicativo
}

class MyApp extends StatelessWidget { // Classe principal do aplicativo
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove a barra de debug
      home: const MenuScreen(), // Define o menu como a tela principal
    );
  }
}

// Tela Inicial (Menu)
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<double> reactionAverages = []; // Lista para armazenar os tempos de reação

  @override
  void initState() {
    super.initState();
    loadReactionAverages(); // Carrega os tempos salvos ao iniciar
  }

  Future<void> loadReactionAverages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      reactionAverages = prefs.getStringList('reactionAverages')?.map((e) => double.parse(e)).toList() ?? [];
    });
  }

  Future<void> clearReactionTimes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('reactionAverages'); // Apaga os tempos salvos
    setState(() {
      reactionAverages.clear(); // Atualiza a interface
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Exercícios de Dedos"), backgroundColor: Colors.blue),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FingerGameScreen()), // Navega para a tela do exercício
                ).then((_) => loadReactionAverages()); // Atualiza os tempos ao voltar
              },
              child: const Text("Iniciar", style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 20),
                        ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Médias de Tempo"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: reactionAverages.isNotEmpty
                          ? reactionAverages.map((avg) => Text("${avg.toStringAsFixed(2)} ms", style: const TextStyle(fontSize: 18))).toList()
                          : [const Text("Nenhuma média salva ainda.")],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fechar")),
                      TextButton(onPressed: clearReactionTimes, child: const Text("Apagar Tudo"))
                    ],
                  ),
                );
              },
              child: const Text("Ver Médias", style: TextStyle(fontSize: 24)),
            ),
          ],
        ),
      ),
    );
  }
}

// Tela do Jogo
class FingerGameScreen extends StatefulWidget {
  const FingerGameScreen({super.key}); // Construtor da tela

  @override
  // ignore: library_private_types_in_public_api
  _FingerGameScreenState createState() => _FingerGameScreenState(); // Cria o estado da tela
}

class _FingerGameScreenState extends State<FingerGameScreen> {
  final String esp32Url = "http://192.168.4.1/status"; // Define a URL do ESP32
  final List<String> fingers = ["Polegar", "Indicador", "Médio", "Anelar", "Mindinho"]; // Lista com os dedos disponíveis

  late String targetFinger; // Define qual dedo precisa ser pressionado
  int timeLeft = 60; // Tempo restante do exercício
  bool success = false, gameOver = false; // Indica se o usuário pressionou o dedo correto e se o exercício acabou
  Timer? gameTimer, checkTimer; // Timers para verificar o tempo de exercício e o estado dos botões
  DateTime? startTime; // Armazena o momento em que um novo dedo é mostrado
  List<int> reactionTimes = []; // Lista para armazenar os tempos de reação

  @override
  void initState() {
    super.initState();
    startGame(); // Inicia o exercício quando a tela é carregada
  }

  @override
  void dispose() {
    gameTimer?.cancel(); // Cancela o timer do jogo ao sair da tela
    checkTimer?.cancel(); // Cancela o timer de verificação ao sair da tela
    super.dispose();
  }

  // Inicializa o exercício
  void startGame() {
    gameOver = false; // Reinicia o estado do exercício
    timeLeft = 60; // Reinicia o tempo restante
    reactionTimes.clear(); // Limpa os tempos de reação
    pickRandomFinger(); // Escolhe um dedo aleatório para começar
    startTimers(); // Inicia os timers
  }

  // Escolhe um dedo aleatório
  void pickRandomFinger() {
    setState(() {
      success = false; // Reinicia o estado de sucesso
      targetFinger = fingers[Random().nextInt(fingers.length)]; // Seleciona um dedo aleatoriamente
      startTime = DateTime.now(); // Armazena o momento que o dedo foi mostrado
    });
  }

  // Inicia os timers para verificação e tempo do exercício
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

    checkTimer = Timer.periodic(const Duration(milliseconds: 10), (_) => checkFingerPress()); // Verifica o estado dos dedos a cada 100ms
  }

  // Verifica o estado dos dedos no ESP32
  Future<void> checkFingerPress() async {
    if (gameOver) return; // Não verifica se o exercício tiver encerrado

    try {
      final response = await http.get(Uri.parse(esp32Url)); // Faz uma requisição GET ao ESP32
      if (response.statusCode == 200) { // Verifica se a resposta foi bem-sucedida
        final Map<String, dynamic> fingerStates = json.decode(utf8.decode(response.bodyBytes)); // Decodifica a resposta JSON

        if (fingerStates[targetFinger] == 1 && !success) { // Verifica se o dedo correto foi pressionado
          int reactionTime = DateTime.now().difference(startTime!).inMilliseconds; // Calcula o tempo de reação
          reactionTimes.add(reactionTime); // Adiciona à lista de tempos de reação
          setState(() => success = true); // Define que o usuário acertou
          Future.delayed(const Duration(milliseconds: 500), pickRandomFinger); // Aguarda 0,5 segundo antes de escolher outro dedo
        }
      }
    } catch (_) {
      debugPrint("Erro ao conectar ao ESP32."); // Imprime uma mensagem de erro caso a conexão falhe
    }
  }

  // Salva os tempos de reação
  Future<void> saveReactionAverage() async {
     if (reactionTimes.isEmpty) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double average = reactionTimes.reduce((a, b) => a + b) / reactionTimes.length;
    List<String> savedAverages = prefs.getStringList('reactionAverages') ?? [];
    savedAverages.add(average.toString());
    await prefs.setStringList('reactionAverages', savedAverages);
  }

  // Encerra o exercício
  void endGame() {
    gameTimer?.cancel(); // Cancela o temporizador do exercício
    checkTimer?.cancel(); // Cancela o temporizador de verificação
    setState(() => gameOver = true); // Define o estado do exercício como encerrado
    if (reactionTimes.isNotEmpty){
      saveReactionAverage();
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






