# 🥋 Relatório de Auditoria UI/UX — Gym Saiyajin

> **Projeto**: `gym_saiyajin`  
> **Objetivo**: Avaliação aprofundada de Design, Usabilidade, Arquitetura de Interface, Acessibilidade e Experiência do Usuário (UX) no ecossistema Flutter.  
> **Especialidade**: UI/UX para Flutter Applications & Fitness Systems.

---

## 1. Visão Geral e Impressões Iniciais

O **Gym Saiyajin** apresenta uma identidade visual temática (**Dragon Ball Z / Fitness**) altamente criativa, imersiva e consistente com a proposta de gamificação do treino:
- **Câmara de Regeneração Namekusei** estilizada para o cronômetro de descanso;
- **Caminho da Serpente** com curva senoidal procedural para progressão de volume histórico rumo ao Planeta do Sr. Kaioh;
- **Radar do Dragão** para monitoramento da meta semanal de treinos;
- **Cápsula Hoi-Poi** para composição corporal / IMC / %BF;
- **Esferas do Dragão** indicando Recordes Pessoais batidos (PRs);
- **Scouter e Patamares de Transformação** (Classe Baixa até Instinto Superior) vinculados ao cálculo de Ki acumulado.

Apesar da excelente direção de arte e do ótimo uso de haptics (`HapticFeedback`), a auditoria identificou **fricções ergonômicas críticas na rotina de academia**, **estados de loading ausentes (Empty State Flash)**, **riscos de perda acidental de dados** e **oportunidades de padronização arquitetural do Material Design 3**.

---

## 2. Pontos Fortes Identificados (UI/UX Highlights)

1. **Feedback Multissensorial Imersivo**:
   - Uso cirúrgico de `HapticFeedback.lightImpact()`, `selectionClick()` e `heavyImpact()` ao interagir com cronômetro, séries, transformações e botões.
   - Integração de alarme sonoro (`FlutterRingtonePlayer`) e vibração adaptativa (`Vibration`) para o término do descanso.
2. **Design System Temático Customizado**:
   - Ícones e ilustrações vetoriais procedurais usando `CustomPainter` (`EscotilhaCamaraPainter`, `CaminhoSerpenteProgressBar`, `DragonRadarIcon`, `DragonBallIcon`, `CapsuleIcon`, `ScouterIcon`, `PlanetaKaiohPainter`), eliminando rasterização borrada e mantendo o bundle leve.
3. **Card Studio de Compartilhamento Social**:
   - `CompartilharCardModal` oferece suporte a Stories (9:16) e Feed (1:1), personalização com foto real do usuário, 3 presets de layout (Slim, HUD Scouter e Minimalista) e renderização em imagem sem travamentos via `RepaintBoundary`.
4. **Entrada de Dados com Formatação Adaptada ao Brasil**:
   - Formatação que aceita vírgula ou ponto para casas decimais no peso (`_pesoInputFormatter`), essencial para teclados numéricos brasileiros.
5. **Preservação de Estado entre Abas**:
   - Uso de `IndexedStack` na navegação inferior, permitindo ao usuário consultar o histórico ou gráficos sem perder o treino em andamento.

---

## 3. Matriz de Severidade dos Apontamentos

