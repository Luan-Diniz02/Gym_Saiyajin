import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: settings);

    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    await _plugin
        .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    
    // Solicitação de permissões para Android 13+ e Alarmes Exatos (Android 12+)
    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  Future<void> agendarNotificacaoDescanso(int segundos) async {
    if (segundos <= 0) return;

    const detalhes = NotificationDetails(
      android: AndroidNotificationDetails(
        'descanso_channel_v2',
        'Descanso',
        channelDescription: 'Notificacoes para fim do descanso',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    final dataAgendada = tz.TZDateTime.now(tz.local).add(Duration(seconds: segundos));
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    AndroidScheduleMode modoAgendamento = AndroidScheduleMode.exactAllowWhileIdle;

    if (android != null) {
      final notificacoesHabilitadas = await android.areNotificationsEnabled();
      if (notificacoesHabilitadas == false) {
        final concedida = await android.requestNotificationsPermission();
        if (concedida != true) {
          debugPrint('Notificacao nao agendada: permissao de notificacao negada.');
          return;
        }
      }

      final podeAgendarExato = await android.canScheduleExactNotifications();
      if (podeAgendarExato != true) {
        modoAgendamento = AndroidScheduleMode.inexactAllowWhileIdle;
      }
    }

    try {
      await _plugin.zonedSchedule(
        id: 1,
        title: 'Descanso Finalizado! ⏰',
        body: 'Bora voltar para o treino, monstro!',
        scheduledDate: dataAgendada,
        notificationDetails: detalhes,
        androidScheduleMode: modoAgendamento,
        matchDateTimeComponents: null,
      );
    } catch (e) {
      if (modoAgendamento == AndroidScheduleMode.exactAllowWhileIdle) {
        await _plugin.zonedSchedule(
          id: 1,
          title: 'Descanso Finalizado! ⏰',
          body: 'Bora voltar para o treino, monstro!',
          scheduledDate: dataAgendada,
          notificationDetails: detalhes,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: null,
        );
        return;
      }

      rethrow;
    }
  }

  Future<void> cancelarNotificacao() async {
    await _plugin.cancel(id: 1);
  }
}
