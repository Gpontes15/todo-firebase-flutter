import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificacaoService {
  // Padrão Singleton: Garante que o app inteiro use a mesma "caixa de som" para tocar o alarme
  static final NotificacaoService _instancia = NotificacaoService._internal();
  factory NotificacaoService() => _instancia;
  NotificacaoService._internal();

  // A ferramenta principal do pacote que instalamos
  final FlutterLocalNotificationsPlugin pluginNotificacoes = FlutterLocalNotificationsPlugin();

  // Função para ligar o motor das notificações quando o app abrir
  Future<void> init() async {
    // 1. Ensina ao Flutter todos os fusos horários do mundo
    tz.initializeTimeZones();
    // 2. Define o nosso fuso horário local padrão
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    // 3. Configura o ícone que vai aparecer na notificação do Android
    // @mipmap/ic_launcher é o ícone padrão do Flutter (aquele F azul)
    const AndroidInitializationSettings configAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings configuracoesGlobais = InitializationSettings(
      android: configAndroid,
    );

    // 4. Dá a partida no plugin
    await pluginNotificacoes.initialize(settings: configuracoesGlobais);
  }

  // Função que vamos chamar lá do nosso modal quando o usuário salvar a tarefa
  Future<void> agendarNotificacao({
    required int id, // Um número único para a notificação
    required String titulo, // Ex: "Sua tarefa vence hoje!"
    required String corpo, // Ex: "Prova de sistemas operacionais"
    required DateTime dataAgendada,
  }) async {
    
    await pluginNotificacoes.zonedSchedule(
      id: id,
      title: titulo,
      body: corpo,
      // Converte o DateTime normal do Dart para o formato que entende de fusos horários
      scheduledDate: tz.TZDateTime.from(dataAgendada, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'canal_tarefas_1', // ID interno do canal no Android
          'Lembretes de Tarefas', // Nome que o usuário vê nas configurações do celular
          channelDescription: 'Avisa quando uma tarefa está perto de vencer',
          importance: Importance.max, // Faz a notificação pular na tela
          priority: Priority.high,
        ),
      ),
      // Diz pro Android que essa notificação é EXATA e pode acordar o celular
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Função para desarmar a bomba caso a tarefa seja concluída ou apagada
  Future<void> cancelarNotificacao(int id) async {
    await pluginNotificacoes.cancel(id: id);
  }
}