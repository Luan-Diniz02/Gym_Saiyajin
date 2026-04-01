import 'package:flutter/material.dart';
import 'theme/app_colors.dart';
import 'screens/treino_screen.dart';
import 'screens/historico_screen.dart';
import 'screens/progresso_screen.dart';
// Importaremos as telas aqui quando as criarmos de verdade. 
// Por enquanto, usaremos placeholders.

void main() {
  runApp(const GymSaiyajinApp());
}

class GymSaiyajinApp extends StatelessWidget {
  const GymSaiyajinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Saiyajin',
      debugShowCheckedModeBanner: false, // Tira aquela faixa vermelha de DEBUG
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
        ),
        // Estiliza a barra de navegação inferior para o app todo
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textDimmed,
        ),
      ),
      home: const TelaBase(),
    );
  }
}

// O StatefulWidget que gerencia qual aba está selecionada
class TelaBase extends StatefulWidget {
  const TelaBase({super.key});

  @override
  State<TelaBase> createState() => _TelaBaseState();
}

class _TelaBaseState extends State<TelaBase> {
  int _indiceAtual = 0;

  @override
  Widget build(BuildContext context) {
    // Colocamos a lista aqui dentro para ela ter acesso ao setState desta classe
    final List<Widget> telas = [
      TreinoScreen(
        onEncerrarTreino: () {
          setState(() {
            _indiceAtual = 1; // <--- Muda o foco da aba para o Histórico (índice 1)
          });
        },
      ),
      const HistoricoScreen(),
      const ProgressoScreen(),
    ];

    return Scaffold(
      body: telas[_indiceAtual], // Exibe a tela baseada no índice atual
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: (index) {
          setState(() {
            _indiceAtual = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Treino',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Histórico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Progresso',
          ),
        ],
      ),
    );
  }
}