| ID | Categoria | Descrição do Apontamento | Severidade |
|---|---|---|:---:|
| **UX-01** | Ergonomia / Dados | Exclusão de série por arrasto (Dismissible) sem diálogo de confirmação e sem botão de "Desfazer" | 🔴 **Crítico** |
| **UX-02** | Fluxo de Treino | Método `preencherSerieComAnterior` implementado no controller, mas não conectado à UI (usuário é forçado a redigitar tudo) | 🔴 **Crítico** |
| **UX-03** | Navegação / Sistema | Ausência de `PopScope`: toque no botão "Voltar" do Android minimiza/fecha o app sem salvar o treino | 🔴 **Crítico** |
| **UX-04** | Usabilidade / Interrupção | Dialog de fim de descanso com `barrierDismissible: false` bloqueia todo o app com modal intrusivo | 🟡 **Médio** |
| **UX-05** | Loading States | Falta de flag de carregamento assíncrono gerando "flash" de tela vazia (Empty State Flicker) no Histórico e Progresso | 🟡 **Médio** |
| **UX-06** | Gestão de Fichas | Falta de reordenação arrastável (`ReorderableListView`) no editor de fichas e alvos de toque abaixo de 48dp | 🟡 **Médio** |
| **UX-07** | Dados Padrão / Onboarding | Valores arbitrários hardcoded (69.0 kg / 1.70 m) criam falso diagnóstico inicial de IMC para novos usuários | 🟡 **Médio** |
| **UI-01** | Consistência Visual | Proliferação de cores hexadecimais hardcoded fora de `AppColors` e ausência de suporte/configuração a `ThemeData` global | 🟢 **Baixo** |
| **UI-02** | Tipografia / Acessibilidade | TextFields e botões com alturas rígidas (`height: 44`) suscetíveis a corte de texto com Text Scaling alto | 🟢 **Baixo** |
| **UI-03** | Identidade Visual | Falta de tipografia customizada temática (ex: Bebas Neue / Orbitron) para enriquecer o visual anime arcade | 💡 **Sugestão** |

---

## 4. Análise Detalhada dos Problemas e Soluções Recomendadas

---

### 🔴 UX-01: Exclusão Acidental de Séries via Dismissible sem Confirmação ou Undo
- **Arquivo**: `lib/widgets/serie_row_widget.dart` (Linhas 306-345)
- **Cenário Real de Uso**: O atleta está na academia com mãos suadas ou descansando entre séries. Ao tentar fazer o scroll vertical da lista de séries, acidentalmente faz um leve gesto horizontal para a esquerda.
- **Impacto**: O widget `Dismissible` apaga a série instantaneamente do exercício atual. A SnackBar emitida não contém nenhuma `SnackBarAction` ("Desfazer"). O peso e repetições digitados são perdidos para sempre.
- **Trecho Problemático**:
```dart
return Dismissible(
  key: ValueKey('serie_${nomeExercicioAtual}_${serie.hashCode}_${widget.index}'),
  direction: DismissDirection.endToStart,
  // ⚠️ Falta confirmDismiss!
  onDismissed: (_) {
    widget.controller.removerSerie(widget.index);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Série ${widget.index + 1} removida.'),
        duration: const Duration(seconds: 2), // ⚠️ Sem ação de desfazer!
      ),
    );
  },
  child: cardConteudo,
);
```
- **Solução Recomendada**:
  1. Adicionar `confirmDismiss` exigindo confirmação caso a série contenha peso ou repetições preenchidos;
  2. Implementar suporte a restauração no `TreinoController` e adicionar botão `SnackBarAction(label: 'DESFAZER', onPressed: ...)` na SnackBar.

---

### 🔴 UX-02: Ação Rápida de Auto-preenchimento Órfã (`preencherSerieComAnterior`)
- **Arquivo**: `lib/controllers/treino_controller.dart` (Linhas 614-637) vs `lib/widgets/serie_row_widget.dart` (Linhas 102-110, 215-265)
- **Problema de UX**: Nos principais apps de musculação do mercado (Hevy, Strong, RepCount), o usuário pode copiar os valores da última sessão com um único toque. No Gym Saiyajin, o controller possui a lógica pronta:
```dart
bool preencherSerieComAnterior(int index) { ... }
```
  Porém, na tela, o método **nunca é chamado**. O usuário visualiza o peso e repetições anteriores apenas como texto de dica cinza (`hintText`), mas tocar no hint não preenche nada. O usuário é obrigado a abrir o teclado numérico e digitar manualmente os mesmos valores todas as vezes.
- **Solução Recomendada**:
  1. Tornar o toque no `hintText` ou adicionar um botão de atalho rápido (ex: ícone de histórico / chip "Repetir anterior") que acione `controller.preencherSerieComAnterior(widget.index)`.
  2. Sincronizar imediatamente os `TextEditingController` dos campos de peso e repetições.

---

