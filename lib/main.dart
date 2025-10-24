import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
// Importação com prefixo para evitar conflitos de nomes (Importance, NotificationVisibility)
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:localiza_agendamentos/core/foreground_service.dart';
import 'screens/login_screen.dart';
import 'firebase_options.dart';

// Usa o prefixo fln para o plugin de notificações
final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    fln.FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  // Usa o prefixo fln
  const fln.AndroidInitializationSettings initializationSettingsAndroid =
      fln.AndroidInitializationSettings('@mipmap/ic_launcher');

  // Usa o prefixo fln
  final fln.InitializationSettings initializationSettings = fln.InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: null,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializa notificações locais
  await initializeNotifications();

  // Inicializa o FlutterForegroundTask (sem await)
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'foreground_channel',
      channelName: 'Foreground Service',
      channelDescription: 'Executa tarefas em background',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
      // Icone é inferido ou configurado via 'taskIconName'
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    // CORREÇÃO CRÍTICA ABAIXO
    foregroundTaskOptions: ForegroundTaskOptions(
      // eventAction é OBRIGATÓRIO. Usamos .repeat(interval)
      eventAction: ForegroundTaskEventAction.repeat(5000), // Repete a cada 5000ms
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  // Inicia automaticamente o serviço em foreground
  await FlutterForegroundTask.startService(
    notificationTitle: 'Monitorando agendamentos',
    notificationText: 'O app está ativo em background',
    callback: startCallback,
  );

  runApp(const MyApp());
}

// Define o MonitorTaskHandler
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MonitorTaskHandler());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Localiza Agendamentos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
