import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/models/catalogo_exercicios.dart';
import 'package:gym_saiyajin/widgets/exercicio_midia_widget.dart';

void main() {
  group('CatalogoExercicios - Integridade do Catálogo Offline e Assets', () {
    test('Deve conter 92 exercícios padrão com todos os metadados preenchidos', () {
      expect(CatalogoExercicios.exerciciosPadrao.length, equals(92));

      for (final ex in CatalogoExercicios.exerciciosPadrao) {
        expect(ex.nome.isNotEmpty, isTrue, reason: 'Nome vazio');
        expect(ex.grupo.isNotEmpty, isTrue, reason: 'Grupo vazio em ${ex.nome}');
        expect(ex.equipamento.isNotEmpty, isTrue, reason: 'Equipamento vazio em ${ex.nome}');
        expect(ex.musculoAlvo.isNotEmpty, isTrue, reason: 'Músculo alvo vazio em ${ex.nome}');
        expect(ex.instrucoes.isNotEmpty, isTrue, reason: 'Instruções vazias em ${ex.nome}');
      }
    });

    test('Puxada Alta deve usar 0197-qdRxqCj e Levantamento Terra deve estar em PERNAS', () {
      final puxadaAlta = CatalogoExercicios.buscarPorNome('Puxada Alta');
      expect(puxadaAlta, isNotNull);
      expect(puxadaAlta!.codigoMidia, equals('0197-qdRxqCj'));
      expect(puxadaAlta.grupo, equals('COSTAS'));

      final terra = CatalogoExercicios.buscarPorNome('Levantamento Terra');
      expect(terra, isNotNull);
      expect(terra!.grupo, equals('PERNAS'));
    });

    test('Todos os arquivos .jpg e .gif referenciados devem existir localmente em assets/exercises/', () {
      for (final ex in CatalogoExercicios.exerciciosPadrao) {
        final thumbFile = File(ex.thumbAsset);
        final gifFile = File(ex.gifAsset);

        expect(
          thumbFile.existsSync(),
          isTrue,
          reason: 'Miniatura ausente para ${ex.nome}: ${ex.thumbAsset}',
        );
        expect(
          thumbFile.lengthSync(),
          greaterThan(100),
          reason: 'Miniatura vazia/corrompida para ${ex.nome}',
        );

        expect(
          gifFile.existsSync(),
          isTrue,
          reason: 'GIF ausente para ${ex.nome}: ${ex.gifAsset}',
        );
        expect(
          gifFile.lengthSync(),
          greaterThan(100),
          reason: 'GIF vazio/corrompido para ${ex.nome}',
        );
      }
    });

    test('buscarPorNome deve normalizar parênteses, acentos e sinônimos sem falsos positivos de prefixo', () {
      expect(CatalogoExercicios.buscarPorNome('Supino Reto')?.codigoMidia, equals('0025-EIeI8Vf'));
      expect(CatalogoExercicios.buscarPorNome('Supino Inclinado (Halteres)')?.nome, equals('Supino Inclinado Halteres'));
      expect(CatalogoExercicios.buscarPorNome('Puxada Frontal')?.nome, equals('Puxada Alta'));
      expect(CatalogoExercicios.buscarPorNome('Puxada Frontal')?.codigoMidia, equals('0197-qdRxqCj'));
      expect(CatalogoExercicios.buscarPorNome('Voador Invertido')?.codigoMidia, equals('0602-myfUsKf'));
      expect(CatalogoExercicios.buscarPorNome('Rosca Martelo (Polia)')?.codigoMidia, equals('0165-HPlPoQA'));
      expect(CatalogoExercicios.buscarPorNome('Rosca Direta (Polia)')?.nome, equals('Rosca Polia Baixa'));
      expect(CatalogoExercicios.buscarPorNome('Rosca Scott Unilateral')?.codigoMidia, equals('0402-7D5bgLT'));
      expect(CatalogoExercicios.buscarPorNome('Remada Máquina')?.codigoMidia, equals('0588-IGjKj1v'));
      expect(CatalogoExercicios.buscarPorNome('Remada Articulada')?.codigoMidia, equals('0588-IGjKj1v'));
      expect(CatalogoExercicios.buscarPorNome('Prancha')?.codigoMidia, equals('2135-VBAWRPG'));
      expect(CatalogoExercicios.buscarPorNome('Desenvolvimento Máquina')?.codigoMidia, equals('2318-dNFYIU1'));
      expect(CatalogoExercicios.buscarPorNome('Elevação Lateral Polia')?.codigoMidia, equals('0192-wEulIzp'));
      expect(CatalogoExercicios.buscarPorNome('Elevação Lateral (Polia)')?.codigoMidia, equals('0192-wEulIzp'));
      expect(CatalogoExercicios.buscarPorNome('Abdominal Declinado')?.codigoMidia, equals('0277-9Ap7miY'));
      expect(CatalogoExercicios.buscarPorNome('Supino Reto Unilateral'), isNull);
      expect(CatalogoExercicios.buscarPorNome('Remada Unilateral (Máquina)')?.codigoMidia, equals('1356-OIFMAp1'));
      expect(CatalogoExercicios.buscarPorNome('Rosca Unilateral')?.codigoMidia, equals('0190-YTur5nR'));
      expect(CatalogoExercicios.buscarPorNome('Elevacao Pélvica')?.nome, equals('Elevação Pélvica'));
      expect(CatalogoExercicios.buscarPorNome('Exercício Inexistente XYZ'), isNull);
    });

    test('Novos exercícios populares no Brasil e substituição do Tríceps Coice pela versão na polia', () {
      expect(CatalogoExercicios.buscarPorNome('Crucifixo Inclinado Halteres')?.codigoMidia, equals('0319-ESOd5Pl'));
      expect(CatalogoExercicios.buscarPorNome('Crossover Polia Baixa')?.codigoMidia, equals('0179-FVmZVhk'));
      expect(CatalogoExercicios.buscarPorNome('Crossover Polia Alta')?.codigoMidia, equals('1269-UKWTJWR'));
      expect(CatalogoExercicios.buscarPorNome('Glúteo Polia')?.codigoMidia, equals('0228-Kpajagk'));
      expect(CatalogoExercicios.buscarPorNome('Glúteo Polia')?.grupo, equals('PERNAS'));
      expect(CatalogoExercicios.buscarPorNome('Passada')?.codigoMidia, equals('1460-IZVHb27'));
      expect(CatalogoExercicios.buscarPorNome('Tríceps Coice Polia')?.codigoMidia, equals('0860-HEJ6DIX'));
      expect(CatalogoExercicios.buscarPorNome('Tríceps Testa na Polia')?.codigoMidia, equals('1722-1xHyxys'));
      expect(CatalogoExercicios.buscarPorNome('Tríceps Testa Polia')?.nome, equals('Tríceps Testa na Polia'));
      // Histórico legado com o nome antigo continua apontando para a nova versão
      expect(CatalogoExercicios.buscarPorNome('Tríceps Coice')?.nome, equals('Tríceps Coice Polia'));
    });

    test('correspondeBusca deve encontrar exercícios por sinônimos populares brasileiros', () {
      expect(CatalogoExercicios.correspondeBusca('Voador', 'peck deck'), isTrue);
      expect(CatalogoExercicios.correspondeBusca('Stiff', 'rdl'), isTrue);
      expect(CatalogoExercicios.correspondeBusca('Elevação Pélvica', 'hip thrust'), isTrue);
      expect(CatalogoExercicios.correspondeBusca('Puxada Alta', 'puxador'), isTrue);
      expect(CatalogoExercicios.correspondeBusca('Passada', 'avanço'), isTrue);
      expect(CatalogoExercicios.correspondeBusca('Glúteo Polia', 'caneleira'), isTrue);
      expect(CatalogoExercicios.correspondeBusca('Tríceps Polia', 'triceps'), isTrue);
      expect(CatalogoExercicios.correspondeBusca('Tríceps Testa na Polia', 'triceps testa polia'), isTrue);
      expect(CatalogoExercicios.correspondeBusca('Crossover Polia Alta', 'crossover alto'), isTrue);
      expect(CatalogoExercicios.correspondeBusca('Supino Reto', 'peck deck'), isFalse);
    });
  });

  group('ExercicioThumbnailWidget & ExercicioDetalheModal', () {
    testWidgets('Deve abrir o ExercicioDetalheModal sob demanda ao tocar na miniatura', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ExercicioThumbnailWidget(
                nomeExercicio: 'Supino Reto',
                grupo: 'PEITO',
                exibirIndicadorGif: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ExercicioThumbnailWidget), findsOneWidget);

      await tester.tap(find.byType(ExercicioThumbnailWidget));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(ExercicioDetalheModal), findsOneWidget);
      expect(find.text('Supino Reto'), findsOneWidget);
      expect(find.text('Peitoral Maior'), findsOneWidget);
      expect(find.text(InfoExercicioCatalogo.atribuicao), findsOneWidget);
    });
  });
}
