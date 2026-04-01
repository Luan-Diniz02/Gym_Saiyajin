# Gym Saiyajin

Aplicativo Flutter para registro de treinos com foco em:

- Fluxo rápido de treino (exercícios, séries e cronômetro de descanso)
- Histórico persistido em SQLite
- Dashboard de progresso com métricas e gráfico de progressão de carga

## Visão Geral

O projeto foi refatorado para uma base mais limpa e escalável, com:

- Modelos tipados (sem uso de Map<String, dynamic> no domínio)
- Controllers com ChangeNotifier para regras de negócio
- Camada de repositório para persistência no SQLite
- Widgets extraídos para UI mais declarativa e reutilizável

## Stack

- Flutter (Dart)
- sqflite
- path
- fl_chart

## Arquitetura Atual

Organização principal em camadas:

- models: entidades de domínio
- controllers: estado + regras de negócio
- repositories: acesso a dados (SQLite)
- database: configuração e schema do banco
- widgets: componentes visuais reutilizáveis
- screens: composição de telas

### Modelos

- Serie
	- peso, reps, concluida
- Exercicio
	- nome, grupo, seriesDetalhes
- SessaoTreino
	- id (opcional), data (opcional), exerciciosConcluidosHoje, exercicioAtual

### Persistência (SQLite)

Banco: gym_saiyajin.db

Tabelas relacionais:

- sessoes
	- id, data, nome_treino
- exercicios
	- id, sessao_id, nome, grupo
- series
	- id, exercicio_id, peso, reps, concluida

Repositório principal:

- TreinoRepository
	- salvarSessaoTreino(sessao): transacional, grava sessão -> exercícios -> séries
	- buscarHistoricoTreinos(): reconstrói lista de sessões com dados aninhados

## Funcionalidades Implementadas

### Treino

- Seleção de exercício com:
	- busca por nome/grupo
	- criação de novo exercício via modal (seleção de grupo muscular)
- Registro de séries (peso/reps)
- Marcação de série concluída
- Cronômetro global de descanso com:
	- iniciar, pausar, reiniciar, continuar
	- anel de progresso visual que esvazia com o tempo
	- alerta ao finalizar descanso
- Encerramento do treino com persistência no SQLite

### Histórico

- Carregamento real do SQLite via TreinoRepository
- Timeline de sessões
- Cards expansíveis por exercício com detalhamento de séries

### Progresso

- Carregamento real a partir do histórico persistido
- Cálculo de métricas:
	- IMC
	- dias ativos na janela dos últimos 7 dias
- Filtro dinâmico por exercício
- Gráfico (fl_chart) com:
	- peso máximo por sessão para o exercício filtrado
	- eixo X com datas formatadas (dd/MM)
	- sessões ordenadas da mais antiga para a mais nova no gráfico

## Injeção de Dependências

No ponto central da aplicação (TelaBase):

- uma instância única de TreinoRepository
- TreinoController e HistoricoController injetados com o mesmo repositório
- ProgressoController também injetado com o mesmo repositório

Com isso, treino, histórico e progresso compartilham a mesma fonte de dados.

## Estrutura de Pastas (resumo)

lib/

- controllers/
	- treino_controller.dart
	- historico_controller.dart
	- progresso_controller.dart
- database/
	- db_helper.dart
- models/
	- serie.dart
	- exercicio.dart
	- sessao_treino.dart
- repositories/
	- treino_repository.dart
- screens/
	- treino_screen.dart
	- historico_screen.dart
	- progresso_screen.dart
- widgets/
	- cronometro_widget.dart
	- serie_row_widget.dart
	- selecao_exercicio_modal.dart
	- config_tempo_descanso_modal.dart
	- historico_card_widget.dart
	- metricas_dashboard_widget.dart
	- progresso_grafico_widget.dart

## Como Rodar

Pré-requisitos:

- Flutter SDK instalado
- Android Studio/VS Code configurado

Comandos:

1. Instalar dependências

	 flutter pub get

2. Executar em debug

	 flutter run

3. Gerar APK release

	 flutter build apk

## Qualidade e Estado Atual

- Código com null-safety
- Base orientada a controllers + repository
- Build de APK funcionando
- Analyzer limpo nos principais módulos refatorados

## Próximos Passos Recomendados

- Criar testes unitários para controllers e repositório
- Evoluir de exercícios mockados para catálogo persistido no banco
- Versionar schema com migrações (upgrade de banco)
- Adicionar tratamento de erros com mensagens de domínio mais específicas

