import 'package:flutter/material.dart';
import '../core/firebase_service.dart';
import '../models/agendamento.dart';
import '../core/formatters.dart';

class AgendamentoForm extends StatefulWidget {
  final String nomeVendedor;
  final String tokenDevice;
  final Function(String deviceTokenHigienizador, String modelo) onAgendamentoCriado;

  const AgendamentoForm({
    super.key,
    required this.nomeVendedor,
    required this.tokenDevice,
    required this.onAgendamentoCriado,
  });

  @override
  State<AgendamentoForm> createState() => _AgendamentoFormState();
}

class _AgendamentoFormState extends State<AgendamentoForm> {
  final _formKey = GlobalKey<FormState>();
  final _corController = TextEditingController();
  final _placaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _horaController = TextEditingController();
  DateTime _dataSelecionada = DateTime.now();
  final _firebaseService = FirebaseService();
  bool _isSaving = false;

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        // 1️⃣ Pega o token do higienizador do Firestore
        final tokenHigienizador = await _firebaseService.pegarTokenHigienizador();

        // 2️⃣ Cria o agendamento com todos os campos
        final agendamento = Agendamento(
          vendedor: widget.nomeVendedor,
          cor: _corController.text,
          placa: _placaController.text,
          modelo: _modeloController.text,
          data: _dataSelecionada,
          hora: _horaController.text,
          tokenId: tokenHigienizador,
          not_higienizador: false,
          not_consultor: false,
        );

        // 3️⃣ Salva no Firestore
        await _firebaseService.salvarAgendamento(agendamento.toMap());

        // 4️⃣ Chama callback para notificar a tela anterior
        widget.onAgendamentoCriado(tokenHigienizador, _modeloController.text);

        // Fecha o modal
        Navigator.pop(context);
      } catch (e) {
        // Tratar erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar agendamento: $e')),
        );
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Agendamento'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _corController,
                decoration: const InputDecoration(labelText: 'Cor'),
                inputFormatters: [UpperCaseTextFormatter()],
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              TextFormField(
                controller: _placaController,
                decoration: const InputDecoration(labelText: 'Placa'),
                inputFormatters: [UpperCaseTextFormatter()],
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              TextFormField(
                controller: _modeloController,
                decoration: const InputDecoration(labelText: 'Modelo'),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              // Campo de Data
              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Data',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                controller: TextEditingController(
                  text:
                      "${_dataSelecionada.year}-${_dataSelecionada.month.toString().padLeft(2,'0')}-${_dataSelecionada.day.toString().padLeft(2,'0')}",
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _dataSelecionada,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _dataSelecionada = picked);
                  }
                },
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              // Campo de Hora
              TextFormField(
                readOnly: true,
                controller: _horaController,
                decoration: const InputDecoration(
                  labelText: 'Hora',
                  suffixIcon: Icon(Icons.access_time),
                ),
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _horaController.text =
                          "${picked.hour.toString().padLeft(2,'0')}:${picked.minute.toString().padLeft(2,'0')}";
                    });
                  }
                },
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSaving ? null : _salvar,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
