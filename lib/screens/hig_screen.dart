import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:localiza_agendamentos/screens/login_screen.dart';
import '../core/firebase_service.dart';


class HigScreen extends StatefulWidget {
  final String nome;
  final String tokenDevice;

  const HigScreen({
    super.key,
    required this.nome,
    required this.tokenDevice,
  });

  @override
  State<HigScreen> createState() => _HigScreenState();
}

class _HigScreenState extends State<HigScreen> {
  final _firebaseService = FirebaseService();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState(){
    super.initState();
    _initNotifications();
    _listenNovosAgendamentos();
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings();
    final initSettings = 
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    _firebaseService.listarAgendamentos().listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Agendamentos concluídos do consultor e ainda não notificados
        if ((data['status'] ?? '').toLowerCase() == 'pendente' &&
            (data['not_higienizador'] ?? true) ) {

          // 1️⃣ Envia notificação local
          _enviarNotificacao(data['modelo'], data['placa']);

          // 2️⃣ Atualiza Firestore para not_consultor = true
          _firebaseService.atualizarNotHigienizador(doc.id, true);
        }
      }
    });
  }

  Future<void> _enviarNotificacao(String modelo, String placa) async {
  const androidDetails = AndroidNotificationDetails(
    'canal_higienizador',
    'Notificações de Higienizador',
    channelDescription: 'Notificações para novos agendamentos de higienização',
    importance: Importance.max,
    priority: Priority.high,
  );

  final iosDetails = DarwinNotificationDetails();

  final generalNotificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await _flutterLocalNotificationsPlugin.show(
    0,
    'Novo Agendamento',
    'Modelo: $modelo, Placa: $placa',
    generalNotificationDetails,
  );
}



  
  Future<void> _concluirAgendamento(
      String id, String deviceTokeno) async {
    try {
      await _firebaseService.atualizarStatus(id, 'concluído');
      await _firebaseService.atualizarNotConsultor(id, true);
            print('Agendamento $id concluído com sucesso.');
    } catch (e) {
      print('Erro ao concluir agendamento: $e');
    }
  }

  

    void _listenNovosAgendamentos() {
    _firebaseService.listarAgendamentos().listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Só pegar agendamentos pendentes e not_higienizador == false
        if ((data['status'] ?? '').toLowerCase() == 'pendente' &&
            (data['not_higienizador'] ?? true) == false) {

          // 1️⃣ Envia notificação
          _enviarNotificacao(data['modelo'], data['placa']);

          // 2️⃣ Atualiza no Firestore para not_higienizador = true
          _firebaseService.atualizarNotHigienizador(doc.id, true);
        }
      }
    });
  }

  



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Higienizador: ${widget.nome}'),
        backgroundColor: const Color.fromRGBO(8, 143, 66, 1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          )
        ],
      ),
      body: StreamBuilder(
        stream: _firebaseService.listarAgendamentos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          // Filtra apenas agendamentos pendentes
          final meusAgendamentos = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['status'] ?? '').toLowerCase() == 'pendente';
          }).toList();

          if (meusAgendamentos.isEmpty) {
            return const Center(child: Text('Nenhum agendamento pendente.'));
          }

          return ListView.builder(
            itemCount: meusAgendamentos.length,
            itemBuilder: (context, index) {
              final doc = meusAgendamentos[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text('${data['modelo']} - ${data['placa']}'),
                  subtitle: Text('Consultor: ${data['vendedor']}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      final dataMap = doc.data() as Map<String, dynamic>;

                      final tokenId = dataMap['tokenId']??'';


                      _concluirAgendamento(doc.id, tokenId);
                    },
                    // 👇 Aqui está o child obrigatório
                    child: const Text('Concluir'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

