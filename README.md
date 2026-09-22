# Gym Saiyajin

Aplicativo mobile offline-first para rastreamento de treinos de musculação, construído com Flutter, SQLite e arquitetura limpa com foco em ergonomia esportiva, robustez visual e temática Saiyajin.

---

## 📸 Demonstração Visual

<p align="center">
  <img src="docs/images/treino.png" width="30%" />
  <img src="docs/images/historico.png" width="30%" />
  <img src="docs/images/progresso.png" width="30%" />
</p>

---

## 🚀 Funcionalidades Principais

### 🏋️ Treino em Tempo Real
- **Nome & Divisão do Treino**:
  - Barra superior de chips rápidos padronizados (`Treino A`, `Treino B`, `Treino C`, `Push`, `Pull`, `Legs`, `Superiores`, `Inferiores`) e botão para digitação de nomes customizados.
  - O nome é registrado na sessão, exibido com badge dourado na timeline do histórico e estampado no card de compartilhamento para redes sociais.
- **📋 Fichas / Templates de Treino Pré-configurados**:
  - **Criação & Edição Completa**: Crie novas fichas ou edite rotinas existentes (alteração do nome, adição/remoção de exercícios e personalização da quantidade de séries padrão por exercício através de seletores ergonômicos `[-] X [+]`).
  - **Visualização Adaptativa e Sem Truncamento**: Modo recolhido exibe 2 exercícios com suas respectivas séries e badge de excedentes (`+X`), além de alternância para modo expandido exibindo a lista completa sem cortes de nomes longos.
  - **Proteção de Interface (SafeArea)**: Layout com tratamento de margens inferiores e insets dinâmicos, impedindo qualquer sobreposição da barra de navegação do sistema Android.
  - **Carregamento em 1 Toque**: Escolha uma rotina pré-configurada na gaveta de fichas e inicie o treino com todos os exercícios já enfileirados.
  - **Aparelho Ocupado? Substituição Ágil**: Se uma máquina estiver em uso, toque no botão de troca (`Swap`) para substituir o exercício (atual ou pendente na fila) por outro do mesmo grupo muscular sem alterar a ficha base.
  - **Salvar Treino como Ficha**: Transforme a sessão do dia em um template permanente com um único toque.
  - **Liberdade Total**: Adicione novos exercícios extras a qualquer momento ou exclua exercícios do dia mantendo a ficha original intacta.
- **👻 "Carga Anterior" de Referência (Sobrecarga Progressiva)**:
  - Ao iniciar qualquer exercício, o app busca automaticamente o histórico da última sessão concluída.
  - Carga e repetições aparecem como sugestão suave nos inputs (`hintText`) e em uma linha discreta de apoio (`Anterior: X kg × Y reps`), facilitando a progressão contínua de carga (*Progressive Overload*).
  - **Preenchimento Inteligente em 1 Toque**: Ao tocar no botão de check com os inputs vazios, o app preenche automaticamente a série com os valores da carga anterior.
- **Catálogo & Criação de Exercícios**: Modal de busca instantânea com barra de pesquisa por texto e chips de filtragem por grupo muscular (`TODOS`, `PEITO`, `COSTAS`, `PERNAS`, etc.). Suporte a criação dinâmica de novos exercícios personalizados.
- **Séries com Ergonomia Avançada**: 
  - Alinhamento horizontal simétrico entre número da série, inputs numéricos e botão de conclusão (*Check*).
  - **Fluxo Contínuo de Teclado**: Foco no campo de Peso com tecla de ação `Next` pula diretamente para Reps; tecla `Done` (Enter) em Reps valida e conclui a série imediatamente sem fechar o teclado.
  - **Estabilidade Total de Foco**: Ciclo de digitação blindado contra fechamentos involuntários do teclado causados por rebuilds ou ticks do cronômetro.
  - Remoção intuitiva e ágil de séries individuais via gesto de **Swipe** (*deslizar para a esquerda*), com feedback tátil e prevenção de exclusão acidental.
