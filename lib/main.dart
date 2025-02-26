// Versão 0.2.0
// Esta versão escolhe dedos aleatoriamente e espera que o dedo correto faça contato.
import 'package:flutter/material.dart'; // Biblioteca principal do Flutter
import 'package:http/http.dart' as http; // Biblioteca para requisições HTTP
import 'dart:convert'; // Biblioteca para trabalhar com JSON
import 'dart:math'; // Biblioteca para gerar números aleatórios
import 'dart:async'; // Biblioteca para usar Timer

void main() {
  runApp(const MyApp()); // Inicia o aplicativo
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false, // Oculta a faixa de debug
      home: FingerGameScreen(), // Define a tela principal
    );
  }
}

class FingerGameScreen extends StatefulWidget {
  const FingerGameScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _FingerGameScreenState createState() => _FingerGameScreenState();
}

class _FingerGameScreenState extends State<FingerGameScreen> {
  final String esp32Url = "http://192.168.4.1/status"; //IP do ESP32

  // Lista com os nomes dos dedos
  final List<String> fingers = ["Polegar", "Indicador", "Médio", "Anelar", "Mindinho"];
  String targetFinger = ""; // Dedo que o usuário precisa pressionar
  bool success = false; // Indica se o usuário acertou
  Timer? timer; // Timer para checagem automática

  @override
  void initState() {
    super.initState();
    pickRandomFinger(); // Escolhe um dedo aleatório ao iniciar
    startChecking(); // Inicia a verificação automática
  }

  @override
  void dispose() {
    timer?.cancel(); // Cancela o timer ao sair do app
    super.dispose();
  }

  // Escolhe um dedo aleatoriamente
  void pickRandomFinger() {
    setState(() {
      success = false; // Reseta o estado de acerto
      targetFinger = fingers[Random().nextInt(fingers.length)]; // Escolhe um dedo aleatório
    });
  }

  // Inicia a verificação automática
  void startChecking() {
    timer = Timer.periodic(const Duration(milliseconds: 100), (Timer t) {
      checkFingerPress();
    });
  }

  // Busca os estados dos dedos no ESP32
  Future<void> checkFingerPress() async {
    try {
      final response = await http.get(Uri.parse(esp32Url)); // Faz requisição HTTP ao ESP32
      if (response.statusCode == 200) {
        Map<String, dynamic> fingerStates = json.decode(utf8.decode(response.bodyBytes)); // Converte JSON para Map

        // Verifica se o dedo correto foi pressionado
        if (fingerStates[targetFinger] == 1 && !success) {
          setState(() {
            success = true; // Indica que o usuário acertou
          });

          // Aguarda 1 segundo e escolhe outro dedo
          Future.delayed(const Duration(seconds: 1), pickRandomFinger);
        }
      } else {
        debugPrint("Erro ao buscar os dados: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erro de conexão: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pressione o dedo certo!"),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Exibe o dedo que deve ser pressionado
            Text(
              "Pressione: $targetFinger",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Mensagem de acerto
            if (success)
              const Text(
                "✅ Acertou!",
                style: TextStyle(fontSize: 30, color: Colors.green, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}



