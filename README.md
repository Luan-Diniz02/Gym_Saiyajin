# 🐉 Gym Saiyajin

<p align="center">
  <strong>Aplicativo mobile offline-first para rastreamento de treinos de musculação, construído com Flutter, SQLite e arquitetura limpa com foco em ergonomia esportiva, robustez visual e temática Saiyajin.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%3E%3D3.22.0-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-%3E%3D3.11.4-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Database-SQLite-003B57?logo=sqlite&logoColor=white" alt="SQLite" />
  <img src="https://img.shields.io/badge/Tests-104%20Passing-brightgreen?logo=checkmarx&logoColor=white" alt="Tests" />
  <img src="https://img.shields.io/badge/License-MIT-F9A825" alt="License" />
</p>

---

## 📸 Demonstração Visual

<p align="center">
  <img src="docs/images/treino.png" width="30%" alt="Tela de Treino" />
  <img src="docs/images/historico.png" width="30%" alt="Histórico" />
  <img src="docs/images/progresso.png" width="30%" alt="Progresso & Ki" />
</p>

---

## 📚 Documentação Especializada

Para manter o repositório organizado e detalhar com profundidade cada engenharia do projeto, a documentação está dividida nos seguintes guias modulares:

- 🏛️ **[Arquitetura & Engenharia de Software](docs/ARQUITETURA.md)**: Detalhamento das camadas do app (Controllers, Repositories, Services, Models), schema do banco de dados SQLite com integridade referencial, estratégias de migração de banco, tratamento de ciclo de vida do SO e matriz da suíte de testes (104 testes automatizados).
- 🎨 **[Design System, Ergonomia & UI/UX](docs/UI_UX.md)**: Princípios de usabilidade sob fadiga física, manifesto de identidade anti-caricatura (seriedade esportiva e fisiologia em primeiro lugar), design tokens, anatomia simétrica das séries, fluxo contínuo de teclado, micro-badges de PRs, proteção de layout (SafeArea/insets), arte vetorial nativa no Canvas (`DragonBallIcon`, `ScouterIcon`, `DragonRadarIcon`, `CapsuleIcon`, `PlanetaKaiohIcon`, `KiAuraIcon`, `EscotilhaCamaraPainter`) e ergonomia do Histórico e do Cronômetro.
- ⚡ **[Sistema Saiyajin & Progressão de Poder (Ki)](docs/SISTEMA_SAIYAJIN.md)**: Matemática da fórmula híbrida do Ki (Força Base, Vigor Saiyajin e Limites Superados), patamares de poder canônicos, design do Super Saiyajin 2, componentes vetoriais nativos, fórmula de Epley refinada para estimativa de 1RM, a jornada de 1.000.000 km no Caminho da Serpente e a Câmara de Regeneração Médica.
- 📸 **[Compartilhamento Social Personalizável](docs/COMPARTILHAMENTO_SOCIAL.md)**: Guia completo do gerador de cartões sociais, proporções Stories (9:16) e Feed (1:1), os 3 presets de overlay (Slim Clássico, Scouter HUD e Rodapé Minimalista), personalização de cores/legenda e pipeline de captura em alta resolução (3x DPI).
- 📜 **[Propostas Temáticas & Próximos Passos](docs/ROADMAP_TEMATICO.md)**: Histórico de implementações canônicas (Caminho da Serpente e Câmara de Regeneração concluídos) e planejamento arquitetural futuro.

---

## 🚀 Funcionalidades Principais

