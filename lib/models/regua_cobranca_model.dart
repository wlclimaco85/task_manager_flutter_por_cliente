enum CanalCobranca {
  email('EMAIL', 'E-mail', true),
  notificacaoInterna('NOTIFICACAO_INTERNA', 'Notificacao interna', true),
  whatsapp('WHATSAPP', 'WhatsApp', true),
  sms('SMS', 'SMS', true);

  const CanalCobranca(this.apiValue, this.label, this.disponivel);

  final String apiValue;
  final String label;
  final bool disponivel;

  static CanalCobranca fromJson(Object? value) {
    final normalized = value?.toString().toUpperCase() ?? '';
    return values.firstWhere(
      (canal) => canal.apiValue == normalized,
      orElse: () => email,
    );
  }
}

class ReguaCobranca {
  const ReguaCobranca({
    this.id,
    required this.nome,
    required this.diasAposVencimento,
    required this.canal,
    required this.mensagem,
    required this.somenteDiaUtil,
    required this.ordem,
    this.ativo = true,
  });

  final int? id;
  final String nome;
  final int diasAposVencimento;
  final CanalCobranca canal;
  final String mensagem;
  final bool somenteDiaUtil;
  final int ordem;
  final bool ativo;

  factory ReguaCobranca.fromJson(Map<String, dynamic> json) {
    return ReguaCobranca(
      id: _asInt(json['id']),
      nome: json['nome']?.toString() ?? 'Etapa de cobranca',
      diasAposVencimento: _asInt(
            json['diasRelativosVencimento'] ?? json['diasAposVencimento'],
          ) ??
          0,
      canal: CanalCobranca.fromJson(json['canal']),
      mensagem: json['mensagem']?.toString() ?? '',
      somenteDiaUtil: _asBool(json['somenteDiaUtil'], fallback: true),
      ordem: _asInt(json['ordem']) ?? 1,
      ativo: _asBool(json['ativo'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'nome': nome,
        'diasAposVencimento': diasAposVencimento,
        'canal': canal.apiValue,
        'mensagem': mensagem,
        'somenteDiaUtil': somenteDiaUtil,
        'ordem': ordem,
        'ativo': ativo,
      };
}

class PainelReguaCobranca {
  const PainelReguaCobranca({
    required this.titulosEmAberto,
    required this.enviosPendentes,
    required this.enviosEnviados,
    required this.enviosFalha,
    required this.valorVencido,
    required this.valorAVencer,
    required this.valorRecuperado,
    required this.aging,
  });

  final int titulosEmAberto;
  final int enviosPendentes;
  final int enviosEnviados;
  final int enviosFalha;
  final double valorVencido;
  final double valorAVencer;
  final double valorRecuperado;
  final List<AgingReguaCobranca> aging;

  factory PainelReguaCobranca.fromJson(Map<String, dynamic> json) =>
      PainelReguaCobranca(
        titulosEmAberto: _asInt(json['titulosEmAberto']) ?? 0,
        enviosPendentes: _asInt(json['enviosPendentes']) ?? 0,
        enviosEnviados: _asInt(json['enviosEnviados']) ?? 0,
        enviosFalha: _asInt(json['enviosFalha']) ?? 0,
        valorVencido: _asDouble(json['valorVencido']) ?? 0,
        valorAVencer: _asDouble(json['valorAVencer']) ?? 0,
        valorRecuperado: _asDouble(json['valorRecuperado']) ?? 0,
        aging: ((json['aging'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => AgingReguaCobranca.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value))))
            .toList(),
      );
}

class AgingReguaCobranca {
  const AgingReguaCobranca({
    required this.faixa,
    required this.quantidade,
    required this.valor,
  });

  final String faixa;
  final int quantidade;
  final double valor;

  factory AgingReguaCobranca.fromJson(Map<String, dynamic> json) =>
      AgingReguaCobranca(
        faixa: json['faixa']?.toString() ?? '-',
        quantidade: _asInt(json['quantidade']) ?? 0,
        valor: _asDouble(json['valor']) ?? 0,
      );
}

class ExecucaoReguaResultado {
  const ExecucaoReguaResultado({
    required this.titulosAvaliados,
    required this.enviosEnfileirados,
    required this.duplicadosIgnorados,
  });

  final int titulosAvaliados;
  final int enviosEnfileirados;
  final int duplicadosIgnorados;

  factory ExecucaoReguaResultado.fromJson(Map<String, dynamic> json) =>
      ExecucaoReguaResultado(
        titulosAvaliados: _asInt(json['titulosAvaliados']) ?? 0,
        enviosEnfileirados: _asInt(json['enviosEnfileirados']) ?? 0,
        duplicadosIgnorados: _asInt(json['duplicadosIgnorados']) ?? 0,
      );
}

class CobrancaRegua {
  const CobrancaRegua({
    required this.id,
    required this.clienteNome,
    required this.valor,
    required this.vencimento,
    required this.status,
    this.etapa,
    this.canal,
    this.executadaEm,
    this.resultado,
    this.destinatario,
    this.tentativas,
    this.ultimoErro,
  });

  final int id;
  final String clienteNome;
  final double valor;
  final DateTime? vencimento;
  final String status;
  final String? etapa;
  final CanalCobranca? canal;
  final DateTime? executadaEm;
  final String? resultado;
  final String? destinatario;
  final int? tentativas;
  final String? ultimoErro;

  factory CobrancaRegua.fromJson(Map<String, dynamic> json) {
    final cliente = json['cliente'];
    final parceiro = json['parceiro'];
    return CobrancaRegua(
      id: _asInt(json['id'] ?? json['cobrancaId'] ?? json['contaReceberId']) ??
          0,
      clienteNome: json['clienteNome']?.toString() ??
          (cliente is Map ? cliente['nome']?.toString() : null) ??
          (parceiro is Map ? parceiro['nome']?.toString() : null) ??
          (json['clienteId'] == null
              ? null
              : 'Cliente #${json['clienteId']}') ??
          'Cliente nao informado',
      valor: _asDouble(json['valor'] ?? json['valorTitulo']) ?? 0,
      vencimento: _asDate(json['vencimento'] ?? json['dataVencimento']),
      status: json['status']?.toString() ?? 'PENDENTE',
      etapa: json['etapa']?.toString() ?? json['etapaNome']?.toString(),
      canal:
          json['canal'] == null ? null : CanalCobranca.fromJson(json['canal']),
      executadaEm: _asDate(json['executadaEm'] ?? json['dataAcao']),
      resultado:
          json['resultado']?.toString() ?? json['mensagemErro']?.toString(),
      destinatario: json['destinatario']?.toString(),
      tentativas: _asInt(json['tentativas']),
      ultimoErro: json['ultimoErro']?.toString(),
    );
  }
}

int? _asInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value');
double? _asDouble(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value');
DateTime? _asDate(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());
bool _asBool(Object? value, {required bool fallback}) {
  if (value is bool) return value;
  if (value == null) return fallback;
  return value.toString().toLowerCase() == 'true';
}
