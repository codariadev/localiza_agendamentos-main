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
  
  // ❌ REMOVIDO _horaController, pois a hora será selecionada via Dropdown
  // final _horaController = TextEditingController(); 

  // ✅ NOVO: Variável de estado para a hora selecionada via Dropdown
  String? _horaSelecionada;
  
  DateTime _dataSelecionada = DateTime.now();
  final _firebaseService = FirebaseService();
  bool _isSaving = false;

  // ✅ GERA A LISTA DE HORÁRIOS DE 9:00H ATÉ 17:00H (30 em 30 minutos)
  final List<String> _timeSlots = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30',
    '15:00', '15:30', '16:00', '16:30', '17:00',
  ];

  // Garantindo que todos os textos sejam salvos em caixa alta
  String _toUpper(String text) => text.trim().toUpperCase();

  void _salvar() async {
    // Agora verifica se a hora também foi selecionada (_horaSelecionada != null)
    if (_formKey.currentState!.validate() && _horaSelecionada != null) {
      setState(() => _isSaving = true);

      try {
        // 1️⃣ Pega o token do higienizador do Firestore
        final tokenHigienizador = await _firebaseService.pegarTokenHigienizador();

        // 2️⃣ Cria o agendamento com todos os campos
        final agendamento = Agendamento(
          vendedor: widget.nomeVendedor,
          cor: _toUpper(_corController.text),
          placa: _toUpper(_placaController.text),
          modelo: _toUpper(_modeloController.text),
          data: _dataSelecionada,
          // ✅ USA A HORA SELECIONADA DO DROPDOWN
          hora: _horaSelecionada!, 
          tokenId: tokenHigienizador,
          not_higienizador: false,
          not_consultor: false,
        );

        // 3️⃣ Salva no Firestore
        await _firebaseService.salvarAgendamento(agendamento.toMap());

        // 4️⃣ Chama callback para notificar a tela anterior (usando o modelo em caixa alta)
        widget.onAgendamentoCriado(tokenHigienizador, agendamento.modelo);

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
    } else if (_horaSelecionada == null) {
      // Mensagem de erro caso o horário não tenha sido selecionado
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione um horário para o agendamento.')),
        );
      setState(() => _isSaving = false);
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
                controller: _placaController,
                decoration: const InputDecoration(labelText: 'Placa'),
                inputFormatters: [UpperCaseTextFormatter()],
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              TextFormField(
                controller: _modeloController,
                decoration: const InputDecoration(labelText: 'Modelo'),
                inputFormatters: [UpperCaseTextFormatter()],
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              TextFormField(
                controller: _corController,
                decoration: const InputDecoration(labelText: 'Cor'),
                inputFormatters: [UpperCaseTextFormatter()],
                textCapitalization: TextCapitalization.characters,
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
              // ✅ CAMPO DE HORA SUBSTITUÍDO POR DROPDOWN
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Hora',
                  suffixIcon: Icon(Icons.access_time),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                value: _horaSelecionada,
                hint: const Text('Selecione o horário'),
                isExpanded: true,
                items: _timeSlots.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _horaSelecionada = newValue;
                  });
                },
                // O validador garante que a seleção não é nula
                validator: (value) => value == null ? 'Campo obrigatório' : null,
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
