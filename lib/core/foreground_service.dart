import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
// CORREÇÃO: Usando 'as fln' para evitar ambiguidade de 'NotificationVisibility' e 'Importance'
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln; 
import 'package:firebase_core/firebase_core.dart';
import 'package:localiza_agendamentos/firebase_options.dart';

class MonitorTaskHandler extends TaskHandler {
  StreamSubscription? _listener;
  final fln.FlutterLocalNotificationsPlugin _notifications = fln.FlutterLocalNotificationsPlugin();

  @override
  // CORREÇÃO: onStart espera TaskStarter?
  Future<void> onStart(DateTime timestamp, TaskStarter? taskStarter) async {
    // Inicialização do Firebase no Isolate
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Inicialização do Local Notifications no Isolate
    const fln.AndroidInitializationSettings initSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    const fln.InitializationSettings initSettings =
        fln.InitializationSettings(android: initSettingsAndroid);
    await _notifications.initialize(initSettings);

    // Inicia o listener do Firestore em tempo real
    _listener = FirebaseFirestore.instance.collection('agendamentos').snapshots().listen((snapshot) {
      for (var docChange in snapshot.docChanges) {
        // Notifica apenas quando um documento é ADICIONADO
        if (docChange.type == DocumentChangeType.added) {
          // Extrai os dados, se necessário, para personalizar a notificação
          final data = docChange.doc.data();
          final String title = data?['title'] ?? "Novo Agendamento";
          final String body = data?['description'] ?? "Um novo agendamento foi criado no sistema.";
          
          _showNotification(title, body);
        }
      }
    });
  }

  Future<void> _showNotification(String title, String body) async {
    const fln.AndroidNotificationDetails androidDetails = fln.AndroidNotificationDetails(
      'agendamentos_channel',
      'Agendamentos',
      channelDescription: 'Notificações de novos agendamentos',
      // CORREÇÃO: Usando o prefixo fln.
      importance: fln.Importance.max,
      priority: fln.Priority.high,
      // CORREÇÃO: Usando o prefixo fln.
      visibility: fln.NotificationVisibility.public,
    );
    const fln.NotificationDetails details = fln.NotificationDetails(android: androidDetails);
    
    // ID dinâmico para permitir múltiplas notificações
    final int notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
    await _notifications.show(notificationId, title, body, details);
  }

  @override
  // CORREÇÃO: onDestroy espera bool
  Future<void> onDestroy(DateTime timestamp, bool isRemoved) async {
    // Cancela o listener do Firestore para liberar recursos ao destruir a tarefa
    await _listener?.cancel();
  }

  @override
  // CORREÇÃO: onRepeatEvent não espera SendPort?
  void onRepeatEvent(DateTime timestamp) {
    // Não é necessário lógica aqui, pois o monitoramento é feito via Stream no onStart.
    // Manter o método vazio é o esperado.
  }
}
