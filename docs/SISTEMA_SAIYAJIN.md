# ⚡ Sistema Saiyajin & Progressão de Poder (Ki)

O **Gym Saiyajin** combina o rigor do treinamento de força e hipertrofia com uma temática autêntica, sóbria e canônica do universo Dragon Ball. O sistema de gamificação foi desenhado para incentivar a consistência, a sobrecarga progressiva e a superação contínua de recordes pessoais, mantendo sempre uma apresentação esportiva de alto nível sem poluição visual ou excesso de emojis infantis.

---

## 🧮 1. A Fórmula Híbrida do Poder de Luta (Ki)

O Poder de Luta do guerreiro é dinâmico e reflete tanto a **força bruta** quanto o **volume acumulado** e a **frequência de superação**:

$$\text{Poder de Luta (Ki)} = \text{Força Base} + \text{Vigor Saiyajin} + \text{Limites Superados}$$

$$\text{Poder de Luta (Ki)} = \left(\sum \text{Maior 1RM Estimado por Grupo Muscular} \times 10\right) + \left(\frac{\text{Volume Total Histórico}}{100}\right) + (\text{PRs Batidos} \times 150)$$

### Decomposição dos 3 Pilares:

1. **Força Base ($\sum \text{Maior 1RM} \times 10$)**:
   - Para cada um dos 6 grupos musculares principais (*Peito, Costas, Pernas, Ombros, Braços, Abdômen*), o sistema identifica o exercício com a maior estimativa de repetição máxima (1RM).
   - A soma desses maiores 1RMs é multiplicada por **10**. Esse pilar garante que a evolução na intensidade absoluta dos exercícios fundamentais (supinos, agachamentos, terras, desenvolvimentos) impulsione diretamente o patamar do atleta.

2. **Vigor Saiyajin ($\frac{\text{Volume Histórico}}{100}$)**:
   - Volume total levantado em toda a jornada pelo atleta:
     $$\text{Volume} = \sum (\text{peso} \times \text{repetições})$$
   - Dividido por **100**. Premia a consistência, a resistência neuromuscular à fadiga e a capacidade de trabalho acumulada nas incontáveis sessões de ferro contra a gravidade.

3. **Limites Superados ($\text{PRs} \times 150$)**:
   - Cada novo Recorde Pessoal (PR) conquistado (seja por carga absoluta ou por 1RM estimado) concede **+150 de Ki permanente**.
   - Bônus imediato: ao finalizar uma sessão com PRs, o card comemorativo e o card de encerramento destacam o ganho instantâneo de Ki.

---

## 👑 2. Patamares de Poder & Transformações Canônicas

O Ki acumulado determina o **Patamar de Poder** do guerreiro, desbloqueando auras visuais, cores de destaque e subtítulos épicos na interface:

| Patamar | Faixa de Ki | Cor do Badge | Lente do Scouter | Subtítulo Épico Oficial |
| :--- | :--- | :--- | :--- | :--- |
| **Classe Baixa** | 0 – 999 | `#9E9E9E` (Cinza neutro) | `#9E9E9E` | *Início da jornada do guerreiro* |
| **Guerreiro Z** | 1.000 – 3.999 | `#4FC3F7` (Azul Celeste) | `#4FC3F7` | *Defensor em treinamento constante* |
| **Elite Saiyajin** | 4.000 – 7.999 | `#FF5252` (Vermelho concentrado) | `#FF5252` | *Aura vermelha de poder concentrado* |
| **Super Saiyajin** | 8.000 – 14.999 | `#FFD700` (Dourado clássico) | `#FFD700` | *O lendário guerreiro dourado despertou* |
| **Super Saiyajin 2** | 15.000 – 29.999 | `#FF9E00` (Âmbar elétrico) | `#00E5FF` (Ciano elétrico) | *A fúria que rompeu a barreira do Super Saiyajin* |
| **Super Saiyajin 3** | 30.000 – 49.999 | `#FF6D00` (Laranja cósmico) | `#FF6D00` | *A força colossal que faz o universo estremecer* |
| **Instinto Superior** | 50.000+ | `#FFFFFF` (Prata celestial) | `#80D8FF` (Azul divino) | *O estado divino onde o corpo age por puro instinto* |

