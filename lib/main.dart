import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';

// Handler de background. Deve ser uma função de nível superior.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inicializa o Firebase para garantir que os serviços estejam disponíveis
  await Firebase.initializeApp(); 
  print("Mensagem de background recebida: ${message.messageId}");
  // Aqui você pode processar dados ou disparar notificações locais.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inicializa o Firebase
  await Firebase.initializeApp();
  
  // 2. Registra o handler de background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // 3. Configura handlers e permissões iniciais
  FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  // 4. Configura o handler de foreground (ex: para mostrar notificação local)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Mensagem em foreground recebida: ${message.notification?.title}');
    // Seu código de notificação local (se estiver usando flutter_local_notifications)
    // pode ser chamado aqui.
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}