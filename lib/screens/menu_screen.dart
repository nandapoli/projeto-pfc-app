import 'package:flutter/material.dart'; // Importa a biblioteca do Flutter para interface gráfica
import 'time_selection_screen.dart'; // Importa a tela de seleção de tempo
import 'package:flutter_application_1/services/storage_service.dart'; // Importa o serviço de armazenamento dos tempos
import 'history_screen.dart'; //Importa a tela de histórico
import 'package:flutter_application_1/services/esp32_service.dart'; // Importa o serviço de conexão com o ESP32

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key}); // Construtor da tela do menu

  @override
  // ignore: library_private_types_in_public_api
  State<MenuScreen> createState() => _MenuScreenState(); // Cria o estado do menu
}

class _MenuScreenState extends State<MenuScreen> {
  bool isConnected = false; // Variável para armazenar o status da conexão com o ESP32

  @override
  void initState() {
    super.initState();
    checkEsp32Connection(); // Verifica a conexão com o ESP32
  } 

  // Função para verificar a conexão com o ESP32
  Future<void> checkEsp32Connection() async {
    bool status = await Esp32Service.checkConnection();
    setState(() {
      isConnected = status; // Atualiza o status da conexão
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("ESP32: ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Icon(isConnected ? Icons.wifi : Icons.wifi_off, color: isConnected ? Colors.green : Colors.red),
                Text(isConnected ? " Conectado" : " Desconectado", style: TextStyle(fontSize: 18, color: isConnected ? Colors.green : Colors.red)),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TimeSelectionScreen()),
                );
              },
              child: const Text("Iniciar", style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await StorageService.loadData(); // Atualiza os dados
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryScreen()),
                );
              },
              child: const Text("Ver Histórico", style: TextStyle(fontSize: 25)),
            ),
          ],
        ),
      ),
    );
  }
}
