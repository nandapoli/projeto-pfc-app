import 'package:flutter/material.dart';
import 'game_screen.dart'; // Importa a tela do jogo

class TimeSelectionScreen extends StatelessWidget {
  const TimeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecione o tempo de exercício'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [30, 60, 90, 120].map((tempo) {
            return Padding(
              padding: const EdgeInsets.all(10),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FingerGameScreen(gameTimer: tempo),
                    ),
                  );
                },
                child: Text("$tempo segundos", style: const TextStyle(fontSize: 22)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