### Destaque Visual do Super Saiyajin 2:
- **Card e Borda Harmonizados**: Borda externa do card em gradiente âmbar elétrico `#FF9E00`, proporcionando uma transição visual límpida e nobre entre o ouro do SSJ1 e o fogo do SSJ3.
- **Lente do Scouter em Ciano Elétrico (`#00E5FF`)**: Em alusão aos raios bioelétricos característicos do SSJ2, o visor holográfico do `ScouterIcon` assume a tonalidade ciano, criando um contraste estético esportivo impecável sem poluir as molduras.

---

## 🎨 3. Componentes Vetoriais Nativos (CustomPainter)

Eliminamos o uso excessivo de emojis genéricos (como 📦 ou ⚡) em favor de ícones vetoriais proprietários desenhados diretamente no Canvas do Flutter:

### `DragonBallIcon`
- **Arquivo**: [`lib/widgets/dragon_ball_icon.dart`](file:///c:/Users/luand/Documents/Codigos/Dart/gym_saiyajin/lib/widgets/dragon_ball_icon.dart)
- **Renderização**:
  - Esfera com gradiente radial âmbar/laranja profundo (`#FFB703` $\to$ `#FB8500`).
  - Brilho especular translúcido simétrico simulando reflexo de cristal/acrílico.
  - Estrelas vermelhas de 5 pontas desenhadas matematicamente com funções trigonométricas ($\cos/\sin$ a cada $72^\circ$).
  - Suporte procedural a qualquer constelação de **1 a 7 estrelas**, distribuídas em círculos concêntricos e centro.
- **Uso Oficial**:
  - Ícone de prestígio do **Registro de Poder** (Quadro de Recordes Pessoais).
  - Marcador oficial de conquistas de Recordes Pessoais (**PRs**) no card de compartilhamento social.

### `ScouterIcon`
- **Arquivo**: [`lib/widgets/scouter_icon.dart`](file:///c:/Users/luand/Documents/Codigos/Dart/gym_saiyajin/lib/widgets/scouter_icon.dart)
- **Renderização**:
  - Haste ergonômica auricular com detalhes de parafusos e juntas mecânicas.
  - Arco superior angular com textura de liga metálica.
  - Lente translúcida frontal chanfrada em acrílico holográfico.
  - Retículo de mira/alvo interno digital e linhas de telemetria estilizadas.
- **Uso Oficial**:
  - Carimbo tecnológico de telemetria no modo de compartilhamento **Scouter HUD**.
  - Identificador visual da transformação atual do guerreiro no painel de Ki.

---

## 📊 4. Estimativa de 1RM (Fórmula de Epley Refinada)

Para mensurar recordes e calcular o Poder de Luta sem forçar o praticante a testar cargas máximas perigosas com 1 repetição, o app adota a fórmula de Epley com salvaguardas fisiológicas:

$$1\text{RM} = \begin{cases} 
\text{peso} & \text{se } \text{reps} = 1 \\
\text{peso} \times \left(1 + \frac{\text{reps}}{30}\right) & \text{se } 2 \le \text{reps} \le 15 \\
0 & \text{se } \text{peso} \le 0 \text{ ou } \text{reps} \le 0
\end{cases}$$

- **Teto Estatístico de 15 Repetições**: Séries com mais de 15 reps medem primordialmente resistência muscular localizada (RML) e não força máxima neuromuscular; portanto, a fórmula limita o multiplicador em 15 para prevenir distorções hiperbólicas nos cálculos de 1RM.
- **Formatação Limpa**: Valores inteiros são apresentados sem casas decimais (`120 kg`), enquanto frações preservam uma casa decimal (`102.5 kg`).
