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
- **Catálogo & Criação de Exercícios**: Modal de busca instantânea com barra de pesquisa por texto e chips de filtragem por grupo muscular (`TODOS`, `PEITO`, `COSTAS`, `PERNAS`, etc.). Suporte a criação dinâmica de novos exercícios personalizados.
- **Séries com Ergonomia Avançada**: 
  - Alinhamento horizontal simétrico entre número da série, inputs numéricos e botão de conclusão (*Check*).
  - Remoção intuitiva e ágil de séries individuais via gesto de **Swipe** (*deslizar para a esquerda*), com feedback tátil e prevenção de exclusão acidental.
  - Navegação acelerada de teclado com salto automático de foco (*Next*) entre Peso e Repetições.
- **Cronômetro de Treino & Descanso em Tempo Real**:
  - **Tempo Total de Treino**: Iniciação automática na primeira interação, contagem precisa em segundo plano com controle de pausa/retomada.
  - **Tempo de Descanso Total Acumulado**: Registra e consolida todo o tempo que o usuário passou descansando entre as séries ao longo de toda a sessão.
  - **Cronômetro Regressivo Inteligente**: Visor circular com anel de progresso nítido, sincronizado com o ciclo de vida do sistema, alerta sonoro nativo e vibração háptica contínua.
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
│       ├── historico_card_widget.dart
│       ├── metricas_dashboard_widget.dart
│       ├── progresso_grafico_widget.dart
│       ├── selecao_exercicio_modal.dart
│       └── serie_row_widget.dart
├── test/                       # Suíte de testes unitários automatizados
│   ├── backup_test.dart
│   ├── imc_test.dart
│   ├── tempo_treino_test.dart
│   └── treino_controller_test.dart
└── pubspec.yaml
```

---

## 💾 Banco de Dados (SQLite)

* Arquivo: `gym_saiyajin.db` (Versão do schema: `2`)
* `PRAGMA foreign_keys = ON;` ativo via callback `onConfigure`
* Migração transacional automática via `onUpgrade` (versão 1 -> 2)
* Tabelas:
  * `sessoes`: `id`, `data`, `nome_treino`, `duracao_segundos`, `descanso_total_segundos`
  * `exercicios`: `id`, `sessao_id`, `nome`, `grupo`
  * `series`: `id`, `exercicio_id`, `peso`, `reps`, `concluida`
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
