import 'package:flutter/material.dart';
import 'controllers/historico_controller.dart';
import 'controllers/progresso_controller.dart';
import 'controllers/treino_controller.dart';
import 'repositories/treino_repository.dart';
import 'theme/app_colors.dart';
import 'screens/treino_screen.dart';
import 'screens/historico_screen.dart';
import 'screens/progresso_screen.dart';

void main() {
  runApp(const GymSaiyajinApp());
}

class GymSaiyajinApp extends StatelessWidget {
  const GymSaiyajinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Saiyajin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
        ),
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

class TelaBase extends StatefulWidget {
  const TelaBase({super.key});

  @override
  State<TelaBase> createState() => _TelaBaseState();
}

class _TelaBaseState extends State<TelaBase> {
  int _indiceAtual = 0;
  late final TreinoRepository _treinoRepository;
  late final TreinoController _treinoController;
  late final HistoricoController _historicoController;
  late final ProgressoController _progressoController;

  @override
  void initState() {
    super.initState();
    _treinoRepository = TreinoRepository();
    _treinoController = TreinoController(repository: _treinoRepository);
    _historicoController = HistoricoController(repository: _treinoRepository);
    _progressoController = ProgressoController(repository: _treinoRepository);
    _historicoController.carregarHistorico();
    _progressoController.carregarDados();
  }

  @override
  void dispose() {
    _treinoController.dispose();
    _historicoController.dispose();
    _progressoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> telas = [
      TreinoScreen(
        controller: _treinoController,
        onEncerrarTreino: () {
          _historicoController.carregarHistorico();
          _progressoController.carregarDados();
          setState(() {
            _indiceAtual = 1;
          });
        },
      ),
      HistoricoScreen(controller: _historicoController),
      ProgressoScreen(controller: _progressoController),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _indiceAtual,
        children: telas,
      ),
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