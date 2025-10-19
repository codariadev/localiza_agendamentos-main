import 'package:flutter/material.dart';
import 'package:localiza_agendamentos/screens/login_screen.dart';
import '../core/firebase_service.dart';
import '../widgets/agendamento_form.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeScreen extends StatelessWidget {
  final String nomeVendedor;
  final String tokenDevice;
  final _firebaseService = FirebaseService();

  HomeScreen({
    super.key,
    required this.nomeVendedor,
    required this.tokenDevice,
  });

  // 🔔 Função para enviar notificação (igual ao HigScreen)
  Future<void> _enviarNotificacaoHigienizador(
      String deviceToken, String modelo) async {
    final url = Uri.parse(
        'https://localiza-agendamentos-main.vercel.app/api/sendToHig'); // seu endpoint Node

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': deviceToken,
          'title': 'Novo agendamento recebido',
          'body': 'O veículo $modelo foi agendado para higienização.',
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Notificação enviada com sucesso');
      } else {
        print('❌ Erro ao enviar notificação: ${response.body}');
      }
    } catch (e) {
      print('❌ Erro na requisição HTTP: $e');
    }
  }

  void _novoAgendamento(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AgendamentoForm(
        nomeVendedor: nomeVendedor,
        tokenDevice: tokenDevice,
        // callback para enviar notificação após salvar
        onAgendamentoCriado: (String deviceTokenHigienizador, String modelo) {
          _enviarNotificacaoHigienizador(deviceTokenHigienizador, modelo);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, $nomeVendedor'),
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
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          // Filtra apenas agendamentos do usuário logado
          final meusAgendamentos = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['vendedor'] == nomeVendedor;
          }).toList();

          if (meusAgendamentos.isEmpty) {
            return const Center(
              child: Text('Você não possui agendamentos.'),
            );
          }

          return ListView(
            children: meusAgendamentos.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text('${data['modelo']} - ${data['placa']}'),
                subtitle: Text('Status: ${data['status']}'),
                trailing: data['status'] == 'pendente'
                    ? const Icon(Icons.watch_later, color: Colors.orange)
                    : const Icon(Icons.check_circle, color: Colors.green),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _novoAgendamento(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
