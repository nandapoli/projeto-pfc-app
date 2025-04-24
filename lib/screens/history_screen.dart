import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/storage_service.dart'; // Importa o serviço de armazenamento

// Tela que exibe o histórico das partidas
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, String>> history = []; // Lista com o histórico das partidas

  @override
  void initState() {
    super.initState();
    _loadHistory(); // Carrega os dados ao iniciar a tela
  }

  // Método que carrega os dados usando o StorageService
  Future<void> _loadHistory() async {
    final loadedHistory = await StorageService.loadData(); // Carrega os dados do SharedPreferences
    setState(() {
      history = loadedHistory; // Atualiza o estado da tela com o histórico carregado
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Histórico de Partidas"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: history.isEmpty
            ? const Center(child: Text("Nenhum dado salvo ainda."))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Tempo Médio (ms)", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("Taxa de Acerto (%)", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final game = history[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${game['reaction']}"),
                              Text("${game['accuracy']}"),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        await StorageService.clearHistory(); // Limpa o histórico salvo
                        _loadHistory(); // Atualiza a tela
                      },
                      child: const Text("Apagar Histórico"),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

