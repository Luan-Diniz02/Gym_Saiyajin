import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_saiyajin/services/notification_service.dart';

import 'package:timezone/data/latest.dart' as tz_data;

class MockFlutterLocalNotificationsPlugin extends Fake
    implements FlutterLocalNotificationsPlugin {
  final List<int> cancelChamadas = [];
  final List<Map<String, dynamic>> zonedScheduleChamadas = [];
  Completer<void>? atrasoZonedSchedule;

  @override
  Future<void> cancel({required int id, String? tag}) async {
    cancelChamadas.add(id);
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required dynamic scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
  }) async {
    if (atrasoZonedSchedule != null) {
      await atrasoZonedSchedule!.future;
    }
    zonedScheduleChamadas.add({
      'id': id,
      'title': title,
      'body': body,
      'scheduledDate': scheduledDate,
      'notificationDetails': notificationDetails,
      'androidScheduleMode': androidScheduleMode,
    });
  }

  @override
  T? resolvePlatformSpecificImplementation<
    T extends FlutterLocalNotificationsPlatform
  >() {
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService - Prevenção de Notificações Duplicadas', () {
    late MockFlutterLocalNotificationsPlugin mockPlugin;
    late NotificationService service;

    setUpAll(() {
      tz_data.initializeTimeZones();
    });

    setUp(() {
      mockPlugin = MockFlutterLocalNotificationsPlugin();
      service = NotificationService(plugin: mockPlugin);
    });

    test(
      'Deve cancelar notificacao existente antes de agendar uma nova',
      () async {
        await service.agendarNotificacaoDescanso(60);

        expect(mockPlugin.cancelChamadas, contains(1));
        expect(mockPlugin.zonedScheduleChamadas.length, 1);
        expect(mockPlugin.zonedScheduleChamadas.first['id'], 1);
      },
    );

    test(
      'Nao deve agendar se o tempo for menor ou igual a zero, mas deve cancelar pendente',
      () async {
        await service.agendarNotificacaoDescanso(0);

        expect(mockPlugin.cancelChamadas, contains(1));
        expect(mockPlugin.zonedScheduleChamadas, isEmpty);
      },
    );

    test(
      'Chamadas concorrentes: apenas a requisição mais recente deve agendar notificação',
      () async {
        // Simula uma chamada demorada na primeira requisição
        mockPlugin.atrasoZonedSchedule = Completer<void>();

        // Dispara requisição 1 (que ficará represada no atraso)
        final futuro1 = service.agendarNotificacaoDescanso(60);

        // Dispara requisição 2 logo em seguida (ex: clique em dois checks seguidos)
        // Remove o atraso para requisições subsequentes
        mockPlugin.atrasoZonedSchedule!.complete();
        mockPlugin.atrasoZonedSchedule = null;

        final futuro2 = service.agendarNotificacaoDescanso(90);

        await Future.wait([futuro1, futuro2]);

        // Apenas a chamada 2 deve ter sido registrada no zonedSchedule final
        expect(mockPlugin.zonedScheduleChamadas.length, 1);
      },
    );

    test(
      'cancelarNotificacao invalida agendamento pendente concorrente',
      () async {
        mockPlugin.atrasoZonedSchedule = Completer<void>();

        final futuroAgendamento = service.agendarNotificacaoDescanso(60);

        // Usuário cancela antes de concluir
        await service.cancelarNotificacao();
        mockPlugin.atrasoZonedSchedule!.complete();
        mockPlugin.atrasoZonedSchedule = null;

        await futuroAgendamento;

        // Nenhuma notificação deve ter sido agendada
        expect(mockPlugin.zonedScheduleChamadas, isEmpty);
      },
    );

    test(
      'Deve configurar icone monocromatico, cor ambar e largeIcon nos detalhes Android',
      () async {
        await service.agendarNotificacaoDescanso(60);

        final chamada = mockPlugin.zonedScheduleChamadas.first;
        expect(
          chamada['androidScheduleMode'],
          AndroidScheduleMode.alarmClock,
        );
        final details = chamada['notificationDetails'] as NotificationDetails;
        expect(details.android?.icon, 'ic_notification');
        expect(details.android?.color, const Color(0xFFFF9800));
        expect(details.android?.largeIcon, isA<DrawableResourceAndroidBitmap>());
        final largeIcon =
            details.android?.largeIcon as DrawableResourceAndroidBitmap;
        expect(largeIcon.data, 'ic_notification_large');
      },
    );
  });
}
