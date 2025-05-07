// Versão 0.9.2: Histórico melhorado pra dividir os resultados por tempo de exercício e data.
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
