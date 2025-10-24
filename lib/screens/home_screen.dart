import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:localiza_agendamentos/screens/login_screen.dart';
import '../core/firebase_service.dart';
import '../widgets/agendamento_form.dart';

class HomeScreen extends StatefulWidget {
  final String nomeVendedor;
  final String tokenDevice;

  const HomeScreen({
    super.key,
    required this.nomeVendedor,
    required this.tokenDevice,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firebaseService = FirebaseService();
    final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  bool _isLoading = false;
  

  @override
  void initState(){
    super.initState();
    _initNotifications();
    _listenAgendamentosConcluidos();
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings();
    final initSettings = 
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _enviarNotificacao(String modelo, String placa) async {
  const androidDetails = AndroidNotificationDetails(
    'canal_consultor',
    'Notificações do Consultor',
    channelDescription: 'Notificações para novos agendamentos concluidos',
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
    'Agendamento Concluído',
    'Modelo: $modelo, Placa: $placa',
    generalNotificationDetails,
  );
}


  void _listenAgendamentosConcluidos() {
    _firebaseService.listarAgendamentos().listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Agendamentos concluídos do consultor e ainda não notificados
        if ((data['status'] ?? '').toLowerCase() == 'concluído' &&
            (data['not_consultor'] ?? true) == false &&
            data['vendedor'] == widget.nomeVendedor) {

          // 1️⃣ Envia notificação local
          _enviarNotificacao(data['modelo'], data['placa']);

          // 2️⃣ Atualiza Firestore para not_consultor = true
          _firebaseService.atualizarNotConsultor(doc.id, true);
        }
      }
    });
  }



  void _novoAgendamento() {
    setState(() {
      _isLoading = true;
    });

    showDialog(
      context: context,
      builder: (_) => AgendamentoForm(
        nomeVendedor: widget.nomeVendedor,
        tokenDevice: widget.tokenDevice,
        onAgendamentoCriado: (String deviceTokenHigienizador, String modelo) {
        },
      ),
    ).then((_) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${widget.nomeVendedor}'),
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

          // Filtra apenas agendamentos do usuário logado
          final meusAgendamentos = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['vendedor'] == widget.nomeVendedor;
          }).toList();

          if (meusAgendamentos.isEmpty) {
            return const Center(
              child: Text('Você não possui agendamentos.'),
            );
          }

          return ListView(
            children: meusAgendamentos.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              // ✅ Exibindo em caixa alta (Embora o dado já deva vir assim do banco)
              final modelo = (data['modelo'] as String).toUpperCase();
              final placa = (data['placa'] as String).toUpperCase();
              final status = (data['status'] as String).toUpperCase();

              return ListTile(
                title: Text('$modelo - $placa'),
                subtitle: Text('Status: $status'),
                trailing: data['status'] == 'pendente'
                    ? const Icon(Icons.watch_later, color: Colors.orange)
                    : const Icon(Icons.check_circle, color: Colors.green),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _novoAgendamento,
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.add),
      ),
    );
  }
}
