import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'widgets/ki_aura_icon.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = NotificationService();
  runApp(GymSaiyajinApp(notificationService: notificationService));
  unawaited(notificationService.init());
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
        progressoController: _progressoController,
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
        progressoController: _progressoController,
        onHistoricoAtualizado: () {
          _progressoController.carregarDados();
          _treinoController.carregarFichas();
        },
      ),
      ProgressoScreen(controller: _progressoController),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Se estiver em outra aba (Histórico ou Progresso), volta primeiro para a aba Treino
        if (_indiceAtual != 0) {
          setState(() {
            _indiceAtual = 0;
          });
          return;
        }

        // Se não houver treino em andamento, encerra o app normalmente
        if (!_treinoController.treinoAtivo) {
          await SystemNavigator.pop();
          return;
        }

        // Se houver treino ativo na Sala do Tempo, solicita confirmação para não perder o progresso
        final confirmarSaida = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                KiAuraIcon(
                  size: 20,
                  primaryColor: AppColors.accent,
                  secondaryColor: AppColors.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Treino em Andamento',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Text(
              'Você possui um treino ativo na Sala do Tempo. Deseja realmente sair do aplicativo?',
              style: TextStyle(color: AppColors.textLight),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Continuar Treino'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Sair do App',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
        );

        if (confirmarSaida == true) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
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
      ),
    );
  }
}