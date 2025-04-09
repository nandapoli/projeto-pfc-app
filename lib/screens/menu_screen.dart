import 'package:flutter/material.dart'; // Importa a biblioteca do Flutter para interface gráfica
import 'time_selection_screen.dart'; // Importa a tela de seleção de tempo
import 'package:flutter_application_1/services/storage_service.dart'; // Importa o serviço de armazenamento dos tempos
import 'package:flutter_application_1/services/esp32_service.dart'; // Importa o serviço de conexão com o ESP32

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key}); // Construtor da tela do menu

  @override
  // ignore: library_private_types_in_public_api
  _MenuScreenState createState() => _MenuScreenState(); // Cria o estado do menu
}

class _MenuScreenState extends State<MenuScreen> {
  List<double> reactionTimes = []; // Lista para armazenar os tempos médios de reação
  bool isConnected = false; // Variável para armazenar o status da conexão com o ESP32

  @override
  void initState() {
    super.initState();
    loadReactionTimes(); // Carrega os tempos armazenados
    checkEsp32Connection(); // Verifica a conexão com o ESP32
  }

  // Função para carregar os tempos salvos
  Future<void> loadReactionTimes() async {
    List<double> times = await StorageService.loadReactionTimes();
    setState(() {
      reactionTimes = times; // Atualiza a lista de tempos na interface
    });
  }

  // Função para verificar a conexão com o ESP32
  Future<void> checkEsp32Connection() async {
    bool status = await Esp32Service.checkConnection();
    setState(() {
      isConnected = status; // Atualiza o status da conexão
    });
  }

  // Função para limpar os tempos armazenados
  Future<void> clearTimes() async {
    await StorageService.clearReactionTimes();
    setState(() {
      reactionTimes.clear(); // Atualiza a interface
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TimeSelectionScreen()),
                ).then((_) => loadReactionTimes());
              },
              child: const Text("Iniciar", style: TextStyle(fontSize: 24)),
            ),
                        ElevatedButton(
              onPressed: () {
                loadReactionTimes();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Médias de Tempo"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: reactionTimes.isNotEmpty
                          ? reactionTimes.map((avg) => Text("${avg.toStringAsFixed(2)} ms", style: const TextStyle(fontSize: 18))).toList()
                          : [const Text("Nenhuma média salva ainda.")],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fechar")),
                      TextButton(onPressed: StorageService.clearReactionTimes, child: const Text("Apagar Tudo"))
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
