import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  int _schedulingCounter = 0;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    try {
      const androidSettings = AndroidInitializationSettings(
        'ic_notification',
      );
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );
      await _plugin.initialize(settings: settings);
    } catch (_) {
      const androidSettingsFallback = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const settings = InitializationSettings(
        android: androidSettingsFallback,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );
      await _plugin.initialize(settings: settings);
    }

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Solicitação de permissão de notificações para Android 13+ (POST_NOTIFICATIONS)
    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  Future<void> agendarNotificacaoDescanso(int segundos) async {
    final currentToken = ++_schedulingCounter;

    // Cancela imediatamente qualquer notificação/alarme pendente no SO
    await _plugin.cancel(id: 1);
    if (currentToken != _schedulingCounter) return;

    if (segundos <= 0) return;

    const detalhes = NotificationDetails(
      android: AndroidNotificationDetails(
        'descanso_channel_v2',
        'Descanso',
        channelDescription: 'Notificacoes para fim do descanso e regeneracao',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        autoCancel: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        icon: 'ic_notification',
        color: Color(0xFFFF9800),
        largeIcon: DrawableResourceAndroidBitmap('ic_notification_large'),
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    const detalhesFallback = NotificationDetails(
      android: AndroidNotificationDetails(
        'descanso_channel_v2',
        'Descanso',
        channelDescription: 'Notificacoes para fim do descanso e regeneracao',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        autoCancel: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFFF9800),
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    _garantirTimeZones();
    final dataAgendada = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(seconds: segundos));
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    AndroidScheduleMode modoAgendamento =
        AndroidScheduleMode.alarmClock;

    if (android != null) {
      final notificacoesHabilitadas = await android.areNotificationsEnabled();
      if (currentToken != _schedulingCounter) return;

      if (notificacoesHabilitadas == false) {
        final concedida = await android.requestNotificationsPermission();
        if (currentToken != _schedulingCounter) return;
        if (concedida != true) {
          debugPrint(
            'Notificacao nao agendada: permissao de notificacao negada.',
          );
          return;
        }
      }

      final podeAgendarExato = await android.canScheduleExactNotifications();
      if (currentToken != _schedulingCounter) return;

      if (podeAgendarExato != true) {
        modoAgendamento = AndroidScheduleMode.inexactAllowWhileIdle;
      }
    }

    if (currentToken != _schedulingCounter) return;

    try {
      await _plugin.zonedSchedule(
        id: 1,
        title: 'Regeneração Concluída ⏱️',
        body: 'Seu Ki e energia foram restaurados. Hora da próxima série!',
        scheduledDate: dataAgendada,
        notificationDetails: detalhes,
        androidScheduleMode: modoAgendamento,
        matchDateTimeComponents: null,
      );
    } catch (e) {
      if (currentToken != _schedulingCounter) return;

      final isIconError = e.toString().contains('invalid_icon') ||
          e.toString().contains('invalid_large_icon');
      final detalhesParaUsar = isIconError ? detalhesFallback : detalhes;

      try {
        await _plugin.zonedSchedule(
          id: 1,
          title: 'Regeneração Concluída ⏱️',
          body: 'Seu Ki e energia foram restaurados. Hora da próxima série!',
          scheduledDate: dataAgendada,
          notificationDetails: detalhesParaUsar,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: null,
        );
      } catch (err) {
        debugPrint('Erro ao agendar notificacao no fallback: $err');
      }
    }
  }

  Future<void> cancelarNotificacao() async {
    _schedulingCounter++;
    await _plugin.cancel(id: 1);
  }

  void _garantirTimeZones() {
    try {
      tz.local;
    } catch (_) {
      tz_data.initializeTimeZones();
    }
  }
}
