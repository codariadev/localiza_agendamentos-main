class Agendamento {
  final String vendedor;
  final String cor;
  final String placa;
  final String modelo;
  final DateTime data;
  final String hora;
  final String tokenId;
  final bool not_higienizador;
  final bool not_consultor;

  Agendamento({
    required this.vendedor,
    required this.cor,
    required this.placa,
    required this.modelo,
    required this.data,
    required this.hora,
    required this.tokenId,
    required this.not_higienizador,
    required this.not_consultor,
  });

  Map<String, dynamic> toMap() {
    return {
      'vendedor': vendedor,
      'cor': cor,
      'placa': placa,
      'modelo': modelo,
      'data': data.toIso8601String(),
      'hora': hora,
      'tokenId': tokenId,
      'not_higienizador': not_higienizador,
      'not_consultor': not_consultor,
      'status': 'pendente',
    };
  }
}