- **Cronômetro de Treino & Descanso em Tempo Real**:
  - **Tempo Total de Treino**: Iniciação automática na primeira interação, contagem precisa em segundo plano com controle de pausa/retomada.
  - **Tempo de Descanso Total Acumulado**: Registra e consolida todo o tempo que o usuário passou descansando entre as séries ao longo de toda a sessão.
  - **Cronômetro Regressivo Inteligente**: Visor circular com anel de progresso nítido, sincronizado com o ciclo de vida do sistema, alerta sonoro nativo, vibração háptica contínua e blindagem contra notificações duplicadas com cancelamento atômico de alarmes e controle de concorrência sequencial.
  - **Modal de Ajuste de Tempo**: Visor digital integrado (`MIN : SEG`), botões satélites de ajuste fino `+/- 15s` e grade simétrica 3x2 de atalhos rápidos padronizados (`00:45`, `1:00`, `1:30`, `2:00`, `3:00`, `4:00`).
- **Encerramento Protegido**: Validação contra fechamento acidental com exercícios pendentes, gravação transacional segura no banco de dados e disparo automático do modal de compartilhamento.

### 📜 Histórico de Sessões & Compartilhamento
- **Efeito de Timeline Clássico**: Linha vertical contínua conectando os dias de treino com nós circulares de calendário.
- **Métricas Consolidadas no Cabeçalho**: Resumo da sessão com quantidade de exercícios, total de séries, **Volume Total Levantado** ($\sum \text{reps} \times \text{peso}$), **Duração Total** e **Tempo de Descanso Acumulado**.
- **Cards de Exercícios Limpos**: Detalhamento expansível de cada exercício exibindo grupo muscular e histórico de séries, livre de poluição visual.
- **Card Visual Saiyajin para Compartilhamento (PNG)**:
  - Geração de card estilizado de alta definição (proporção ideal para Instagram Stories, WhatsApp Status e redes sociais).
  - Personalização com foto: tire uma foto na hora pela câmera, selecione da galeria ou use o tema escuro/dourado Saiyajin nativo.
  - Destaque das principais métricas do treino e principais exercícios com suas maiores cargas.
  - Exportação e compartilhamento direto de imagem PNG ou texto formatado via `share_plus`.
- **Backup & Restauração Completa (JSON)**:
  - **Exportar Histórico**: Gera arquivo JSON estruturado com todas as sessões, exercícios, séries e exercícios customizados.
  - **Importar Histórico**: Carregamento seguro via seletor de arquivos com opção de **Mesclar Dados** (evita duplicatas) ou **Substituir Tudo**.
- **Empty State Motivacional**: Ilustração e mensagem temática encorajadora para novos usuários ou histórico zerado.
- **Exclusão Segura**: Confirmação modal e exclusão em cascata transacional (`ON DELETE CASCADE`) no SQLite.

### 📈 Dashboard de Progresso & Métricas
- **Cálculo de IMC Completo (Padrão OMS)**: Classificação oficial em 6 faixas (*Abaixo do peso, Peso normal, Sobrepeso, Obesidade I, II e III*).
- **Consistência de Interação**: Cards superiores centralizados com atalho rápido de edição tanto para Meta Semanal quanto para Medidas Corporais.
- **Gráfico de Progressão de Cargas (`fl_chart`)**:
  - Curva de sobrecarga progressiva (*Progressive Overload*) por exercício ao longo das datas.
  - Seletor moderno de exercício integrado com lupa, campo de busca e chips de grupos musculares.
  - *Empty State* inteligente orientando o usuário caso o exercício possua menos de 2 registros para traçar a evolução.

---

## 🛠️ Stack Tecnológico

- **Flutter / Dart** (Framework mobile multiplataforma)
- **sqflite** (Banco de dados relacional offline-first com integridade referencial e migrações)
- **share_plus** (Compartilhamento nativo de cards PNG e backups JSON)
- **image_picker** (Captura de fotos via câmera e seleção da galeria para o card)
- **file_picker** (Seleção de arquivos de backup JSON no dispositivo)
- **path_provider** (Armazenamento temporário para exportação de mídias e arquivos)
- **fl_chart** (Renderização gráfica analítica de alta performance)
- **shared_preferences** (Armazenamento de preferências e configurações chave-valor)
- **flutter_local_notifications & timezone** (Notificações agendadas e alertas em segundo plano)
- **flutter_ringtone_player** (Alerta sonoro nativo de alarme)
- **vibration** (Feedback háptico nativo de hardware)
- **flutter_test** (Testes unitários e de integração de regras de negócio)

