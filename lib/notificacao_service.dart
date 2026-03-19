import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificacaoService {
  static final NotificacaoService _instancia = NotificacaoService._internal();
  factory NotificacaoService() => _instancia;
  NotificacaoService._internal();

  final FlutterLocalNotificationsPlugin pluginNotificacoes = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    const AndroidInitializationSettings configAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings configuracoesGlobais = InitializationSettings(
      android: configAndroid,
    );

    await pluginNotificacoes.initialize(settings: configuracoesGlobais);

    await pluginNotificacoes
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> agendarNotificacao({
    required int id,
    required String titulo,
    required String corpo,
    required DateTime dataAgendada,
  }) async {
    await pluginNotificacoes.zonedSchedule(
      id: id,
      title: titulo,
      body: corpo,
      scheduledDate: tz.TZDateTime.from(dataAgendada, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'canal_tarefas_1',
          'Lembretes de Tarefas',
          channelDescription: 'Avisa quando uma tarefa está perto de vencer',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelarNotificacao(int id) async {
    await pluginNotificacoes.cancel(id: id);
  }

  // --- FUNÇÃO NOVA PARA O NOSSO TESTE IMEDIATO ---
  Future<void> mostrarNotificacaoImediata() async {
    await pluginNotificacoes.show(
      id: 888, // <-- Adicionado id:
      title: 'Sucesso no Teste!', // <-- Adicionado title:
      body: 'A notificação estilo WhatsApp pulou no ecrã!', // <-- Adicionado body:
      notificationDetails: const NotificationDetails( // <-- Adicionado notificationDetails:
        android: AndroidNotificationDetails(
          'canal_tarefas_1', 
          'Lembretes de Tarefas',
          importance: Importance.max, 
          priority: Priority.high,
        ),
      ),
    );
  }
}