### 🔴 UX-03: Falta de Controle de Saída (`PopScope`) e Risco de Perda de Treino Ativo
- **Arquivo**: `lib/main.dart` (Linhas 119-147)
- **Problema de UX**: No Android, o botão/gesto nativo de "Voltar" (Back gesture) encerra ou minimiza o app imediatamente caso o usuário esteja em qualquer aba.
- **Cenário de Risco**: O usuário está na metade de um treino volumoso (4 exercícios feitos, 1 em andamento), navega até a aba "Progresso" para checar uma carga antiga, e aperta o botão voltar esperando retornar à aba "Treino". Em vez disso, o app fecha.
- **Solução Recomendada**:
  Envolver o `Scaffold` de `TelaBase` com `PopScope`:
```dart
PopScope(
  canPop: _indiceAtual == 0 && !_treinoController.temExercicioEmAndamento && _treinoController.exerciciosConcluidosHoje.isEmpty,
  onPopInvokedWithResult: (didPop, result) async {
    if (didPop) return;
    if (_indiceAtual != 0) {
      setState(() => _indiceAtual = 0); // Retorna primeiro à aba Treino
      return;
    }
    // Se há treino em andamento, alerta o usuário antes de sair
    final sair = await _mostrarDialogoConfirmarSaidaTreino();
    if (sair == true && context.mounted) {
      SystemNavigator.pop();
    }
  },
  child: Scaffold(...),
)
```

---

### 🟡 UX-04: Alerta de Descanso Invasivo (`barrierDismissible: false`)
- **Arquivo**: `lib/screens/treino_screen.dart` (Linhas 76-128)
- **Problema de UX**: Quando o cronômetro atinge 00:00, o app dispara vibração, som e abre um `AlertDialog` com `barrierDismissible: false`:
```dart
void _mostrarDialogoDescansoFinalizado() {
  showDialog(
    context: context,
    barrierDismissible: false, // ⚠️ Bloqueio total da UI
    builder: (context) => AlertDialog(
      title: Text('REGENERAÇÃO CONCLUÍDA!'),
      actions: [ElevatedButton(child: Text('BORA!'), onPressed: () => Navigator.pop(context))],
    ),
  );
}
```
  Se o usuário estiver no meio de uma anotação, escolhendo um exercício no modal de busca ou ajustando as fichas, o diálogo abre por cima, toma o foco e exige que o atleta pare o que estiver fazendo para tocar no botão "BORA!".
- **Solução Recomendada**:
  Substituir o `AlertDialog` bloqueante por uma **notificação in-app não intrusiva** (Banner deslizante no topo ou SnackBar flutuante elegante) que desapareça sozinha em 4 segundos ou com um toque, sem bloquear a digitação e a visualização do treino.

---

### 🟡 UX-05: Flicker de Estado Vazio (Falta de Loading States nos Controllers)
- **Arquivos**: `lib/controllers/historico_controller.dart` e `lib/controllers/progresso_controller.dart`
- **Problema de UX**:
  1. `_sessoesTreino` inicia como lista vazia `[]`.
  2. Ao abrir o app, `HistoricoScreen` avalia `historico.isEmpty` e monta a ilustração com o texto: `"NENHUM TREINO REGISTRADO AINDA - O caminho de um guerreiro começa..."`.
  3. Milissegundos depois, o SQLite termina de ler o banco e notifica os ouvintes, fazendo a lista de treinos saltar na tela de forma abrupta.
  4. O mesmo ocorre no `ProgressoScreen`: o radar e os gráficos exibem valores de fallback antes do término da leitura.
- **Solução Recomendada**:
  Adicionar a propriedade `bool _isLoading = true;` em ambos os controllers. Na interface:
  - Exibir um **Skeleton Shimmer** ou um `CircularProgressIndicator` temático (Ki Orb pulsante) enquanto `isLoading` for `true`.
  - Exibir o `_buildEmptyState()` **apenas se** `!isLoading && historico.isEmpty`.

---

### 🟡 UX-06: Editor de Fichas com Ergonomia Deficiente e Sem Reordenação
- **Arquivo**: `lib/widgets/gerenciar_fichas_modal.dart` (Linhas 973-1109)
- **Problemas Identificados**:
  1. **Sem Drag & Drop**: Enquanto na tela principal os próximos exercícios da ficha podem ser reordenados com arrasto (`ReorderableListView`), no editor de fichas a lista é um `ListView.separated` estático. Para trocar a ordem, o usuário precisa deletar exercícios e adicioná-los novamente.
  2. **Touch Targets de 28dp**: Os botões de stepper `[-]` e `[+]` e o botão de exclusão da linha utilizam:
     `constraints: const BoxConstraints(minWidth: 28, minHeight: 28)`
     Isso viola as diretrizes de acessibilidade (mínimo de 48x48 dp para toque confortável sem erros).
