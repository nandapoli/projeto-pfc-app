// Versão 0.8: Nesta versão o código foi dividido em arquivos e agora é possível escolher o tempo de exercício.
import 'package:flutter/material.dart'; // Importa a biblioteca principal do Flutter para interface gráfica
import 'screens/menu_screen.dart'; // Importa a tela do menu principal

void main() {
  runApp(const MyApp()); // Inicia o aplicativo
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Construtor da classe principal

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove a barra de debug
      home: const MenuScreen(), // Define o menu como a tela principal
    );
  }
}
