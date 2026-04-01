import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'dart:async';

class TreinoScreen extends StatefulWidget {
  final VoidCallback onEncerrarTreino; // <--- 1. Criamos a variável que vai receber a função

  // 2. Obrigamos o main.dart a passar essa função quando criar a tela
  const TreinoScreen({super.key, required this.onEncerrarTreino});

  @override
  State<TreinoScreen> createState() => _TreinoScreenState();
}

class _TreinoScreenState extends State<TreinoScreen> {
  Timer? _timer;
  int _tempoDescansoPadrao = 90; // 90 segundos = 01:30
  int _tempoAtual = 90;
  bool _isTimerRodando = false;


  String exercicioAtual = 'SUPINO RETO';
  String grupoAtual = 'PEITO';
  // Estado mockado (simulando o banco de dados).
  List<Map<String, dynamic>> series = [
    {'peso': '60', 'reps': '12', 'concluida': true},
    {'peso': '60', 'reps': '12', 'concluida': true},
    {'peso': '60', 'reps': '12', 'concluida': false},
    {'peso': '60', 'reps': '12', 'concluida': false},
  ];

  void _adicionarSerie() {
    setState(() {
      series.add({'peso': '', 'reps': '', 'concluida': false});
    });
  }

  void _toggleConcluida(int index) {
    setState(() {
      bool isAgoraConcluida = !series[index]['concluida'];
      series[index]['concluida'] = isAgoraConcluida;

      // Se acabou de marcar como concluída, inicia o descanso!
      if (isAgoraConcluida) {
        _iniciarTimer();
      }
    });
  }

