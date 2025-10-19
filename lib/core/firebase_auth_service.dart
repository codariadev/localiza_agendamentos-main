import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<Map<String, dynamic>?> login(String senhaDigitada) async {
    if (senhaDigitada.isEmpty) throw Exception('Informe a senha');

    // Busca em ambas as coleções
    final queryVendedor = await _firestore
        .collection('colaboradores')
        .where('senha', isEqualTo: senhaDigitada)
        .where('cargo', isEqualTo: 'vendedor')
        .get();

    final queryHigienizador = await _firestore
        .collection('colaboradores')
        .where('senha', isEqualTo: senhaDigitada)
        .where('cargo', isEqualTo: 'higienizador')
        .get();

    final deviceToken = await _fcm.getToken();

    if (queryVendedor.docs.isNotEmpty) {
      final data = queryVendedor.docs.first.data();
      return {
        'nome': data['nome'] ?? 'Usuário',
        'cargo': 'vendedor',
        'token': deviceToken,
      };
    } else if (queryHigienizador.docs.isNotEmpty) {
      final data = queryHigienizador.docs.first.data();
      return {
        'nome': data['nome'] ?? 'Usuário',
        'cargo': 'higienizador',
        'token': deviceToken,
      };
    } else {
      return null;
    }
  }
}
