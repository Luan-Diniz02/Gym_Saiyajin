import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import 'dart:async';

class TreinoScreen extends StatefulWidget {
  final VoidCallback onEncerrarTreino;

  const TreinoScreen({super.key, required this.onEncerrarTreino});

  @override
  State<TreinoScreen> createState() => _TreinoScreenState();
}

class _TreinoScreenState extends State<TreinoScreen> {
  // --- 1. CRONÔMETRO ---
  Timer? _timer;
  int _tempoDescansoPadrao = 90;
  int _tempoAtual = 90;
  bool _isTimerRodando = false;

  // --- 2. FORMATADORES DE TEXTO ---
  final TextInputFormatter _pesoInputFormatter = TextInputFormatter.withFunction((oldValue, newValue) {
    final texto = newValue.text;
    if (texto.isEmpty || RegExp(r'^\d+([.,]\d{0,2})?$').hasMatch(texto)) {
      return newValue;
    }
    return oldValue;
  });
  final TextInputFormatter _repsInputFormatter = FilteringTextInputFormatter.digitsOnly;

  // --- 3. ESTADO DA SESSÃO DE TREINO ---
  List<Map<String, dynamic>> exerciciosConcluidosHoje = []; // O "Log" do passado
  
  String? exercicioAtual; // O "Foco" do presente (Começa null)
  String? grupoAtual;
  List<Map<String, dynamic>> series = [];

  // ==========================================
  // LÓGICA DE NEGÓCIO
  // ==========================================

  void _iniciarNovoExercicio(String nome, String grupo) {
    setState(() {
      exercicioAtual = nome;
      grupoAtual = grupo;
      // Zera a lista de séries, deixando apenas uma vazia para começar
      series = [
        {'peso': null, 'reps': null, 'concluida': false}
      ];
    });
  }

