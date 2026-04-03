import 'package:flutter/material.dart';
import 'controllers/historico_controller.dart';
import 'controllers/progresso_controller.dart';
import 'controllers/treino_controller.dart';
import 'repositories/treino_repository.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';
import 'theme/app_colors.dart';
import 'screens/treino_screen.dart';
import 'screens/historico_screen.dart';
import 'screens/progresso_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = NotificationService();
  await notificationService.init();
  runApp(GymSaiyajinApp(notificationService: notificationService));
}

class GymSaiyajinApp extends StatelessWidget {
  final NotificationService notificationService;

  const GymSaiyajinApp({super.key, required this.notificationService});

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
      home: TelaBase(notificationService: notificationService),
    );
  }
}

class TelaBase extends StatefulWidget {
  final NotificationService notificationService;

  const TelaBase({super.key, required this.notificationService});

  @override
  State<TelaBase> createState() => _TelaBaseState();
}

class _TelaBaseState extends State<TelaBase> {
  int _indiceAtual = 0;
  late final TreinoRepository _treinoRepository;
  late final PreferencesService _preferencesService;
  late final TreinoController _treinoController;
  late final HistoricoController _historicoController;
  late final ProgressoController _progressoController;

  @override
  void initState() {
    super.initState();
    _treinoRepository = TreinoRepository();
    _preferencesService = PreferencesService();
    _treinoController = TreinoController(
      repository: _treinoRepository,
      preferencesService: _preferencesService,
      notificationService: widget.notificationService,
    );
    _historicoController = HistoricoController(repository: _treinoRepository);
    _progressoController = ProgressoController(
      repository: _treinoRepository,
      preferencesService: _preferencesService,
    );
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
      HistoricoScreen(
        controller: _historicoController,
        onHistoricoAtualizado: () {
          _progressoController.carregarDados();
        },
      ),
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