import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HistoricoScreen extends StatelessWidget {
  const HistoricoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. DADOS ATUALIZADOS: Agora cada exercício tem uma lista detalhada de séries
    final List<Map<String, dynamic>> historicoTreinos = [
      {
        'data': '30 de Março de 2026',
        'qtd_exercicios': 2,
        'exercicios': [
          {
            'nome': 'SUPINO RETO',
            'grupo': 'PEITO',
            'series_detalhes': [
              {'reps': 15, 'peso': 20}, // Aquecimento
              {'reps': 12, 'peso': 60},
              {'reps': 10, 'peso': 60},
              {'reps': 8, 'peso': 64},  // Progressão de carga
            ]
          },
          {
            'nome': 'CRUCIFIXO',
            'grupo': 'PEITO',
            'series_detalhes': [
              {'reps': 12, 'peso': 16},
              {'reps': 12, 'peso': 16},
              {'reps': 10, 'peso': 18},
            ]
          },
        ]
      },
      {
        'data': '28 de Março de 2026',
        'qtd_exercicios': 1,
        'exercicios': [
          {
            'nome': 'AGACHAMENTO',
            'grupo': 'PERNAS',
            'series_detalhes': [
              {'reps': 10, 'peso': 80},
              {'reps': 10, 'peso': 80},
              {'reps': 8, 'peso': 84},
            ]
          },
        ]
      },
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'HISTÓRICO',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
            const SizedBox(height: 4),
            const Text(
              'TODOS OS SEUS TREINOS',
              style: TextStyle(fontSize: 12, color: AppColors.textDimmed, letterSpacing: 1.2),
            ),
            const SizedBox(height: 30),

            Expanded(
              child: ListView.builder(
                itemCount: historicoTreinos.length,
                itemBuilder: (context, index) {
                  final diaTreino = historicoTreinos[index];
                  final isUltimo = index == historicoTreinos.length - 1; 
                  return _buildTimelineItem(context, diaTreino, isUltimo);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, Map<String, dynamic> diaTreino, bool isUltimo) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.calendar_month, color: AppColors.background, size: 20),
              ),
              if (!isUltimo)
                Expanded(child: Container(width: 2, color: AppColors.primary.withOpacity(0.5))),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diaTreino['data'],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight),
                ),
                Text(
                  '${diaTreino['qtd_exercicios']} EXERCÍCIOS',
                  style: const TextStyle(fontSize: 12, color: AppColors.textDimmed),
                ),
                const SizedBox(height: 12),
                ...List.generate(
                  diaTreino['exercicios'].length,
                  (index) => _buildCardExercicio(context, diaTreino['exercicios'][index]),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. O NOVO CARD COM EXPANSION TILE
  Widget _buildCardExercicio(BuildContext context, Map<String, dynamic> exercicio) {
    final List detalhes = exercicio['series_detalhes'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      // O Theme tira as linhas de borda nativas que o ExpansionTile coloca por padrão
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textDimmed,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          
          // O que aparece quando está FECHADO
          title: Row(
            children: [
              const Icon(Icons.fitness_center, color: AppColors.primary, size: 20),
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
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    exercicio['grupo'],
                    style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${detalhes.length} SÉRIES', style: const TextStyle(color: AppColors.textDimmed, fontSize: 12)),
              ],
            ),
          ),
          
          // O que aparece quando está ABERTO
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.background, // Fundo mais escuro para contrastar
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
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
                            Text('${serieData['reps']} reps', style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 16),
                            Text('${serieData['peso']} kg', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
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
}