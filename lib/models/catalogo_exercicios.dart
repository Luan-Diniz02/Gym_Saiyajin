/// Metadados enriquecidos e caminhos de mídia offline para exercícios do catálogo.
///
/// As miniaturas (180×180 `.jpg`) e animações (180×180 `.gif`) são provenientes do
/// dataset `hasaneyldrm/exercises-dataset` (© Gym visual — https://gymvisual.com/).
class InfoExercicioCatalogo {
  final String nome;
  final String grupo;
  final String codigoMidia;
  final String equipamento;
  final String musculoAlvo;
  final List<String> musculosSecundarios;
  final List<String> instrucoes;

  const InfoExercicioCatalogo({
    required this.nome,
    required this.grupo,
    required this.codigoMidia,
    required this.equipamento,
    required this.musculoAlvo,
    required this.musculosSecundarios,
    required this.instrucoes,
  });

  String get thumbAsset => 'assets/exercises/thumbs/$codigoMidia.jpg';
  String get gifAsset => 'assets/exercises/gifs/$codigoMidia.gif';
  static const String atribuicao = '© Gym visual — gymvisual.com';
}

class CatalogoExercicios {
  CatalogoExercicios._();

  static const List<InfoExercicioCatalogo> exerciciosPadrao = [
    // ==================== PEITO (10) ====================
    InfoExercicioCatalogo(
      nome: 'Supino Reto',
      grupo: 'PEITO',
      codigoMidia: '0025-EIeI8Vf',
      equipamento: 'Barra',
      musculoAlvo: 'Peitoral Maior',
      musculosSecundarios: ['Tríceps', 'Deltoide Anterior'],
      instrucoes: [
        'Deite-se no banco reto com os pés firmes no chão e escápulas retraídas.',
        'Segure a barra com pegada pouco mais larga que os ombros e desça de forma controlada até a linha média do peito.',
        'Empurre a barra explosivamente até estender os braços sem perder a estabilidade escapular.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Supino Inclinado',
      grupo: 'PEITO',
      codigoMidia: '0047-3TZduzM',
      equipamento: 'Barra',
      musculoAlvo: 'Peitoral Superior (Clavicular)',
      musculosSecundarios: ['Deltoide Anterior', 'Tríceps'],
      instrucoes: [
        'Ajuste o banco entre 30° e 45° e mantenha as escápulas firmes no encosto.',
        'Desça a barra sob controle em direção à parte alta do peitoral.',
        'Empurre verticalmente mantendo os cotovelos levemente projetados à frente (cerca de 45° do tronco).',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Supino Declinado',
      grupo: 'PEITO',
      codigoMidia: '0033-GrO65fd',
      equipamento: 'Barra',
      musculoAlvo: 'Peitoral Inferior',
      musculosSecundarios: ['Tríceps', 'Deltoide Anterior'],
      instrucoes: [
        'Prenda os pés no apoio do banco declinado e retraia as escápulas.',
        'Desça a barra controladamente até a porção inferior do esterno.',
        'Empurre de volta até a extensão sem travar bruscamente os cotovelos.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Crucifixo',
      grupo: 'PEITO',
      codigoMidia: '0308-yz9nUhF',
      equipamento: 'Halteres',
      musculoAlvo: 'Peitoral Maior',
      musculosSecundarios: ['Deltoide Anterior', 'Bíceps (Estabilização)'],
      instrucoes: [
        'Deitado no banco reto, segure os halteres acima do peito com as palmas voltadas uma para a outra e leve flexão nos cotovelos.',
        'Abra os braços em arco amplo até sentir o alongamento do peitoral na linha do tronco.',
        'Retorne pelo mesmo arco contraindo o peito no topo.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Crossover',
      grupo: 'PEITO',
      codigoMidia: '0188-xLYSdtg',
      equipamento: 'Polia / Cabo',
      musculoAlvo: 'Peitoral Maior',
      musculosSecundarios: ['Deltoide Anterior', 'Core'],
      instrucoes: [
        'Posicione-se no centro do crossover com um pé levemente à frente para estabilidade e tronco sutilmente inclinado.',
        'Com os cotovelos semi-flexionados, puxe os puxadores em arco até se encontrarem à frente do peito.',
        'Retorne devagar mantendo a tensão contínua dos cabos.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Voador',
      grupo: 'PEITO',
      codigoMidia: '0596-v3xmPAR',
      equipamento: 'Máquina (Pec Deck)',
      musculoAlvo: 'Peitoral Maior',
      musculosSecundarios: ['Deltoide Anterior'],
      instrucoes: [
        'Ajuste o assento para que as alças fiquem na linha média do peitoral e apoie bem as costas.',
        'Una os braços à frente espremendo o peitoral por 1 segundo no centro.',
        'Retorne de forma controlada sem deixar os pesos baterem.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Supino Reto Halteres',
      grupo: 'PEITO',
      codigoMidia: '0289-SpYC0Kp',
      equipamento: 'Halteres',
      musculoAlvo: 'Peitoral Maior',
      musculosSecundarios: ['Tríceps', 'Deltoide Anterior'],
      instrucoes: [
        'Deite-se no banco reto segurando os halteres ao lado do peito com os pés firmes no chão.',
        'Empurre os halteres para cima convergindo suavemente no topo sem bater um no outro.',
        'Desça controladamente aproveitando a maior amplitude articular dos halteres.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Supino Inclinado Halteres',
      grupo: 'PEITO',
      codigoMidia: '0314-ns0SIbU',
      equipamento: 'Halteres',
      musculoAlvo: 'Peitoral Superior (Clavicular)',
      musculosSecundarios: ['Deltoide Anterior', 'Tríceps'],
      instrucoes: [
        'Com o banco inclinado a 30°–45°, posicione os halteres na linha dos ombros.',
        'Empurre para cima mantendo os punhos firmes e cotovelos a ~45° do tronco.',
        'Desça até alongar bem a porção clavicular do peito.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Supino Máquina',
      grupo: 'PEITO',
      codigoMidia: '0577-T0yTjgW',
      equipamento: 'Máquina Articulada',
      musculoAlvo: 'Peitoral Maior',
      musculosSecundarios: ['Tríceps', 'Deltoide Anterior'],
      instrucoes: [
        'Ajuste a altura do banco para que as manoplas fiquem alinhadas ao meio do peito.',
        'Empurre as alças à frente mantendo as escápulas coladas no encosto.',
        'Retorne controlando a fase excêntrica.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Flexão de Braços',
      grupo: 'PEITO',
      codigoMidia: '0662-I4hDWkc',
      equipamento: 'Peso Corporal',
      musculoAlvo: 'Peitoral Maior',
      musculosSecundarios: ['Tríceps', 'Deltoide Anterior', 'Core'],
      instrucoes: [
        'Apoie as mãos no solo um pouco além da largura dos ombros, mantendo o corpo reto em prancha.',
        'Desça o tronco flexionando os cotovelos até o peito chegar próximo ao chão.',
        'Empurre o solo de volta até estender os braços mantendo o abdômen contraído.',
      ],
    ),

    // ==================== COSTAS (8) ====================
    InfoExercicioCatalogo(
      nome: 'Puxada Alta',
      grupo: 'COSTAS',
      codigoMidia: '0197-qdRxqCj',
      equipamento: 'Polia Alta (Barra)',
      musculoAlvo: 'Latíssimo do Dorso (Dorsal)',
      musculosSecundarios: ['Bíceps', 'Redondo Maior', 'Romboides'],
      instrucoes: [
        'Ajuste a altura do assento e prenda as coxas sob o apoio acolchoado, segurando a barra com pegada aberta pronada.',
        'Incline sutilmente o tronco para trás, estufe o peito e puxe a barra em direção à parte superior do peitoral.',
        'Pause brevemente contraindo as escápulas e retorne devagar até alongar os dorsais.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Remada Curvada',
      grupo: 'COSTAS',
      codigoMidia: '0027-eZyBC3j',
      equipamento: 'Barra',
      musculoAlvo: 'Costas Superiores & Dorsal',
      musculosSecundarios: ['Trapézio', 'Romboides', 'Bíceps', 'Lombar'],
      instrucoes: [
        'Incline o tronco à frente mantendo a coluna neutra, joelhos semi-flexionados e core travado.',
        'Puxe a barra em direção ao abdômen aproximando as escápulas no topo.',
        'Desça a barra sob controle sem arredondar a região lombar.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Remada Baixa',
      grupo: 'COSTAS',
      codigoMidia: '0861-fUBheHs',
      equipamento: 'Polia Baixa',
      musculoAlvo: 'Meio das Costas & Dorsal',
      musculosSecundarios: ['Romboides', 'Trapézio Médio', 'Bíceps'],
      instrucoes: [
        'Sente-se com os pés apoiados na plataforma, joelhos levemente flexionados e coluna ereta.',
        'Puxe o triângulo em direção ao abdômen estufando o peito e unindo as escápulas.',
        'Estenda os braços à frente controladamente sem jogar o tronco para trás no impulso.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Serrote',
      grupo: 'COSTAS',
      codigoMidia: '0292-C0MA9bC',
      equipamento: 'Halter',
      musculoAlvo: 'Latíssimo do Dorso & Costas Superiores',
      musculosSecundarios: ['Bíceps', 'Deltoide Posterior', 'Romboides'],
      instrucoes: [
        'Apoie um joelho e a mão do mesmo lado no banco, mantendo as costas retas e paralelas ao chão.',
        'Puxe o halter em direção à linha do quadril, conduzindo o movimento pelo cotovelo.',
        'Desça alongando bem a escápula antes da próxima repetição.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Barra Fixa',
      grupo: 'COSTAS',
      codigoMidia: '0652-lBDjFxJ',
      equipamento: 'Peso Corporal',
      musculoAlvo: 'Latíssimo do Dorso (Dorsal)',
      musculosSecundarios: ['Bíceps', 'Antebraço', 'Core'],
      instrucoes: [
        'Segure a barra fixa com pegada pronada um pouco mais larga que os ombros.',
        'Traga o peito em direção à barra deprimindo os ombros e contraindo as costas.',
        'Desça de forma controlada até a extensão completa dos braços.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Pulldown Polia',
      grupo: 'COSTAS',
      codigoMidia: '0238-x69MAlq',
      equipamento: 'Polia Alta',
      musculoAlvo: 'Latíssimo do Dorso (Dorsal)',
      musculosSecundarios: ['Redondo Maior', 'Cabeça Longa do Tríceps'],
      instrucoes: [
        'Em pé diante da polia alta, incline levemente o tronco e mantenha os cotovelos quase totalmente estendidos.',
        'Puxe a barra ou corda em arco até a altura das coxas contraindo exclusivamente os dorsais.',
        'Suba devagar sentindo a expansão da caixa torácica e dorsal.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Remada Cavalinho',
      grupo: 'COSTAS',
      codigoMidia: '1349-BgljGjd',
      equipamento: 'Máquina / Barra T',
      musculoAlvo: 'Espessura Dorsal & Romboides',
      musculosSecundarios: ['Trapézio', 'Bíceps', 'Deltoide Posterior'],
      instrucoes: [
        'Posicione os pés na base e mantenha a coluna neutra (ou o peito apoiado, se houver suporte).',
        'Puxe a carga trazendo os cotovelos para trás e espremendo o meio das costas.',
        'Desça controladamente aproveitando o alongamento escapular.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Puxada Triângulo',
      grupo: 'COSTAS',
      codigoMidia: '2616-4c9BhzB',
      equipamento: 'Polia Alta (Triângulo)',
      musculoAlvo: 'Latíssimo do Dorso (Porção Inferior)',
      musculosSecundarios: ['Bíceps', 'Braquial', 'Romboides'],
      instrucoes: [
        'Segure o puxador triângulo (V-Bar) na polia alta com pegada neutra e fixe as coxas sob o apoio.',
        'Incline sutilmente o tronco para trás, estufe o peito e puxe o triângulo até a parte alta do peitoral mantendo os cotovelos próximos ao corpo.',
        'Retorne devagar controlando o peso até alongar completamente os dorsais.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Remada Máquina',
      grupo: 'COSTAS',
      codigoMidia: '0588-IGjKj1v',
      equipamento: 'Máquina Articulada (Pegada Neutra)',
      musculoAlvo: 'Costas Superiores & Dorsal',
      musculosSecundarios: ['Romboides', 'Trapézio Médio', 'Bíceps', 'Antebraço'],
      instrucoes: [
        'Ajuste a altura do banco e apoie o peito firmemente contra o suporte acolchoado da máquina.',
        'Segure as manoplas com pegada neutra (fechada) e puxe os cotovelos para trás espremendo as escápulas.',
        'Pause brevemente na contração máxima e retorne devagar mantendo o peito colado ao apoio.',
      ],
    ),

    // ==================== PERNAS (15) ====================
    InfoExercicioCatalogo(
      nome: 'Agachamento Livre',
      grupo: 'PERNAS',
      codigoMidia: '0043-qXTaZnJ',
      equipamento: 'Barra',
      musculoAlvo: 'Quadríceps & Glúteos',
      musculosSecundarios: ['Isquiotibiais', 'Panturrilhas', 'Core / Lombar'],
      instrucoes: [
        'Apoie a barra sobre o trapézio, afaste os pés na largura dos ombros e trave o abdômen.',
        'Desça flexionando quadril e joelhos alinhados com a ponta dos pés até romper a linha paralela.',
        'Empurre o chão com toda a planta do pé para retornar à posição inicial.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Levantamento Terra',
      grupo: 'PERNAS',
      codigoMidia: '0032-ila4NZS',
      equipamento: 'Barra',
      musculoAlvo: 'Glúteos & Cadeia Posterior',
      musculosSecundarios: ['Isquiotibiais', 'Quadríceps', 'Lombar', 'Trapézio', 'Antebraço'],
      instrucoes: [
        'Posicione os pés sob o meio da barra, flexione o quadril e segure a barra por fora das pernas.',
        'Trave o abdômen, mantenha a coluna neutra e empurre o chão com os pés mantendo a barra colada às canelas.',
        'Estenda o quadril e os joelhos simultaneamente até ficar totalmente ereto.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Leg Press 45',
      grupo: 'PERNAS',
      codigoMidia: '0739-10Z2DXU',
      equipamento: 'Máquina (45°)',
      musculoAlvo: 'Quadríceps & Glúteos',
      musculosSecundarios: ['Isquiotibiais', 'Panturrilhas'],
      instrucoes: [
        'Apoie totalmente a lombar e o quadril no encosto e posicione os pés na plataforma na largura dos ombros.',
        'Destrave a máquina e desça a plataforma até os joelhos formarem cerca de 90°, sem tirar o quadril do banco.',
        'Empurre a plataforma sem travar completamente a articulação dos joelhos no topo.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Cadeira Extensora',
      grupo: 'PERNAS',
      codigoMidia: '0585-my33uHU',
      equipamento: 'Máquina',
      musculoAlvo: 'Quadríceps',
      musculosSecundarios: [],
      instrucoes: [
        'Ajuste o encosto para que a dobra do joelho fique alinhada ao eixo de rotação da máquina e o rolo sobre o tornozelo.',
        'Estenda totalmente os joelhos contraindo o quadríceps por 1 segundo no topo.',
        'Desça de forma controlada sem soltar o peso.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Cadeira Flexora',
      grupo: 'PERNAS',
      codigoMidia: '0599-Zg3XY7P',
      equipamento: 'Máquina',
      musculoAlvo: 'Posterior de Coxa (Isquiotibiais)',
      musculosSecundarios: ['Panturrilhas (Gastrocnêmio)'],
      instrucoes: [
        'Ajuste o encosto, apoie os tornozelos sobre o rolo inferior e trave a almofada superior sobre as coxas.',
        'Flexione os joelhos puxando o rolo o máximo possível para baixo do assento.',
        'Retorne devagar mantendo o quadril colado no encosto.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Mesa Flexora',
      grupo: 'PERNAS',
      codigoMidia: '0586-17lJ1kr',
      equipamento: 'Máquina',
      musculoAlvo: 'Posterior de Coxa (Isquiotibiais)',
      musculosSecundarios: ['Panturrilhas', 'Glúteos'],
      instrucoes: [
        'Deite-se de bruços no aparelho com os joelhos alinhados ao eixo da máquina e o rolo logo acima do calcanhar.',
        'Flexione as pernas em direção aos glúteos mantendo o quadril pressionado contra o banco.',
        'Desça controlando a fase negativa até quase estender totalmente.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Panturrilha Máquina',
      grupo: 'PERNAS',
      codigoMidia: '0605-ykUOVze',
      equipamento: 'Máquina em Pé',
      musculoAlvo: 'Panturrilhas (Gastrocnêmio)',
      musculosSecundarios: ['Sóleo'],
      instrucoes: [
        'Apoie os ombros sob as almofadas e a ponta dos pés na plataforma com os joelhos estendidos.',
        'Desça os calcanhares o máximo possível para alongar a panturrilha.',
        'Suba na ponta dos pés até a contração máxima e segure por 1 segundo.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Elevação Pélvica',
      grupo: 'PERNAS',
      codigoMidia: '1409-qKBpF7I',
      equipamento: 'Barra',
      musculoAlvo: 'Glúteo Máximo',
      musculosSecundarios: ['Isquiotibiais', 'Core'],
      instrucoes: [
        'Posicione a barra acolchoada sobre a linha do quadril e mantenha os pés afastados na largura dos ombros.',
        'Eleve o quadril empurrando pelos calcanhares até o tronco ficar paralelo ao solo, contraindo forte os glúteos.',
        'Desça controladamente sem hiperestender a lombar.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Stiff',
      grupo: 'PERNAS',
      codigoMidia: '0085-wQ2c4XD',
      equipamento: 'Barra',
      musculoAlvo: 'Posterior de Coxa & Glúteos',
      musculosSecundarios: ['Eretores da Espinha (Lombar)', 'Antebraço'],
      instrucoes: [
        'Em pé com a barra nas mãos, mantenha os joelhos apenas destravados (semi-flexionados) e a coluna reta.',
        'Projete o quadril para trás deslizando a barra próxima às coxas e canelas até sentir forte alongamento no posterior.',
        'Retorne estendendo o quadril e contraindo glúteos e posteriores.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Afundo Halteres',
      grupo: 'PERNAS',
      codigoMidia: '0336-RRWFUcw',
      equipamento: 'Halteres',
      musculoAlvo: 'Quadríceps & Glúteos',
      musculosSecundarios: ['Isquiotibiais', 'Panturrilhas', 'Core'],
      instrucoes: [
        'Segure um halter em cada mão ao lado do corpo e dê um passo firme à frente.',
        'Desça o quadril flexionando ambos os joelhos até formarem cerca de 90°.',
        'Empurre o solo com o calcanhar da perna da frente para retornar.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Agachamento Búlgaro',
      grupo: 'PERNAS',
      codigoMidia: '0410-qx4fgX7',
      equipamento: 'Halteres',
      musculoAlvo: 'Quadríceps & Glúteo Máximo',
      musculosSecundarios: ['Isquiotibiais', 'Adutores', 'Core'],
      instrucoes: [
        'Apoie o peito do pé de trás sobre um banco e dê um passo à frente com a perna de trabalho.',
        'Desça verticalmente flexionando o joelho da frente até a coxa ficar paralela ao solo.',
        'Empurre com força pelo pé da frente mantendo o equilíbrio e o tronco firme.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Agachamento Hack',
      grupo: 'PERNAS',
      codigoMidia: '0743-Qa55kX1',
      equipamento: 'Máquina Hack',
      musculoAlvo: 'Quadríceps & Glúteos',
      musculosSecundarios: ['Isquiotibiais', 'Panturrilhas'],
      instrucoes: [
        'Encoste totalmente as costas e ombros no suporte da máquina Hack e posicione os pés na plataforma.',
        'Destrave o aparelho e desça controladamente até atingir boa amplitude de flexão dos joelhos.',
        'Empurre a carga de volta mantendo a lombar sempre apoiada.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Cadeira Abdutora',
      grupo: 'PERNAS',
      codigoMidia: '0597-CHpahtl',
      equipamento: 'Máquina',
      musculoAlvo: 'Glúteo Médio & Abdutores',
      musculosSecundarios: ['Glúteo Mínimo', 'Tensor da Fáscia Lata'],
      instrucoes: [
        'Sente-se no aparelho com a parte externa das coxas apoiada nas almofadas.',
        'Afaste as pernas para fora contraindo a lateral dos glúteos no ponto máximo.',
        'Retorne devagar resistindo ao peso.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Cadeira Adutora',
      grupo: 'PERNAS',
      codigoMidia: '0598-oHsrypV',
      equipamento: 'Máquina',
      musculoAlvo: 'Adutores (Parte Interna da Coxa)',
      musculosSecundarios: [],
      instrucoes: [
        'Sente-se com a parte interna das coxas apoiada nas almofadas e ajuste a amplitude inicial.',
        'Feche as pernas contraindo a musculatura interna das coxas.',
        'Retorne de forma controlada sem soltar a carga bruscamente.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Panturrilha Sentado',
      grupo: 'PERNAS',
      codigoMidia: '0594-bOOdeyc',
      equipamento: 'Máquina Sentado',
      musculoAlvo: 'Panturrilhas (Sóleo)',
      musculosSecundarios: ['Gastrocnêmio'],
      instrucoes: [
        'Sente-se no aparelho posicionando a ponta dos pés na plataforma e o apoio acolchoado sobre a parte inferior das coxas.',
        'Desça os calcanhares alongando bem o tendão e o músculo sóleo.',
        'Eleve os calcanhares ao máximo e sustente brevemente no topo.',
      ],
    ),

    // ==================== OMBROS (9) ====================
    InfoExercicioCatalogo(
      nome: 'Desenvolvimento Halteres',
      grupo: 'OMBROS',
      codigoMidia: '0405-znQUdHY',
      equipamento: 'Halteres',
      musculoAlvo: 'Deltoide Anterior & Lateral',
      musculosSecundarios: ['Tríceps', 'Trapézio Superior'],
      instrucoes: [
        'Sentado em um banco com encosto vertical, segure os halteres na altura das orelhas.',
        'Empurre os halteres acima da cabeça até quase estender os cotovelos.',
        'Desça de forma controlada mantendo os cotovelos levemente projetados à frente do plano do tronco.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Elevação Lateral',
      grupo: 'OMBROS',
      codigoMidia: '0334-DsgkuIt',
      equipamento: 'Halteres',
      musculoAlvo: 'Deltoide Lateral',
      musculosSecundarios: ['Trapézio Superior'],
      instrucoes: [
        'Em pé com os cotovelos sutilmente flexionados, segure os halteres ao lado do corpo.',
        'Eleve os braços lateralmente até a linha dos ombros conduzindo o movimento pelos cotovelos.',
        'Desça lentamente sem balançar o tronco.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Elevação Frontal',
      grupo: 'OMBROS',
      codigoMidia: '0310-3eGE2JC',
      equipamento: 'Halteres',
      musculoAlvo: 'Deltoide Anterior',
      musculosSecundarios: ['Peitoral Superior', 'Trapézio'],
      instrucoes: [
        'Em pé, segure os halteres à frente das coxas com as palmas voltadas para o corpo.',
        'Eleve os braços à frente até a altura dos olhos mantendo o tronco estável.',
        'Desça sob controle resistindo à gravidade.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Desenvolvimento Militar',
      grupo: 'OMBROS',
      codigoMidia: '0091-kTbSH9h',
      equipamento: 'Barra',
      musculoAlvo: 'Deltoide Anterior & Lateral',
      musculosSecundarios: ['Tríceps', 'Core', 'Trapézio'],
      instrucoes: [
        'Segure a barra na altura da parte superior do peito com pegada pouco além da largura dos ombros.',
        'Empurre a barra verticalmente acima da cabeça mantendo o abdômen e glúteos contraídos.',
        'Desça a barra controladamente até a linha da clavícula.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Desenvolvimento Máquina',
      grupo: 'OMBROS',
      codigoMidia: '2318-dNFYIU1',
      equipamento: 'Máquina Articulada',
      musculoAlvo: 'Deltoides',
      musculosSecundarios: ['Tríceps', 'Peitoral Superior'],
      instrucoes: [
        'Ajuste o banco para que as manoplas fiquem na altura dos ombros e apoie bem as costas.',
        'Empurre as alças para cima até quase estender totalmente os braços.',
        'Retorne devagar controlando a descida.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Crucifixo Inverso',
      grupo: 'OMBROS',
      codigoMidia: '2292-mu5Guxt',
      equipamento: 'Halteres',
      musculoAlvo: 'Deltoide Posterior',
      musculosSecundarios: ['Romboides', 'Trapézio Médio'],
      instrucoes: [
        'Incline o tronco à frente mantendo a coluna reta e deixe os halteres suspensos abaixo do peito.',
        'Abra os braços lateralmente focando na parte posterior dos ombros.',
        'Desça de forma controlada mantendo a postura do tronco.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Voador Invertido',
      grupo: 'OMBROS',
      codigoMidia: '0602-myfUsKf',
      equipamento: 'Máquina (Pec Deck Inverso)',
      musculoAlvo: 'Deltoide Posterior & Costas Superiores',
      musculosSecundarios: ['Romboides', 'Trapézio Médio'],
      instrucoes: [
        'Sente-se de frente para o encosto da máquina Pec Deck com o peito apoiado e segure as alças na linha dos ombros.',
        'Abra os braços para trás mantendo leve flexão nos cotovelos e contraindo o posterior de ombro e escápulas.',
        'Retorne controladamente à posição inicial.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Face Pull',
      grupo: 'OMBROS',
      codigoMidia: '0203-wqNPGCg',
      equipamento: 'Polia Alta (Corda)',
      musculoAlvo: 'Deltoide Posterior & Manguito Rotador',
      musculosSecundarios: ['Trapézio Médio', 'Romboides'],
      instrucoes: [
        'Ajuste a polia na altura do rosto usando a corda com pegada neutra.',
        'Puxe o centro da corda em direção à testa abrindo os cotovelos e fazendo rotação externa dos ombros.',
        'Segure 1 segundo na contração máxima e retorne devagar.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Encolhimento Halteres',
      grupo: 'OMBROS',
      codigoMidia: '0406-NJzBsGJ',
      equipamento: 'Halteres',
      musculoAlvo: 'Trapézio Superior',
      musculosSecundarios: ['Antebraço (Pegada)'],
      instrucoes: [
        'Em pé, segure um halter pesado em cada mão ao lado das coxas com os braços estendidos.',
        'Eleve os ombros verticalmente em direção às orelhas sem dobrar os cotovelos.',
        'Segure 1 segundo no topo e desça alongando o trapézio.',
      ],
    ),

    // ==================== BÍCEPS (8) ====================
    InfoExercicioCatalogo(
      nome: 'Rosca Direta',
      grupo: 'BÍCEPS',
      codigoMidia: '0031-25GPyDY',
      equipamento: 'Barra',
      musculoAlvo: 'Bíceps Braquial',
      musculosSecundarios: ['Braquial', 'Antebraço'],
      instrucoes: [
        'Em pé, segure a barra com pegada supinada na largura dos ombros e cole os cotovelos ao lado do tronco.',
        'Flexione os cotovelos levando a barra até a altura do peito sem jogar o corpo para trás.',
        'Desça controladamente até estender totalmente os braços.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Rosca Martelo',
      grupo: 'BÍCEPS',
      codigoMidia: '0313-slDvUAU',
      equipamento: 'Halteres',
      musculoAlvo: 'Braquial & Braquiorradial',
      musculosSecundarios: ['Bíceps Braquial'],
      instrucoes: [
        'Segure os halteres com pegada neutra (palmas voltadas uma para a outra, como se segurasse um martelo).',
        'Suba os halteres mantendo os punhos neutros e os cotovelos fixos ao lado das costelas.',
        'Desça devagar controlando a fase excêntrica.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Rosca Martelo Polia',
      grupo: 'BÍCEPS',
      codigoMidia: '0165-HPlPoQA',
      equipamento: 'Polia Baixa (Corda)',
      musculoAlvo: 'Braquial & Braquiorradial',
      musculosSecundarios: ['Bíceps Braquial'],
      instrucoes: [
        'Em pé diante da polia baixa, segure a corda com pegada neutra (palmas frente a frente) e cotovelos colados ao tronco.',
        'Suba a corda contraindo o bíceps e antebraço até a linha dos ombros.',
        'Desça lentamente mantendo a tensão constante do cabo.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Rosca Alternada',
      grupo: 'BÍCEPS',
      codigoMidia: '0285-BU15nH4',
      equipamento: 'Halteres',
      musculoAlvo: 'Bíceps Braquial',
      musculosSecundarios: ['Braquial', 'Antebraço'],
      instrucoes: [
        'Segure um halter em cada mão e mantenha a postura ereta.',
        'Suba um braço de cada vez girando a palma da mão para cima (supinação) durante a subida.',
        'Contraia o bíceps no topo e desça antes de iniciar o outro lado.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Rosca Scott',
      grupo: 'BÍCEPS',
      codigoMidia: '0070-qOgPVf6',
      equipamento: 'Barra / Banco Scott',
      musculoAlvo: 'Bíceps (Cabeça Curta / Pico)',
      musculosSecundarios: ['Braquial', 'Antebraço'],
      instrucoes: [
        'Apoie toda a parte posterior dos braços sobre a almofada inclinada do banco Scott.',
        'Suba a barra contraindo os bíceps sem desencostar os cotovelos do apoio.',
        'Desça lentamente alongando bem o bíceps na base.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Rosca Scott Unilateral',
      grupo: 'BÍCEPS',
      codigoMidia: '0402-7D5bgLT',
      equipamento: 'Halter / Banco Scott',
      musculoAlvo: 'Bíceps (Isolamento Unilateral)',
      musculosSecundarios: ['Braquial', 'Antebraço'],
      instrucoes: [
        'Sente-se no banco Scott e apoie um braço de cada vez sobre a almofada segurando o halter com pegada supinada.',
        'Flexione o cotovelo trazendo o halter até o ombro sem tirar o tríceps do apoio.',
        'Desça devagar até quase estender totalmente o braço e repita com o outro lado.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Rosca Inclinada',
      grupo: 'BÍCEPS',
      codigoMidia: '0315-F3xgbjF',
      equipamento: 'Halteres',
      musculoAlvo: 'Bíceps (Cabeça Longa)',
      musculosSecundarios: ['Braquial', 'Antebraço'],
      instrucoes: [
        'Deite-se em um banco inclinado a ~45°–60° deixando os braços pendurados para trás da linha do tronco.',
        'Flexione os cotovelos mantendo os ombros parados para isolar a cabeça longa do bíceps.',
        'Desça até o alongamento completo na base.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Rosca Polia Baixa',
      grupo: 'BÍCEPS',
      codigoMidia: '0868-G08RZcQ',
      equipamento: 'Polia Baixa',
      musculoAlvo: 'Bíceps Braquial',
      musculosSecundarios: ['Braquial', 'Antebraço'],
      instrucoes: [
        'Em pé diante da polia baixa, segure a barra reta ou W com pegada supinada.',
        'Mantenha os cotovelos colados ao tronco e suba a barra aproveitando a tensão contínua do cabo.',
        'Retorne devagar sem deixar os pesos baterem.',
      ],
    ),

    // ==================== TRÍCEPS (6) ====================
    InfoExercicioCatalogo(
      nome: 'Tríceps Polia',
      grupo: 'TRÍCEPS',
      codigoMidia: '0201-3ZflifB',
      equipamento: 'Polia Alta (Barra)',
      musculoAlvo: 'Tríceps Braquial (Cabeça Lateral)',
      musculosSecundarios: ['Ancôneo'],
      instrucoes: [
        'Em pé diante da polia alta, segure a barra com pegada pronada e fixe os cotovelos ao lado do corpo.',
        'Empurre a barra para baixo até estender completamente os cotovelos.',
        'Suba controladamente apenas até o antebraço passar pouco acima de 90° sem mover os ombros.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Tríceps Testa',
      grupo: 'TRÍCEPS',
      codigoMidia: '0060-h8LFzo9',
      equipamento: 'Barra',
      musculoAlvo: 'Tríceps Braquial (Todas as Cabeças)',
      musculosSecundarios: ['Antebraço'],
      instrucoes: [
        'Deitado no banco reto, sustente a barra acima do peito com os cotovelos apontados para o teto.',
        'Flexione apenas os cotovelos descendo a barra em direção à testa ou levemente atrás da cabeça.',
        'Estenda os cotovelos de volta mantendo os braços fixos.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Tríceps Francês',
      grupo: 'TRÍCEPS',
      codigoMidia: '2188-kont8Ut',
      equipamento: 'Halter',
      musculoAlvo: 'Tríceps (Cabeça Longa)',
      musculosSecundarios: ['Core (Estabilização)'],
      instrucoes: [
        'Sentado ou em pé, segure o halter acima da cabeça com ambas as mãos e cotovelos apontados para cima.',
        'Desça o halter atrás da cabeça flexionando os cotovelos até alongar profundamente o tríceps.',
        'Empurre o halter de volta até estender os braços no topo.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Tríceps Corda',
      grupo: 'TRÍCEPS',
      codigoMidia: '0200-dU605di',
      equipamento: 'Polia Alta (Corda)',
      musculoAlvo: 'Tríceps Braquial',
      musculosSecundarios: ['Ancôneo'],
      instrucoes: [
        'Segure a corda na polia alta mantendo os cotovelos travados ao lado das costelas.',
        'Estenda os braços para baixo abrindo as pontas da corda no final do movimento para máxima contração.',
        'Retorne sob controle sem projetar os cotovelos para frente.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Tríceps Coice',
      grupo: 'TRÍCEPS',
      codigoMidia: '0333-W6PxUkg',
      equipamento: 'Halteres',
      musculoAlvo: 'Tríceps Braquial',
      musculosSecundarios: ['Deltoide Posterior (Estabilização)'],
      instrucoes: [
        'Incline o tronco à frente e eleve o braço até que fique paralelo ao chão, colado ao tronco.',
        'Estenda o antebraço para trás até alinhar todo o braço e contraia o tríceps no topo.',
        'Retorne devagar dobrando apenas o cotovelo.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Mergulho Paralelas',
      grupo: 'TRÍCEPS',
      codigoMidia: '0814-X6C6i5Y',
      equipamento: 'Barras Paralelas',
      musculoAlvo: 'Tríceps & Peitoral Inferior',
      musculosSecundarios: ['Deltoide Anterior'],
      instrucoes: [
        'Sustente o corpo nas barras paralelas mantendo o tronco o mais vertical possível para focar no tríceps.',
        'Desça flexionando os cotovelos até os braços formarem 90°.',
        'Empurre com força até estender novamente os braços no topo.',
      ],
    ),

    // ==================== ABDÔMEN (5) ====================
    InfoExercicioCatalogo(
      nome: 'Abdominal Supra',
      grupo: 'ABDÔMEN',
      codigoMidia: '0274-TFqbd8t',
      equipamento: 'Peso Corporal',
      musculoAlvo: 'Reto Abdominal (Superior)',
      musculosSecundarios: ['Oblíquos'],
      instrucoes: [
        'Deite-se de costas no colchonete com os joelhos flexionados e pés apoiados no chão.',
        'Enrole a parte superior do tronco tirando as escápulas do solo enquanto solta o ar e contrai o abdômen.',
        'Desça devagar mantendo a tensão abdominal.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Prancha',
      grupo: 'ABDÔMEN',
      codigoMidia: '2135-VBAWRPG',
      equipamento: 'Peso Corporal / Anilha',
      musculoAlvo: 'Core & Reto Abdominal',
      musculosSecundarios: ['Transverso Abdominal', 'Ombros', 'Lombar'],
      instrucoes: [
        'Apoie os antebraços e as pontas dos pés no solo, alinhando cabeça, coluna e quadril em linha reta.',
        'Contraia fortemente o abdômen e os glúteos, evitando deixar o quadril cair ou subir demais.',
        'Mantenha a isometria controlada pelo tempo ou carga estipulada.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Abdominal Infra',
      grupo: 'ABDÔMEN',
      codigoMidia: '0620-WhuFnR7',
      equipamento: 'Banco / Solo',
      musculoAlvo: 'Reto Abdominal (Inferior)',
      musculosSecundarios: ['Flexores do Quadril'],
      instrucoes: [
        'Deite-se de costas em um banco ou no solo segurando um apoio firme atrás da cabeça.',
        'Eleve as pernas unidas enrolando levemente a pelve no topo para acionar a porção inferior do abdômen.',
        'Desça as pernas devagar sem arquear a lombar.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Elevação de Pernas Barra',
      grupo: 'ABDÔMEN',
      codigoMidia: '0472-I3tsCnC',
      equipamento: 'Barra Fixa',
      musculoAlvo: 'Reto Abdominal & Core',
      musculosSecundarios: ['Flexores do Quadril', 'Antebraço'],
      instrucoes: [
        'Pendure-se na barra fixa com o corpo estabilizado sem balançar.',
        'Eleve as pernas à frente enrolando o quadril para cima e contraindo forte o abdômen.',
        'Desça controlando o movimento para evitar impulso.',
      ],
    ),
    InfoExercicioCatalogo(
      nome: 'Abdominal Polia',
      grupo: 'ABDÔMEN',
      codigoMidia: '0175-WW95auq',
      equipamento: 'Polia Alta (Corda)',
      musculoAlvo: 'Reto Abdominal',
      musculosSecundarios: ['Oblíquos'],
      instrucoes: [
        'Ajoelhe-se diante da polia alta segurando a corda ao lado da cabeça.',
        'Flexione a coluna vertebral aproximando as costelas da pelve (sem sentar nos calcanhares).',
        'Retorne devagar alongando o abdômen contra a resistência do cabo.',
      ],
    ),
  ];

  static String _normalizarChave(String texto) {
    return texto
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[()\[\]\-/_,.;:]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Sinônimos e nomes legados que apontam diretamente para a chave normalizada do catálogo.
  static const Map<String, String> _aliasesNormalizados = {
    'puxada frontal': 'puxada alta',
    'puxada frente': 'puxada alta',
    'puxada aberta': 'puxada alta',
    'puxada alta aberta': 'puxada alta',
    'puxada alta frente': 'puxada alta',
    'rosca direta polia': 'rosca polia baixa',
    'rosca direta na polia': 'rosca polia baixa',
    'rosca polia': 'rosca polia baixa',
    'rosca martelo na polia': 'rosca martelo polia',
    'rosca martelo corda': 'rosca martelo polia',
    'crucifixo inverso maquina': 'voador invertido',
    'peck deck invertido': 'voador invertido',
    'pec deck invertido': 'voador invertido',
    'peck deck': 'voador',
    'pec deck': 'voador',
    'supino reto com halteres': 'supino reto halteres',
    'supino inclinado com halteres': 'supino inclinado halteres',
    'remada unilateral': 'serrote',
    'remada unilateral halter': 'serrote',
    'remada unilateral halteres': 'serrote',
    'remada articulada': 'remada maquina',
    'remada fechada maquina': 'remada maquina',
    'remada sentado maquina': 'remada maquina',
    'remada na maquina': 'remada maquina',
  };

  static final Map<String, InfoExercicioCatalogo> _mapaNormalizado = {
    for (final item in exerciciosPadrao) _normalizarChave(item.nome): item,
  };

  /// Busca os metadados e mídia de um exercício pelo nome (com tolerância a acentos, parênteses e sinônimos).
  static InfoExercicioCatalogo? buscarPorNome(String nome) {
    final chave = _normalizarChave(nome);
    if (chave.isEmpty) return null;

    final exato = _mapaNormalizado[chave];
    if (exato != null) return exato;

    final aliasAlvo = _aliasesNormalizados[chave];
    if (aliasAlvo != null) {
      return _mapaNormalizado[aliasAlvo];
    }

    return null;
  }

  /// Lista no formato [{'nome': ..., 'grupo': ...}] compatível com SelecaoExercicioModal.
  static List<Map<String, String>> get listaPadraoMap => exerciciosPadrao
      .map((e) => {'nome': e.nome, 'grupo': e.grupo})
      .toList();
}