### 🏋️ Treino em Tempo Real
- **Nome & Divisão do Treino**: Chips de seleção rápida padronizados (`Treino A`, `Treino B`, `Push`, `Pull`, `Legs`, etc.) ou nome customizado digitado pelo usuário. Registrado na sessão e estampado na timeline e no card social.
- **Fichas / Templates Permanentes**: Crie, edite e configure rotinas completas com quantidade de séries padrão por exercício (`[-] X [+]`). Enfileiramento em 1 toque.
- **Aparelho Ocupado? Substituição Ágil**: Toque no botão de troca (`Swap`) para substituir um exercício da fila por outro do mesmo grupo muscular sem alterar a ficha base.
- **Carga Anterior Inteligente (Sobrecarga Progressiva)**: O app busca o histórico do exercício e sugere a última carga e reps nos campos (`hintText`) e na linha de apoio. Tocar no check com campos vazios auto-preenche a série com os valores anteriores.
- **Séries com Ergonomia Avançada**: Alinhamento simétrico, fluxo contínuo de teclado (`Next` pula para reps, `Done` conclui a série), micro-badge dinâmico `PR ⚡` em tempo real e remoção rápida de séries via gesto de deslizar (*Swipe*).
- **Escotilha da Câmara de Regeneração Médica (*Medical Machine / Cápsula de Namekusei*)**:
  - Cronômetro de descanso estilizado como a escotilha de inspeção blindada da câmara médica de Dragon Ball Z: aro exterior em liga de titânio escuro com **8 rebites prateados chanfrados**, anel de fluido bioenergético em **Ouro Super Saiyajin e Âmbar** (`#FFD700` $\to$ `#FF8C00`), micro-bolhas de oxigênio com física de subida contínua e silhueta imersiva da máscara respiratória submersa no fundo.
  - **Sincronização Matemática Exata**: Eliminação do delay de 1s via arredondamento teto (`ceil`), garantindo que o cronômetro regressivo e o contador de descanso acumulado permaneçam 100% espelhados segundo a segundo.
  - **Telemetria Médica**: Chip superior com LED pulsante dinâmico (`REGENERAÇÃO` / `PAUSADO` / `CÂMARA DE CURA`) e botões de controle na paleta Saiyajin.
- **Cronômetro Geral de Treino & Segundo Plano**:
  - Duração total da sessão com controle de pausa e retomada.
  - Registro contínuo do tempo total de descanso acumulado.
  - Resiliência contra tela bloqueada com recálculo por timestamp e alerta sonoro/háptico nativo ao zerar o tempo.
- **Encerramento Protegido & Celebração de Conquistas**: Confirmação segura, cálculo imediato do Ki ganho na sessão com bônus de $+150$ Ki por PR conquistado e disparo do modal de compartilhamento.

### 📜 Histórico de Sessões & Caminho da Serpente
- **Caminho da Serpente (*Snake Way*)**:
  - Barra de progresso senoidal contínua com curvas suaves de alta fidelidade matemática, nuvens celestiais do Outro Mundo, aura de Ki do guerreiro e o Planeta do Senhor Kaioh vetorial (`PlanetaKaiohIcon`) na chegada. Sempre visível no card.
  - Card interativo com Kanji Kaioh oficial (**界王**) e alternância de dados analíticos: odômetro de ferro (meta épica de 1.000.000 km), marcos de lore canônica e métricas consolidadas (*Carga Total*, *Tempo Total* e *Sessões*).
- **Timeline Contínua & Sessões Sempre Expandidas**:
  - Navegação vertical fluida sem acordeões fechados: todos os exercícios e séries ficam prontamente visíveis ao rolar a tela.
  - Nós uniformes com ícone de calendário Saiyajin (`Icons.calendar_month`) em laranja vibrante com sombra.
  - Cabeçalho harmonizado em linha única: **Data** + **Tag da Divisão** (`[ TREINO A ]`) + **Badge Dourado de PRs** (`[ ✪ 2 PRs ]`).
  - Linha de métricas esportivas em caixa alta: `EXERCÍCIOS • SÉRIES • VOLUME • DURAÇÃO • DESCANSO`.
- **Menu de Ações Unificado (`⋮`)**: Botão discreto substituindo múltiplos controles dispersos, permitindo *Compartilhar card*, *Editar treino* e *Excluir treino*.
- **Edição Completa de Sessão Salva**: Ajuste de data da sessão, alteração de nome/divisão e steppers ergonômicos de 5 em 5 minutos para duração total e tempo de descanso (com validação fisiológica que impede o descanso de ultrapassar a duração total do treino).
- **Backup & Restauração Completa v2 (JSON)**: Exportação e importação de todo o banco SQLite (sessões e fichas permanentes), meta semanal e composição corporal (peso, altura e percentual de gordura) com opções de **Mesclar Dados** ou **Substituir Tudo** e retrocompatibilidade com a v1.
- **Exclusão Segura**: Confirmação modal com exclusão em cascata transacional (`ON DELETE CASCADE`) no SQLite.

