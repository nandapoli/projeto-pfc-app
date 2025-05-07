import 'package:flutter/material.dart';
import 'game_screen.dart'; // Importa a tela do jogo

class TimeSelectionScreen extends StatelessWidget {
  const TimeSelectionScreen({super.key});

 // Função auxiliar para navegar para a tela do jogo
  void _startGame(BuildContext context, int? selectedTime) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FingerGameScreen(gameTimer: selectedTime),
      ),
    );
  }

  // Função para criar botões de seleção de tempo
  Widget _buildTimeButton(BuildContext context, String label, int? timeInSeconds) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: () => _startGame(context, timeInSeconds),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(200, 50), // Tamanho mínimo dos botões
          textStyle: const TextStyle(fontSize: 20),
        ),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Tempo de Jogo'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Escolha o tempo de jogo:',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 30),
            _buildTimeButton(context, '30 segundos', 30),
            _buildTimeButton(context, '60 segundos', 60),
            _buildTimeButton(context, '90 segundos', 90),
            _buildTimeButton(context, 'Sem limite de tempo', null), // null representa sem limite
          ],
        ),
      ),
    );
  }
}