  void _finalizarExercicioAtual() {
    if (exercicioAtual == null) return;

    // --- NOVA VALIDAÇÃO ---
    bool temSerieIncompleta = false;
    for (var serie in series) {
      if (serie['peso'] == null || serie['reps'] == null) {
        temSerieIncompleta = true;
        break; // Para o loop assim que achar um erro
      }
    }

    if (temSerieIncompleta) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha o peso e as repetições de TODAS as séries antes de finalizar!',
            style: TextStyle(color: Colors.white), 
          ),
          backgroundColor: Color(0xFFB71C1C), // Vermelho de erro
        ),
      );
      return; // Interrompe a função aqui, impedindo o salvamento
    }
    // --- FIM DA VALIDAÇÃO ---

    setState(() {
      // 1. Salva o rascunho atual no "Log"
      exerciciosConcluidosHoje.add({
        'nome': exercicioAtual,
        'grupo': grupoAtual,
        'series_detalhes': List<Map<String, dynamic>>.from(series), 
      });

      // 2. Limpa o Foco (Volta para a Tela Limpa)
      exercicioAtual = null;
      grupoAtual = null;
      series = [];
    });
  }

  void _adicionarSerie() {
    setState(() {
      series.add({'peso': null, 'reps': null, 'concluida': false});
    });
  }

  void _toggleConcluida(int index) {
    setState(() {
      bool isAgoraConcluida = !series[index]['concluida'];
      series[index]['concluida'] = isAgoraConcluida;

      if (isAgoraConcluida) {
        _iniciarTimer();
      }
    });
  }

  // ==========================================
  // LÓGICA DO CRONÔMETRO
  // ==========================================
  
  String get _tempoFormatado {
    int minutos = _tempoAtual ~/ 60;
    int segundos = _tempoAtual % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  String _formatarSegundos(int totalSegundos) {
    final minutos = totalSegundos ~/ 60;
    final segundos = totalSegundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  void _iniciarTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        if (_tempoAtual > 0) {
          _tempoAtual--;
          return;
        }

        // --- O TEMPO ACABOU ---
        _timer?.cancel();
        _isTimerRodando = false;

        // 1. Vibração Pesada (Nativa do celular)
        HapticFeedback.heavyImpact();
        
        // Se quiser um padrão mais forte, pode chamar duas vezes com um pequeno delay:
        // Future.delayed(const Duration(milliseconds: 200), () => HapticFeedback.heavyImpact());

        // 2. Pop-up saltando na tela
        showDialog(
          context: context,
          barrierDismissible: false, // Obriga o usuário a clicar no botão para fechar
          builder: (context) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.timer, color: AppColors.accent, size: 28),
                  SizedBox(width: 8),
                  Text('DESCANSO FINALIZADO!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              content: const Text(
                'Hora de voltar pro ferro. Prepare-se para a próxima série!',
                style: TextStyle(color: AppColors.textLight),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('BORA!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            );
          },
        );
      });
    });
  }

  void _iniciarTimer() {
    setState(() {
      _tempoAtual = _tempoDescansoPadrao;
      _isTimerRodando = true;
    });
    _iniciarTicker();
  }

  void _pausarTimer() {
    _timer?.cancel();
    setState(() => _isTimerRodando = false);
  }

  void _continuarTimer() {
    if (_isTimerRodando) return;
    setState(() {
      if (_tempoAtual <= 0) _tempoAtual = _tempoDescansoPadrao;
      _isTimerRodando = true;
    });
    _iniciarTicker();
  }

  void _reiniciarTimer() {
    _timer?.cancel();
    setState(() {
      _tempoAtual = _tempoDescansoPadrao;
      _isTimerRodando = false;
    });
  }

  // ==========================================
  // MODAIS
  // ==========================================

  void _abrirConfigTempoDescanso() {
    int tempoSelecionado = _tempoDescansoPadrao;
    final List<int> temposPreDefinidos = [45, 60, 90, 120, 180, 240];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Center(
                child: Text('TEMPO DE DESCANSO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatarSegundos(tempoSelecionado),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.accent),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (tempoSelecionado > 15) setStateModal(() => tempoSelecionado -= 15);
                        },
                        icon: const Icon(Icons.remove_circle_outline, size: 32, color: AppColors.primary),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        onPressed: () => setStateModal(() => tempoSelecionado += 15),
                        icon: const Icon(Icons.add_circle_outline, size: 32, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
                    children: temposPreDefinidos.map((tempo) {
                      bool isSelecionado = tempoSelecionado == tempo;
                      return InkWell(
                        onTap: () => setStateModal(() => tempoSelecionado = tempo),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelecionado ? AppColors.primary : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelecionado ? AppColors.primary : AppColors.surface),
                          ),
                          child: Text(
                            _formatarSegundos(tempo),
                            style: TextStyle(
                              color: isSelecionado ? AppColors.background : AppColors.textLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCELAR', style: TextStyle(color: AppColors.textDimmed)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _tempoDescansoPadrao = tempoSelecionado;
                      _tempoAtual = tempoSelecionado;
                      _isTimerRodando = false;
                    });
                    _timer?.cancel();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.background),
                  child: const Text('SALVAR', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _abrirListaExercicios() {
    final exerciciosCadastrados = [
      {'nome': 'Crucifixo', 'grupo': 'PEITO'},
      {'nome': 'Agachamento Livre', 'grupo': 'PERNAS'},
      {'nome': 'Leg Press', 'grupo': 'PERNAS'},
      {'nome': 'Remada Curvada', 'grupo': 'COSTAS'},
      {'nome': 'Puxada Frontal', 'grupo': 'COSTAS'},
      {'nome': 'Rosca Direta', 'grupo': 'BÍCEPS'},
      {'nome': 'Supino Reto', 'grupo': 'PEITO'},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('SELECIONE O EXERCÍCIO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textDimmed),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar exercício...',
                    hintStyle: const TextStyle(color: AppColors.textDimmed),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: exerciciosCadastrados.length,
                    separatorBuilder: (context, index) => const Divider(color: AppColors.background),
                    itemBuilder: (context, index) {
                      final ex = exerciciosCadastrados[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(ex['nome']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(ex['grupo']!, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                        trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                        onTap: () {
                          Navigator.pop(context);
                          _iniciarNovoExercicio(ex['nome']!, ex['grupo']!);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ==========================================
  // CONSTRUÇÃO DA TELA (BUILD)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            
            // --- 1. CRONÔMETRO GLOBAL (Sempre visível no topo) ---
            _buildCronometroGlobal(),
            const SizedBox(height: 32),

            // --- 2. LOG DA SESSÃO (Exercícios Concluídos) ---
            if (exerciciosConcluidosHoje.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('JÁ REALIZADOS HOJE:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDimmed)),
              ),
              const SizedBox(height: 12),
              ...exerciciosConcluidosHoje.map((ex) => _buildCardLogExercicio(ex)),
              const SizedBox(height: 32),
            ],

            // --- 3. ÁREA DE FOCO (Dinâmica) ---
            if (exercicioAtual == null)
              _buildTelaLimpa() // Estado Vazio
            else
              _buildExercicioAtual(), // Formulário Ativo

            const SizedBox(height: 48),

            // --- 4. BOTÃO FINAL DE ENCERRAR O DIA ---
            if (exerciciosConcluidosHoje.isNotEmpty || exercicioAtual != null)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Aqui vamos salvar a "exerciciosConcluidosHoje" no SQLite
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Treino salvo com sucesso!')),
                    );
                    widget.onEncerrarTreino();
                  },
                  icon: const Icon(Icons.sports_score, size: 20),
                  label: const Text(
                    'ENCERRAR TREINO DE HOJE',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    foregroundColor: AppColors.textLight,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGETS AUXILIARES
  // ==========================================

  Widget _buildCronometroGlobal() {
    return Column(
      children: [
        GestureDetector(
          onTap: _abrirConfigTempoDescanso,
          child: Container(
            width: 180, // Diminui um pouco para não roubar tanto espaço
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.surface, width: 8),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 30, spreadRadius: 10)
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _tempoFormatado,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: _isTimerRodando ? AppColors.accent : AppColors.textLight,
                  ),
                ),
                const Text('TOQUE PARA AJUSTAR', style: TextStyle(fontSize: 10, color: AppColors.textDimmed, letterSpacing: 1.2)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8, runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _isTimerRodando ? _pausarTimer : null,
              icon: const Icon(Icons.pause, size: 16),
              label: const Text('PAUSAR', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
            ),
            OutlinedButton.icon(
              onPressed: _tempoAtual != _tempoDescansoPadrao || _isTimerRodando ? _reiniciarTimer : null,
              icon: const Icon(Icons.restart_alt, size: 16),
              label: const Text('REINICIAR', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
            ),
            ElevatedButton.icon(
              onPressed: !_isTimerRodando ? _continuarTimer : null,
              icon: const Icon(Icons.play_arrow, size: 16),
              label: Text(_tempoAtual == _tempoDescansoPadrao ? 'INICIAR' : 'CONTINUAR', style: const TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.background),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTelaLimpa() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surface, width: 2)
      ),
      child: Column(
        children: [
          const Icon(Icons.fitness_center, size: 64, color: AppColors.textDimmed),
          const SizedBox(height: 16),
          const Text(
            'PRONTO PARA DESTRUIR?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textLight),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adicione o seu primeiro exercício do dia para começar a registrar as cargas.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textDimmed),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _abrirListaExercicios,
              icon: const Icon(Icons.add, size: 24),
              label: const Text('INICIAR TREINO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildExercicioAtual() {
    return Column(
      children: [
        // Cabeçalho do Exercício
        Text(
          exercicioAtual!,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
          child: Text(
            grupoAtual!,
            style: const TextStyle(color: AppColors.background, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const SizedBox(height: 32),

        const Align(
          alignment: Alignment.centerLeft,
          child: Text('SÉRIES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
        const SizedBox(height: 16),

        // Lista de Séries
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: series.length,
          itemBuilder: (context, index) {
            final serie = series[index];
            return _buildSerieRow(index, serie);
          },
        ),
        const SizedBox(height: 24),

        // Botões de Ação do Exercício
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _adicionarSerie,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('ADICIONAR NOVA SÉRIE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent, foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _finalizarExercicioAtual, // Chama a função que salva e limpa
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: const Text('FINALIZAR EXERCÍCIO', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // O Card Retrátil do Histórico (reaproveitado para a Sessão)
  Widget _buildCardLogExercicio(Map<String, dynamic> exercicio) {
    final List detalhes = exercicio['series_detalhes'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textDimmed,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                exercicio['nome'],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 28),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text(exercicio['grupo'], style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Text('${detalhes.length} SÉRIES', style: const TextStyle(color: AppColors.textDimmed, fontSize: 12)),
              ],
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              ),
              child: Column(
                children: detalhes.asMap().entries.map((entry) {
                  int serieIndex = entry.key + 1;
                  var serieData = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Série $serieIndex', style: const TextStyle(color: AppColors.textDimmed, fontSize: 14)),
                        Row(
                          children: [
                            Text('${serieData['reps'] ?? '-'} reps', style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 16),
                            Text('${serieData['peso'] ?? '-'} kg', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- Linha de Input das Séries ---
  Widget _buildSerieRow(int index, Map<String, dynamic> serie) {
    bool isConcluida = serie['concluida'];
    final double? peso = serie['peso'] as double?;
    final int? reps = serie['reps'] as int?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isConcluida ? AppColors.accent : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 2),
            ),
            child: Center(
              child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isConcluida ? AppColors.background : AppColors.accent)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PESO (KG)', style: TextStyle(fontSize: 10, color: AppColors.textDimmed)),
                const SizedBox(height: 4),
                _buildCustomTextField(
                  chave: 'peso-$exercicioAtual-$index',
                  valorInicial: peso?.toStringAsFixed(peso % 1 == 0 ? 0 : 1) ?? '',
                  isConcluida: isConcluida,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [_pesoInputFormatter],
                  onChanged: (valor) {
                    final v = valor.replaceAll(',', '.').trim();
                    series[index]['peso'] = v.isEmpty ? null : double.tryParse(v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('REPS', style: TextStyle(fontSize: 10, color: AppColors.textDimmed)),
                const SizedBox(height: 4),
                _buildCustomTextField(
                  chave: 'reps-$exercicioAtual-$index',
                  valorInicial: reps?.toString() ?? '',
                  isConcluida: isConcluida,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_repsInputFormatter],
                  onChanged: (valor) {
                    final v = valor.trim();
                    series[index]['reps'] = v.isEmpty ? null : int.tryParse(v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => _toggleConcluida(index),
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isConcluida ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isConcluida ? AppColors.primary : AppColors.surface),
              ),
              child: Icon(Icons.check, color: isConcluida ? AppColors.background : AppColors.textDimmed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTextField({
    required String chave,
    required String valorInicial,
    required bool isConcluida,
    required TextInputType keyboardType,
    required List<TextInputFormatter> inputFormatters,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      key: ValueKey(chave),
      initialValue: valorInicial,
      readOnly: isConcluida, 
      keyboardType: keyboardType,
      inputFormatters: isConcluida ? null : inputFormatters,
      onChanged: isConcluida ? null : onChanged,
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isConcluida ? AppColors.textDimmed : AppColors.textLight),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true, fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}