  void _abrirListaExercicios() {
    final exerciciosCadastrados = [
      {'nome': 'Crucifixo', 'grupo': 'PEITO'},
      {'nome': 'Agachamento Livre', 'grupo': 'PERNAS'},
      {'nome': 'Leg Press', 'grupo': 'PERNAS'},
      {'nome': 'Remada Curvada', 'grupo': 'COSTAS'},
      {'nome': 'Puxada Frontal', 'grupo': 'COSTAS'},
      {'nome': 'Rosca Direta', 'grupo': 'BÍCEPS'},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.all(20), // Margem de respiro nas bordas da tela
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8, // Altura máxima de 80% da tela
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Faz o modal encolher se tiver poucos itens
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- CABEÇALHO COM TÍTULO E BOTÃO FECHAR ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PRÓXIMO EXERCÍCIO',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textDimmed),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- BARRA DE PESQUISA ---
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar exercício...',
                    hintStyle: const TextStyle(color: AppColors.textDimmed),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- LISTA DE EXERCÍCIOS ---
                // Usamos Flexible em vez de Expanded para que o modal possa se ajustar ao conteúdo
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
                          Navigator.pop(context); // Fecha o modal
                          
                          // Chama a nossa nova função que usa o setState!
                          _trocarExercicio(ex['nome']!, ex['grupo']!);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // --- BOTÃO CRIAR NOVO ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Opcional: fecha a lista antes de abrir o de criar novo
                      _abrirModalNovoExercicio();
                    },
                    icon: const Icon(Icons.add, color: AppColors.accent),
                    label: const Text(
                      'NÃO ACHOU? CRIAR NOVO',
                      style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _abrirModalNovoExercicio() {
    // Controladores para pegar os valores digitados/selecionados
    final nomeController = TextEditingController();
    String grupoSelecionado = 'PEITO'; // Valor padrão inicial
    final gruposMusculares = ['PEITO', 'COSTAS', 'PERNAS', 'OMBROS', 'BÍCEPS', 'TRÍCEPS'];

    showDialog(
      context: context,
      builder: (context) {
        // Usamos StatefulBuilder porque o Dropdown precisa mudar de valor dentro do Modal
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'NOVO EXERCÍCIO',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min, // Faz o modal usar apenas o espaço necessário
                children: [
                  // --- INPUT DO NOME ---
                  TextField(
                    controller: nomeController,
                    style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Nome do Exercício',
                      labelStyle: const TextStyle(color: AppColors.textDimmed),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- SELETOR DE GRUPO MUSCULAR ---
                  DropdownButtonFormField<String>(
                    value: grupoSelecionado,
                    dropdownColor: AppColors.background, // Cor do menu quando abre
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Grupo Muscular',
                      labelStyle: const TextStyle(color: AppColors.textDimmed),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: gruposMusculares.map((grupo) {
                      return DropdownMenuItem(value: grupo, child: Text(grupo));
                    }).toList(),
                    onChanged: (novoValor) {
                      if (novoValor != null) {
                        setStateModal(() {
                          grupoSelecionado = novoValor;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                // --- BOTÃO CANCELAR ---
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCELAR', style: TextStyle(color: AppColors.textDimmed)),
                ),
                // --- BOTÃO SALVAR ---
                ElevatedButton(
                  onPressed: () {
                    // Aqui entra a lógica futura para salvar no banco SQLite/Supabase
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Salvo: ${nomeController.text} - $grupoSelecionado')),
                    );
                    Navigator.pop(context); // Fecha o Modal
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('SALVAR', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _trocarExercicio(String novoNome, String novoGrupo) {
    setState(() {
      exercicioAtual = novoNome;
      grupoAtual = novoGrupo;
      
      // Zera a lista de séries, deixando apenas uma vazia para começar
      series = [
        {'peso': '', 'reps': '', 'concluida': false}
      ];
    });}

  // Formata 90 segundos para "01:30"
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

        _timer?.cancel();
        _isTimerRodando = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Descanso finalizado! Hora de voltar pro ferro.'),
            backgroundColor: AppColors.primary,
          ),
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
    setState(() {
      _isTimerRodando = false;
    });
  }

  void _continuarTimer() {
    if (_isTimerRodando) return;

    setState(() {
      if (_tempoAtual <= 0) {
        _tempoAtual = _tempoDescansoPadrao;
      }
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

  void _abrirConfigTempoDescanso() {
    int tempoSelecionado = _tempoDescansoPadrao;
    // Tempos mais comuns de descanso na musculação (em segundos)
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
                child: Text(
                  'TEMPO DE DESCANSO',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 16),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mostrador Gigante
                  Text(
                    _formatarSegundos(tempoSelecionado),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ajuste Fino (+ e -)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (tempoSelecionado > 15) {
                            setStateModal(() => tempoSelecionado -= 15);
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline, size: 32, color: AppColors.primary),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        onPressed: () {
                          setStateModal(() => tempoSelecionado += 15);
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 32, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Grade de Atalhos Rápidos (Presets)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: temposPreDefinidos.map((tempo) {
                      bool isSelecionado = tempoSelecionado == tempo;
                      return InkWell(
                        onTap: () {
                          setStateModal(() => tempoSelecionado = tempo);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelecionado ? AppColors.primary : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelecionado ? AppColors.primary : AppColors.surface,
                            ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                  ),
                  child: const Text('SALVAR', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // É importante cancelar o timer se o usuário sair da tela para não vazar memória
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView( // Evita erro de tela cortada se houver muitas séries
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- CABEÇALHO ---
             Text(
              exercicioAtual,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900, // Fonte bem pesada
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                grupoAtual,
                style: TextStyle(
                  color: AppColors.background,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // --- CRONÔMETRO ---
            GestureDetector(
              onTap: _abrirConfigTempoDescanso,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.surface, width: 8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 30,
                      spreadRadius: 10,
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _tempoFormatado,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _isTimerRodando ? AppColors.accent : AppColors.textLight,
                      ),
                    ),
                    const Text(
                      'TOQUE PARA AJUSTAR',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textDimmed,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _isTimerRodando ? _pausarTimer : null,
                  icon: const Icon(Icons.pause, size: 18),
                  label: const Text('PAUSAR'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _tempoAtual != _tempoDescansoPadrao || _isTimerRodando ? _reiniciarTimer : null,
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('REINICIAR'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: !_isTimerRodando ? _continuarTimer : null,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text(_tempoAtual == _tempoDescansoPadrao ? 'INICIAR' : 'CONTINUAR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // --- TÍTULO DA LISTA ---
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SÉRIES DE HOJE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- LISTA DE SÉRIES ---
            ListView.builder(
              shrinkWrap: true, // Necessário quando está dentro de um ScrollView
              physics: const NeverScrollableScrollPhysics(),
              itemCount: series.length,
              itemBuilder: (context, index) {
                final serie = series[index];
                return _buildSerieRow(index, serie); // Chamando nosso método isolado
              },
            ),
            const SizedBox(height: 24),

            // --- BOTÃO 1: ADICIONAR SÉRIE (Maciço Dourado) ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _adicionarSerie,
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'ADICIONAR NOVA SÉRIE',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16), // Espaçamento menor entre ações relacionadas

            // --- BOTÃO 2: FINALIZAR EXERCÍCIO (Outlined Laranja) ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed:  
                _abrirListaExercicios, // <--- Conectamos a função aqui!
                
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text(
                  'FINALIZAR E ADICIONAR EXERCÍCIO',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            
            // Espaçamento visual maior antes da ação definitiva de encerrar
            const SizedBox(height: 48), 

            // --- BOTÃO 3: ENCERRAR TREINO (Maciço Vermelho) ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Lógica para salvar o treino completo e ir para o Histórico
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Treino Encerrado! Indo para o Histórico...')),
                  );
                  widget.onEncerrarTreino(); // <--- Chamamos a função que veio do main.dart
                },
                icon: const Icon(Icons.sports_score, size: 20),
                label: const Text(
                  'ENCERRAR TREINO DE HOJE',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C), // Vermelho escuro de alerta
                  foregroundColor: AppColors.textLight,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20), // Margem final da tela
          ],
        ),
      ),
    );
  }

  // Extraímos a linha da série para não poluir a árvore principal.
  Widget _buildSerieRow(int index, Map<String, dynamic> serie) {
    bool isConcluida = serie['concluida'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Círculo com o número da série
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isConcluida ? AppColors.accent : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 2),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isConcluida ? AppColors.background : AppColors.accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Campo: Peso
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PESO (KG)', style: TextStyle(fontSize: 10, color: AppColors.textDimmed)),
                const SizedBox(height: 4),
                _buildCustomTextField(serie['peso'], isConcluida),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Campo: Reps
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('REPS', style: TextStyle(fontSize: 10, color: AppColors.textDimmed)),
                const SizedBox(height: 4),
                _buildCustomTextField(serie['reps'], isConcluida),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Botão Check
          GestureDetector(
            onTap: () => _toggleConcluida(index),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isConcluida ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isConcluida ? AppColors.primary : AppColors.surface),
              ),
              child: Icon(
                Icons.check,
                color: isConcluida ? AppColors.background : AppColors.textDimmed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reutilizando o input para manter o visual consistente
  Widget _buildCustomTextField(String valorInicial, bool isConcluida) {
    return TextFormField(
      initialValue: valorInicial,
      readOnly: isConcluida, // Trava a edição se a série já foi concluída
      keyboardType: TextInputType.number,
      style: TextStyle(
        fontWeight: FontWeight.bold, 
        fontSize: 16,
        color: isConcluida ? AppColors.textDimmed : AppColors.textLight,
      ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}