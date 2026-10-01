class AlertaManual {
  final int? id;
  final int? idUserDestino;
  final String? data;
  final String texto;
  final String status;
  final int? empresaId;
  final int? parceiroId;
  final String? parceiroNome;

  const AlertaManual({
    this.id,
    this.idUserDestino,
    this.data,
    required this.texto,
    required this.status,
    this.empresaId,
    this.parceiroId,
    this.parceiroNome,
  });

  factory AlertaManual.fromJson(Map<String, dynamic> json) {
    return AlertaManual(
      id: (json['id'] as num?)?.toInt(),
      idUserDestino: (json['idUserDestino'] as num?)?.toInt(),
      data: json['data']?.toString(),
      texto: json['texto']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      empresaId: (json['empresaId'] as num?)?.toInt(),
      parceiroId: (json['parceiroId'] as num?)?.toInt(),
      parceiroNome: json['parceiroNome']?.toString(),
    );
  }
}

class ParceiroAlertaOpcao {
  final int id;
  final String nome;
  final String? documento;

  const ParceiroAlertaOpcao({
    required this.id,
    required this.nome,
    this.documento,
  });

  factory ParceiroAlertaOpcao.fromJson(Map<String, dynamic> json) {
    final nome = json['nome']?.toString();
    final razao = json['razaoSocial']?.toString();
    return ParceiroAlertaOpcao(
      id: (json['id'] as num).toInt(),
      nome: (nome != null && nome.trim().isNotEmpty)
          ? nome
          : (razao != null && razao.trim().isNotEmpty
              ? razao
              : 'Parceiro sem nome'),
      documento: json['cpf']?.toString() ?? json['cpfCnpj']?.toString(),
    );
  }
}

class ResultadoDisparoAlerta {
  final int destinatarios;
  final bool todosClientes;

  const ResultadoDisparoAlerta({
    required this.destinatarios,
    required this.todosClientes,
  });

  factory ResultadoDisparoAlerta.fromJson(Map<String, dynamic> json) {
    return ResultadoDisparoAlerta(
      destinatarios: (json['destinatarios'] as num?)?.toInt() ?? 0,
      todosClientes: json['todosClientes'] == true,
    );
  }
}