### 📈 Dashboard de Progresso & Métricas
- **Medidor de Poder de Luta (Ki) & Transformações**:
  - Pontuação híbrida unindo força máxima nos 6 grupos musculares, quilometragem de volume histórico e bônus de recordes.
  - Escala canônica de patamares: *Classe Baixa* $\to$ *Guerreiro Z* $\to$ *Elite Saiyajin* $\to$ *Super Saiyajin* $\to$ *Super Saiyajin 2* $\to$ *Super Saiyajin 3* $\to$ *Instinto Superior*.
  - Subtítulos épicos oficiais e badge com gradiente e sombras temáticas.
- **Registro de Poder (Quadro de Recordes)**:
  - Marcado com o ícone oficial da Esfera do Dragão (`DragonBallIcon`), cujas estrelas refletem dinamicamente os recordes conquistados (1 a 7 estrelas).
  - Lista detalhada de maiores cargas e 1RMs estimados com busca instantânea e filtros musculares.
- **Gráfico de Evolução de Cargas (`fl_chart`)**: Curva analítica de sobrecarga progressiva com filtro por exercício.
- **Cálculo de IMC & Metas Corporais**: Marcado com o ícone vetorial da Cápsula Hoi-Poi da Capsule Corp (`CapsuleIcon`), cálculo padrão OMS em 6 faixas e atalhos de atualização rápida.

### 📱 Compartilhamento Social de Alta Performance
- **Proporções Flexíveis**: Alternância entre `STORIES (9:16)` (Instagram Stories / WhatsApp Status) e `FEED (1:1)` (Instagram Feed / WhatsApp Chat).
- **Presets de Overlay**:
  - **Slim Clássico**: Minimalista, divisão e troféu de PRs com DragonBallIcon no topo, e 3 métricas de impacto (Volume, Séries, Duração) na base, valorizando 100% da foto.
  - **Scouter HUD**: Estilo telemetria esportiva com visor holográfico (`ScouterIcon`), ganho de Ki e contador de PRs com `DragonBallIcon`.
  - **Rodapé Minimalista**: Topo totalmente limpo e painel translúcido inferior (*frosted glass*).
- **Customização Total**: Alternância de cor (Branco vs Dourado), campo para `@handle` do atleta e fallback texturizado premium caso não deseje usar foto.

---

## 🛠️ Stack Tecnológico

- **Flutter / Dart** (Framework mobile multiplataforma)
- **sqflite** (Banco de dados relacional offline-first com integridade referencial e migrações)
- **share_plus** (Compartilhamento nativo de cards de imagem PNG e backups JSON)
- **image_picker** (Captura de fotos via câmera e seleção da galeria para o card de treino)
- **file_picker** (Seleção de arquivos de backup JSON no armazenamento local)
- **path_provider** (Gerenciamento de caminhos temporários e de documentos)
- **fl_chart** (Renderização gráfica analítica de curvas de progressão de carga)
- **shared_preferences** (Armazenamento de preferências e configurações chave-valor)
- **flutter_local_notifications & timezone** (Notificações locais agendadas e resiliência de alarmes)
- **flutter_ringtone_player** (Alerta sonoro nativo de alarme para encerramento de descansos)
- **vibration** (Feedback háptico de hardware)
- **flutter_test** (Suíte robusta de testes unitários e de integração)

---

## 🏛️ Estrutura de Arquivos

