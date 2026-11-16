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

        // Se houver treino em andamento, solicita confirmação para não perder o progresso
        final confirmarSaida = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const KiAuraIcon(
                    size: 20,
                    primaryColor: AppColors.accent,
                    secondaryColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'TREINO EM ANDAMENTO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ],
            ),
            content: const Text(
              'Você possui um treino em andamento. Deseja realmente sair do aplicativo?',
              style: TextStyle(
                color: AppColors.textDimmed,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.background,
                          foregroundColor: AppColors.textLight,
                          side: const BorderSide(
                            color: AppColors.buttonBorder,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'CONTINUAR',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'SAIR DO APP',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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