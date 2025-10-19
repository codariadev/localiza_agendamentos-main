import 'package:flutter/material.dart';
import 'package:localiza_agendamentos/screens/login_screen.dart';
import '../core/firebase_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  // Função para concluir agendamento e enviar notificação
  Future<void> _concluirAgendamento(
      String id, String deviceToken, String modelo) async {
    try {
      // Atualiza status no Firestore
      await _firebaseService.atualizarStatus(id, 'concluído');

      // Envia notificação para o consultor
      await _enviarNotificacaoParaConsultor(deviceToken, modelo);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Agendamento concluído e notificação enviada!')),
      );
    } catch (e) {
      print('Erro ao concluir agendamento: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao concluir agendamento')),
      );
    }
  }

  // Função para enviar notificação via API Node
  Future<void> _enviarNotificacaoParaConsultor(
      String deviceToken, String modelo) async {
    final url = Uri.parse(
        'https://api-notifications-flutter.vercel.app/api/sendToConsultor');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceToken': deviceToken,
          'title': 'Agendamento concluído',
          'body': 'O agendamento do veículo $modelo foi concluído.',
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Notificação enviada com sucesso!');
      } else {
        print('❌ Erro ao enviar notificação: ${response.body}');
      }
    } catch (e) {
      print('❌ Erro na requisição HTTP: $e');
    }
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

                      // 🔍 Log completo de todos os campos e tipos
                      print('==================== DEBUG AGENDAMENTO ====================');
                      print('ID do documento: ${doc.id}');
                      dataMap.forEach((key, value) {
                        print('$key => $value  |  Tipo: ${value.runtimeType}');
                      });
                      print('===========================================================');

                      final tokenId = dataMap['tokenId'];
                      final modelo = dataMap['modelo'];
                      final placa = dataMap['placa'];
                      final vendedor = dataMap['vendedor'];
                      final status = dataMap['status'];

                      // 🔎 Verificação de campos obrigatórios
                      final erros = <String>[];
                      if (tokenId == null || tokenId.toString().trim().isEmpty) {
                        erros.add('tokenId ausente ou vazio');
                      }
                      if (modelo == null || modelo.toString().trim().isEmpty) {
                        erros.add('modelo ausente ou vazio');
                      }
                      if (placa == null || placa.toString().trim().isEmpty) {
                        erros.add('placa ausente ou vazia');
                      }
                      if (vendedor == null || vendedor.toString().trim().isEmpty) {
                        erros.add('vendedor ausente ou vazio');
                      }

                      if (erros.isNotEmpty) {
                        print('❌ ERRO → Campos faltando:');
                        for (var erro in erros) {
                          print(' - $erro');
                        }
                        print('===========================================================');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro: ${erros.join(", ")}')),
                        );
                        return;
                      }

                      // ✅ Tudo certo, envia notificação
                      print('✅ Todos os campos obrigatórios estão preenchidos!');
                      print('Enviando notificação para token: $tokenId');
                      print('Modelo: $modelo');
                      print('===========================================================');

                      _concluirAgendamento(doc.id, tokenId, modelo);
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
