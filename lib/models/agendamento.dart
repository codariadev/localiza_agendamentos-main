class Agendamento {
  final String vendedor;
  final String cor;
  final String placa;
  final String modelo;
  final DateTime data;
  final String hora;
  final String status;
  final String? tokenId;

  Agendamento({
    required this.vendedor,
    required this.cor,
    required this.placa,
    required this.modelo,
    required this.data,
    required this.hora,
    this.status = 'pendente',
    this.tokenId,
  });

  Map<String, dynamic> toMap() => {
        'vendedor': vendedor,
        'cor': cor,
        'placa': placa,
        'modelo': modelo,
        'data': data.toIso8601String(),
        'hora': hora,
        'status': status,
        'tokenId': tokenId,
      };
}
