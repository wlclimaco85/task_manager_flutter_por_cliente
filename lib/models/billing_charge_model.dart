enum BillingChargeType {
  boleto('BOLETO', 'Boleto'),
  pix('PIX', 'Pix'),
  hybrid('BOLETO_PIX', 'Boleto + Pix');

  final String apiValue;
  final String label;

  const BillingChargeType(this.apiValue, this.label);

  static BillingChargeType? fromApiValue(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'BOLETO':
        return BillingChargeType.boleto;
      case 'PIX':
        return BillingChargeType.pix;
      case 'BOLETO_PIX':
      case 'BOLETO+PIX':
      case 'HIBRIDO':
        return BillingChargeType.hybrid;
      default:
        return null;
    }
  }
}

class BillingChargeResult {
  final String billingId;
  final String status;
  final BillingChargeType? type;
  final String? formaPagamentoNome;
  final double? amount;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? paidAt;
  final DateTime? lastConsultedAt;
  final bool boletoAvailable;
  final bool pixAvailable;
  final List<String> warnings;
  final String? linkCobranca;
  final String? boletoLink;
  final String? linhaDigitavel;
  final String? codigoBarras;
  final String? pixQrCodeBase64;
  final String? pixCopiaCola;
  final String? txid;
  final String? nossoNumero;
  final String? referenciaExterna;
  final String? observacao;
  final String? etapaRegua;
  final String? reguaStatus;
  final String? canalEnvio;
  final DateTime? proximoEnvioEm;
  final DateTime? ultimoEnvioEm;
  final int quantidadeEnvios;
  final String? ultimoErroEnvio;

  const BillingChargeResult({
    required this.billingId,
    required this.status,
    this.type,
    this.formaPagamentoNome,
    this.amount,
    this.dueDate,
    this.createdAt,
    this.paidAt,
    this.lastConsultedAt,
    this.boletoAvailable = false,
    this.pixAvailable = false,
    this.warnings = const [],
    this.linkCobranca,
    this.boletoLink,
    this.linhaDigitavel,
    this.codigoBarras,
    this.pixQrCodeBase64,
    this.pixCopiaCola,
    this.txid,
    this.nossoNumero,
    this.referenciaExterna,
    this.observacao,
    this.etapaRegua,
    this.reguaStatus,
    this.canalEnvio,
    this.proximoEnvioEm,
    this.ultimoEnvioEm,
    this.quantidadeEnvios = 0,
    this.ultimoErroEnvio,
  });

  factory BillingChargeResult.fromJson(Map<String, dynamic> json) {
    String? pick(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value != null) {
          final text = value.toString().trim();
          if (text.isNotEmpty) return text;
        }
      }
      return null;
    }

    DateTime? pickDate(List<String> keys) {
      final value = pick(keys);
      if (value == null) return null;
      return DateTime.tryParse(value);
    }

    double? pickDouble(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is num) return value.toDouble();
        if (value != null) {
          final parsed = double.tryParse(value.toString().replaceAll(',', '.'));
          if (parsed != null) return parsed;
        }
      }
      return null;
    }

    int? pickInt(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value != null) {
          final parsed = int.tryParse(value.toString());
          if (parsed != null) return parsed;
        }
      }
      return null;
    }

    bool? pickBool(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is bool) return value;
        if (value is num) return value != 0;
        if (value != null) {
          final normalized = value.toString().trim().toLowerCase();
          if (normalized == 'true' ||
              normalized == '1' ||
              normalized == 'sim') {
            return true;
          }
          if (normalized == 'false' ||
              normalized == '0' ||
              normalized == 'nao') {
            return false;
          }
        }
      }
      return null;
    }

    List<String> pickWarnings(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is List) {
          return value
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList();
        }
      }
      return const [];
    }

    return BillingChargeResult(
      billingId: pick(['id', 'billingId', 'billing_id', 'cobrancaId']) ?? '',
      status: pick(['status', 'situacao']) ?? 'PENDENTE',
      type: BillingChargeType.fromApiValue(
        pick(['tipoCobranca', 'billingType', 'tipo']),
      ),
      formaPagamentoNome: pick(['formaPagamentoNome', 'paymentMethodName']),
      amount: pickDouble(['valor', 'amount']),
      dueDate: pickDate(['dataVencimento', 'dueDate']),
      createdAt: pickDate(['dataGeracao', 'createdAt']),
      paidAt: pickDate(['dataPagamento', 'paidAt']),
      lastConsultedAt: pickDate(['ultimaConsultaEm', 'lastConsultedAt']),
      boletoAvailable: pickBool(['boletoDisponivel']) ?? false,
      pixAvailable: pickBool(['pixDisponivel']) ?? false,
      warnings: pickWarnings(['avisos', 'warnings']),
      linkCobranca: pick(['linkCobranca', 'link_cobranca', 'paymentLink']),
      boletoLink: pick(['boletoLink', 'boleto_url', 'boletoUrl', 'linkBoleto']),
      linhaDigitavel: pick([
        'linhaDigitavel',
        'linha_digitavel',
        'digitLine',
      ]),
      codigoBarras: pick([
        'codigoBarras',
        'codigo_barras',
        'barcode',
        'barCode',
      ]),
      pixQrCodeBase64: pick([
        'pixQrCodeBase64',
        'pix_qr_code_base64',
        'pixQrCode',
        'qrCodePixBase64',
      ]),
      pixCopiaCola: pick([
        'pixCopiaCola',
        'pix_copia_cola',
        'pixPayload',
        'pix_payload',
        'pixCode',
        'pix_code',
      ]),
      txid: pick(['txid']),
      nossoNumero: pick(['nossoNumero', 'nosso_numero']),
      referenciaExterna: pick(['referenciaExterna', 'referencia_externa']),
      observacao: pick(['observacao', 'observation']),
      etapaRegua: pick(['etapaRegua', 'etapa_regua']),
      reguaStatus: pick(['reguaStatus', 'regua_status']),
      canalEnvio: pick(['canalEnvio', 'canal_envio']),
      proximoEnvioEm: pickDate(['proximoEnvioEm', 'proximo_envio_em']),
      ultimoEnvioEm: pickDate(['ultimoEnvioEm', 'ultimo_envio_em']),
      quantidadeEnvios: pickInt(['quantidadeEnvios', 'quantidade_envios']) ?? 0,
      ultimoErroEnvio: pick(['ultimoErroEnvio', 'ultimo_erro_envio']),
    );
  }

  bool get hasBoleto =>
      boletoAvailable ||
      (linkCobranca?.isNotEmpty ?? false) ||
      (boletoLink?.isNotEmpty ?? false) ||
      (linhaDigitavel?.isNotEmpty ?? false) ||
      (codigoBarras?.isNotEmpty ?? false);

  bool get hasPix =>
      pixAvailable ||
      (pixQrCodeBase64?.isNotEmpty ?? false) ||
      (pixCopiaCola?.isNotEmpty ?? false);
}

class BillingChargeException implements Exception {
  final String message;

  const BillingChargeException(this.message);

  @override
  String toString() => message;
}
