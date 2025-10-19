import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  final _firestore = FirebaseFirestore.instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin = 
  FlutterLocalNotificationsPlugin();

  FirebaseService() {
    _initializeNotifications();
  }

  void _initializeNotifications() {
    const androidInit = AndroidInitializationSettings('@minimap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        print('Notificação clicada: ${response.payload}');
      },
    );
  }

  void listenAgendamentos(String deviceToken){
    _firestore
      .collection('hig_solicitacoes')
      .where('tokenId', isEqualTo: deviceToken)
      .snapshots()
      .listen((snapshot) async {
        final prefs = await SharedPreferences.getInstance();
        final notificadas = prefs.getStringList('notificadas') ?? [];

        for (var doc in snapshot.docs){
          final data = doc.data();
          final id = doc.id;

          if(data['status'] == 'concluido' && !notificadas.contains(id)){
            await _showLocalNotification(data);
            notificadas.add(id);
            await prefs.setStringList('notificadas', notificadas);
          }
        }
      });
  }

  Future<void> _showLocalNotification(Map<String, dynamic> data) async {
    const androidDetails = AndroidNotificationDetails(
      'agendamentos_channel',
      'Agendamentos',
      channelDescription: 'Notificações de agendamentos concluidos',
      importance: Importance.max,
      priority: Priority.high,
    );

    const generalDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      'Agendamento concluído',
      'O agendamento de ${data['cliente'] ?? 'cliente'} foi concluído.',
      generalDetails,
      payload: data['id'] ?? '',
    );
  }

  Future<void> salvarAgendamento(Map<String, dynamic> data) async {
    await _firestore.collection('hig_solicitacoes').add({
      ...data,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> atualizarStatus(String docId, String novoStatus) async {
    await _firestore.collection('hig_solicitacoes').doc(docId).update({
      'status': novoStatus,
    });
  }

  Future<void> atualizarToken(String docId, String tokenId) async {
    await _firestore.collection('hig_solicitacoes').doc(docId).update({
      'tokenId': tokenId,
    });
  }

  Stream<QuerySnapshot> listarAgendamentos() {
    return _firestore
        .collection('hig_solicitacoes')
        .orderBy('criadoEm', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>?> getAgendamentoById(String docId) async {
    final doc = await _firestore.collection('hig_solicitacoes').doc(docId).get();
    if (doc.exists) return doc.data();
    return null;
  }

  Future<String> pegarTokenHigienizador() async {
  final query = await FirebaseFirestore.instance
      .collection('colaboradores')
      .where('cargo', isEqualTo: 'higienizador')
      .limit(1)
      .get();

  if (query.docs.isNotEmpty) {
    return query.docs.first.data()['deviceToken'] ?? '';
  }
  return '';
}

Future<String?> getTokenPorNome(String vendedorNome) async {
    final snapshot = await _firestore
        .collection('colaboradores')
        .where('nome', isEqualTo: vendedorNome)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first['deviceToken'];
    } else {
      return null;
    }
  }

  Future<void> atualizarDeviceToken(String nomeUsuario, String novoToken) async {

  final snapshot = await _firestore
      .collection('colaboradores')
      .where('nome', isEqualTo: nomeUsuario)
      .limit(1)
      .get();
      
  if (snapshot.docs.isNotEmpty) {
    final docId = snapshot.docs.first.id;
    
    await _firestore.collection('colaboradores').doc(docId).update({
      'deviceToken': novoToken,
    });
    print('Token do usuário $nomeUsuario atualizado com sucesso no Firestore.');
  } else {
    print('Erro: Colaborador $nomeUsuario não encontrado para atualização de token.');
  }
}

}