```text
gym_saiyajin/
├── docs/                               # Documentação técnica especializada
│   ├── ARQUITETURA.md                  # Camadas, SQLite, migrações e testes
│   ├── SISTEMA_SAIYAJIN.md             # Matemática do Ki, patamares e ícones vetoriais
│   ├── COMPARTILHAMENTO_SOCIAL.md      # Presets, proporções 9:16/1:1 e exportação
│   ├── ROADMAP_TEMATICO.md             # Planejamento: Semente dos Deuses, Caminho da Serpente
│   └── images/                         # Assets visuais da documentação
├── lib/
│   ├── controllers/                    # Gerenciamento de estado reativo (ChangeNotifier)
│   │   ├── historico_controller.dart
│   │   ├── progresso_controller.dart
│   │   └── treino_controller.dart
│   ├── database/                       # Helper do SQLite, PRAGMAs e migrações (v1 -> v3)
│   │   └── db_helper.dart
│   ├── models/                         # Entidades de domínio imutáveis com serialização
│   │   ├── exercicio.dart
│   │   ├── ficha_treino.dart
│   │   ├── poder_luta.dart
│   │   ├── recorde_pessoal.dart
│   │   ├── serie.dart
│   │   └── sessao_treino.dart
│   ├── repositories/                   # Acesso a dados transacionais e queries preparadas
│   │   └── treino_repository.dart
│   ├── screens/                        # Telas principais (Treino, Histórico, Progresso)
│   │   ├── historico_screen.dart
│   │   ├── progresso_screen.dart
│   │   └── treino_screen.dart
│   ├── services/                       # Infraestrutura, Hardware e Compartilhamento
│   │   ├── backup_service.dart
│   │   ├── card_share_service.dart
│   │   ├── notification_service.dart
│   │   └── preferences_service.dart
│   ├── theme/                          # Design Tokens e paleta de cores centralizada
│   │   └── app_colors.dart
│   └── widgets/                        # Componentes visuais atômicos e CustomPainters
│       ├── caminho_serpente_progress_bar.dart # Barra senoidal contínua e Planeta Kaioh
│       ├── capsule_icon.dart           # CustomPainter da Cápsula Hoi-Poi da Capsule Corp
│       ├── celebracao_transformacao_modal.dart
│       ├── compartilhar_card_modal.dart
│       ├── config_tempo_descanso_modal.dart
│       ├── cronometro_widget.dart
│       ├── dragon_ball_icon.dart       # CustomPainter das Esferas do Dragão (1-7 estrelas)
│       ├── dragon_radar_icon.dart      # CustomPainter do Radar do Dragão (meta semanal)
│       ├── gerenciar_fichas_modal.dart
│       ├── historico_card_widget.dart
│       ├── ki_aura_icon.dart           # CustomPainter da Aura de Ki Saiyajin
│       ├── metricas_dashboard_widget.dart
│       ├── modal_editar_sessao.dart
│       ├── modal_encerrar_treino.dart
│       ├── modal_importar_backup.dart
│       ├── planeta_kaioh_icon.dart     # CustomPainter do Planeta do Sr. Kaioh
│       ├── poder_luta_card_widget.dart
│       ├── progresso_grafico_widget.dart
│       ├── quadro_recordes_modal.dart
│       ├── scouter_icon.dart           # CustomPainter do Scouter com lente e telemetria
│       ├── selecao_exercicio_modal.dart
│       ├── serie_anterior_chip.dart
│       ├── serie_row_widget.dart
│       └── status_barra_treino.dart
├── test/                               # Suíte de 104 testes automatizados
│   ├── backup_test.dart
│   ├── caminho_serpente_test.dart
│   ├── capsule_icon_test.dart
│   ├── compartilhar_card_test.dart
│   ├── cronometro_widget_test.dart
│   ├── dragon_ball_icon_test.dart
│   ├── dragon_radar_icon_test.dart
│   ├── ficha_test.dart
│   ├── imc_test.dart
│   ├── ki_aura_icon_test.dart
│   ├── notification_service_test.dart
│   ├── poder_luta_test.dart
│   ├── pr_test.dart
│   ├── render_preview_test.dart
│   ├── serie_row_widget_test.dart
│   ├── tempo_treino_test.dart
│   ├── treino_controller_test.dart
│   └── treino_repository_test.dart
├── pubspec.yaml
└── README.md
```

---

## 🧪 Como Executar e Testar

### Pré-requisitos
- Flutter SDK instalado (`>= 3.22.0`)
- Dispositivo Android conectado via USB (com depuração ativada) ou emulador

### Comandos
```bash
# Obter dependências do projeto
flutter pub get

# Executar a suíte completa de testes automatizados (104 testes)
flutter test

# Verificar análise estática de código (Linter)
dart analyze

# Executar a aplicação em modo debug
flutter run

# Compilar pacote de produção otimizado (Release APK)
flutter build apk
```

---

## 📄 Licença

Distribuído sob a licença MIT. Consulte `LICENSE` para mais detalhes.
