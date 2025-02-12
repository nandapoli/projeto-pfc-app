// Versão 0.1.1
// Esta versão recebe os dados do estado do contato de cada dedo em formato JSON do localhost e os mostra na tela.
import 'dart:async'; // Biblioteca para lidar com operações assíncronas e timers
import 'dart:convert'; // Biblioteca para converter dados JSON
import 'package:flutter/material.dart'; // Biblioteca principal do Flutter para interface gráfica
import 'package:http/http.dart' as http; // Biblioteca para fazer requisições HTTP

void main() {
  runApp(MyApp()); // Inicia o aplicativo Flutter
}

// Classe principal do aplicativo
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove a faixa de debug
      title: 'Monitor de Botões', // Nome do aplicativo
      theme: ThemeData(primarySwatch: Colors.blue), // Define um tema azul
      home: ESP32Monitor(), // Define a tela principal do aplicativo
    );
  }
}

// Tela principal que exibe o status dos contatos
class ESP32Monitor extends StatefulWidget {
  const ESP32Monitor({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ESP32MonitorState createState() => _ESP32MonitorState();
}

class _ESP32MonitorState extends State<ESP32Monitor> {
  // IP do ESP32
  String esp32Ip = "192.168.100.20";

  // Mapa que armazena o estado dos contatos
  Map<String, int> estados = {
    "botao1": 1,
    "botao2": 1,
    "botao3": 1,
    "botao4": 1,
    "botao5": 1,
  };

  late Timer timer; // Timer para atualizar os dados periodicamente

  @override
  void initState() {
    super.initState();
    fetchData(); // Obtém os dados ao iniciar o aplicativo
    timer = Timer.periodic(Duration(milliseconds: 100), (Timer t) => fetchData()); // Inicia um Timer que atualiza os dados automaticamente a cada 100 milissegundos
  }

  @override
  void dispose() {
    timer.cancel(); // Cancela o Timer para evitar chamadas desnecessárias
    super.dispose();
  }

  // Função para buscar os estados dos contatos do ESP32
  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse("http://$esp32Ip/dados")); // Faz uma requisição GET para o ESP32

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body); // Se a resposta for bem-sucedida, converte o JSON recebido
        setState(() {
          // Atualiza os estados dos contatos com os dados recebidos
          estados["botao1"] = data['botao1'];
          estados["botao2"] = data['botao2'];
          estados["botao3"] = data['botao3'];
          estados["botao4"] = data['botao4'];
          estados["botao5"] = data['botao5'];
        });
      } else {
        debugPrint("Erro ao buscar dados: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erro de conexão: $e");
    }
  }

  // Widget que exibe o estado de cada contato
  Widget buildBotaoWidget(String nome, int estado) {
    return Card(
      color: estado == 0 ? Colors.green : Colors.red, // Ícone verde/vermelho
      child: ListTile(
        title: Text( // Nome do dedo no ícone
          nome.toUpperCase(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        subtitle: Text( // Estado do contato do dedo
          estado == 0 ? "Pressionado" : "Solto",
          style: TextStyle(fontSize: 18, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Estados dos Dedos")), // Barra superior do aplicativo
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Cria um widget para cada dedo, mostrando o estado do contato
            buildBotaoWidget("Polegar", estados["botao1"]!),
            buildBotaoWidget("Indicador", estados["botao2"]!),
            buildBotaoWidget("Médio", estados["botao3"]!),
            buildBotaoWidget("Anelar", estados["botao4"]!),
            buildBotaoWidget("Mindinho", estados["botao5"]!),
            SizedBox(height: 20)
          ],
        ),
      ),
    );
  }
}