- **Solução Recomendada**:
  - Migrar para `ReorderableListView` com `ReorderableDragStartListener`.
  - Aumentar a área de clique para o padrão ergonômico de pelo menos 44x44 dp ou 48x48 dp.

---

### 🟡 UX-07: Valores Padrão Arbitrários (69kg / 1.70m) Criam Diagnóstico Fantasma
- **Arquivo**: `lib/controllers/progresso_controller.dart` (Linhas 24-28, 86-98)
- **Problema de UX**:
```dart
double _pesoAtual = 69.0;
double _altura = 1.70;
```
  Se um usuário acabou de instalar o aplicativo e vai até a aba de Progresso, ele visualiza imediatamente:
  - Peso: `69.0 kg`
  - IMC: `23.9` - `PESO NORMAL`
  Essa métrica é fictícia. Não reflete a realidade do atleta e pode induzir ao erro.
- **Solução Recomendada**:
  Permitir `double? _pesoAtual;` e `double? _altura;`.
  Se forem nulos, exibir um banner acolhedor no card de IMC:
  `"Toque para cadastrar seu peso e altura e acompanhar sua evolução física"`.

---

### 🟢 UI-01 & UI-02: Consistência Visual, Tema Global e Text Scaling
- **Arquivos**: `lib/theme/app_colors.dart`, `lib/main.dart` e múltiplos widgets em `lib/widgets/`
- **Problemas**:
  1. Cores pontuais como `Color(0xFF00E676)`, `Color(0xFFFFD700)`, `Color(0xFFFF9E00)`, `Color(0xFF13141B)`, `Color(0xFF0F1015)` estão instanciadas diretamente nos widgets em vez de referenciar `AppColors`.
  2. O `ThemeData` no `main.dart` não centraliza estilos de botões, inputs e dialogs. Cada modal define manualmente seu próprio `shape`, `borderRadius` e `borderSide`, gerando variações invisíveis (raios de 12, 14, 16, 18, 20, 24).
  3. Em `SerieRowWidget`, o campo de texto possui `SizedBox(height: 44, child: TextField(...))`. Caso o usuário ative tamanhos de fontes aumentados nas configurações de acessibilidade do smartphone (Dynamic Font Scaling), o texto é cortado verticalmente.

---

## 5. Plano de Ação Recomendado (Roadmap de Melhorias)

### Fase 1: Correções Críticas (Segurança de Dados e Fricção de Treino)
1. Conectar o método `preencherSerieComAnterior` na UI de `SerieRowWidget` (ao tocar no hint ou via chip "Repetir anterior").
2. Adicionar confirmação no `Dismissible` de séries e botão `DESFAZER` na `SnackBar`.
3. Implementar `PopScope` no `TelaBase` protegendo sessões em andamento contra saídas acidentais.

### Fase 2: Polimento de Usabilidade e Ergonomia
4. Substituir o `AlertDialog` bloqueante de descanso concluído por um banner animado suave no topo da tela.
5. Adicionar estado `isLoading` e Shimmer Skeleton no Histórico e no Progresso para eliminar o piscar da tela vazia.
6. Atualizar o `_FichaEditorBottomSheet` para usar `ReorderableListView` e elevar os botões de controle para 44-48dp de área de toque.
7. Tratar peso e altura iniciais como nulos para convidar o novo usuário a preencher seus dados.

### Fase 3: Padronização Visual e Acessibilidade
8. Centralizar todas as cores avulsas em `AppColors` e configurar `ThemeData` global (InputDecoration, Dialogs, Cards).
9. Ajustar `contentPadding` dinâmico nos inputs para suportar fontes ampliadas de acessibilidade sem overflow.
10. Opcional: Adicionar uma fonte temática futurista/arcade no `pubspec.yaml` para números de cronômetro, Ki e cargas.