---

## 🏛️ Arquitetura do Código

O projeto adota uma arquitetura em camadas orientada a responsabilidade única:

```text
gym_saiyajin/
├── lib/
│   ├── controllers/            # Gerenciamento de estado e regras de negócio (ChangeNotifier)
│   │   ├── historico_controller.dart
│   │   ├── progresso_controller.dart
│   │   └── treino_controller.dart
│   ├── database/               # Configuração, migrações e schema do SQLite
│   │   └── db_helper.dart
│   ├── models/                 # Entidades de domínio tipadas com serialização JSON
│   │   ├── exercicio.dart
│   │   ├── serie.dart
│   │   └── sessao_treino.dart
│   ├── repositories/           # Abstração de acesso a dados, backup e queries transacionais
│   │   └── treino_repository.dart
│   ├── screens/                # Composição visual das telas principais
│   │   ├── historico_screen.dart
│   │   ├── progresso_screen.dart
│   │   └── treino_screen.dart
│   ├── services/               # Serviços de infraestrutura, notificações e backups
│   │   ├── backup_service.dart
│   │   ├── card_share_service.dart
│   │   ├── notification_service.dart
│   │   └── preferences_service.dart
│   ├── theme/                  # Design Tokens e paleta de cores centralizada
│   │   └── app_colors.dart
│   └── widgets/                # Componentes visuais modulares e reutilizáveis
│       ├── compartilhar_card_modal.dart
│       ├── config_tempo_descanso_modal.dart
│       ├── cronometro_widget.dart
│       ├── gerenciar_fichas_modal.dart
│       ├── historico_card_widget.dart
│       ├── metricas_dashboard_widget.dart
│       ├── modal_encerrar_treino.dart
│       ├── progresso_grafico_widget.dart
│       ├── selecao_exercicio_modal.dart
│       └── serie_row_widget.dart
├── test/                       # Suíte de testes unitários automatizados
│   ├── backup_test.dart
│   ├── ficha_test.dart
│   ├── imc_test.dart
│   ├── notification_service_test.dart
│   ├── tempo_treino_test.dart
│   └── treino_controller_test.dart
└── pubspec.yaml
```

---

## 💾 Banco de Dados (SQLite)

* Arquivo: `gym_saiyajin.db` (Versão do schema: `3`)
* `PRAGMA foreign_keys = ON;` ativo via callback `onConfigure`
* Migrações transacionais automáticas via `onUpgrade` (versão 1 -> 2 -> 3)
* Tabelas:
  * `sessoes`: `id`, `data`, `nome_treino`, `duracao_segundos`, `descanso_total_segundos`
  * `exercicios`: `id`, `sessao_id`, `nome`, `grupo`
  * `series`: `id`, `exercicio_id`, `peso`, `reps`, `concluida`
  * `fichas`: `id`, `nome`, `descricao`
  * `ficha_exercicios`: `id`, `ficha_id`, `nome`, `grupo`, `ordem`, `series_padrao`
* Índices dedicados em chaves estrangeiras para otimização de consultas e exclusão em cascata.

---

## 🧪 Como Executar e Testar

### Pré-requisitos
- Flutter SDK instalado (`>= 3.11.4`)
- Dispositivo Android conectado ou emulador

### Comandos Úteis
```bash
# Instalar dependências
flutter pub get

# Executar testes unitários
flutter test

# Análise estática de código (Linter)
dart analyze

# Executar no dispositivo em modo desenvolvimento
flutter run

# Compilar APK de Release (Otimizado)
flutter build apk

# Compilar APK de Debug
flutter build apk --debug
```

---

## 📄 Licença

Distribuído sob a licença MIT. Consulte `LICENSE` para mais detalhes.
