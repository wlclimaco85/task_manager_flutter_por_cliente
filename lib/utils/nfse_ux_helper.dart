import 'dart:convert';

class NfseUxHelper {
  const NfseUxHelper._();

  static const _codigoServicoMunicipalKeys = [
    'codigoServicoMunicipal',
    'codigo_servico_municipal',
    'codigoServico',
    'codigo_servico',
    'ibge',
  ];

  static String? resolveCodigoServicoMunicipal(Map<String, dynamic>? cidade) {
    if (cidade == null) return null;
    for (final chave in _codigoServicoMunicipalKeys) {
      final texto = cidade[chave]?.toString().trim();
      if (texto != null && texto.isNotEmpty) return texto;
    }
    return null;
  }

  static List<String> validarDadosMunicipais({
    required String municipio,
    required String codigoTributacao,
    String? descricaoServico,
    double? valor,
    double? aliquotaIss,
  }) {
    final erros = <String>[];
    if (_isBlank(municipio)) erros.add('Município de Prestação');
    if (_isBlank(codigoTributacao)) {
      erros.add('Código de Tributação Municipal');
    }
    if (descricaoServico != null && _isBlank(descricaoServico)) {
      erros.add('Descrição do Serviço');
    }
    if (valor != null && valor <= 0) erros.add('Valor do Serviço');
    if (aliquotaIss != null && aliquotaIss <= 0) erros.add('Alíquota ISS');
    return erros;
  }

  static String statusPrefeituraLabel(dynamic status) {
    final texto = status?.toString().trim().toUpperCase() ?? '';
    if (texto.isEmpty || texto == 'PENDENTE') return 'Pendente de envio';
    // BUG produção (card #504): os adaptadores reais de município
    // (SaoPauloMunicipioAdapter/BrasiliaMunicipioAdapter, em
    // AppAcademia/src/main/java/br/com/model/fiscal/MunicipioAdapter.java)
    // retornam status em INGLÊS -- ISSUED/AUTHORIZED/CANCELLED/CONTINGENCY
    // -- que nunca batiam com nenhum dos "contains" em português abaixo.
    // "CANCELLED" nem sequer contém "CANCELAD" (grafia com LL dobrado em
    // inglês), por isso precisa de checagem explícita, não só um novo
    // "contains".
    if (texto == 'ISSUED' || texto == 'AUTHORIZED') {
      return 'Autorizada pela prefeitura';
    }
    if (texto == 'CANCELLED') return 'Cancelada na prefeitura';
    // Ambas as grafias: "CONTINGENCY" (adaptador real, em inglês) e
    // "CONTINGENCIA" (SafeMockAdapter, em português) -- nenhuma batia com
    // os "contains" abaixo antes desta checagem explícita.
    if (texto == 'CONTINGENCY' || texto == 'CONTINGENCIA') {
      return 'Emitida em contingência';
    }
    if (texto.contains('AUTORIZAD') ||
        texto.contains('EMITID') ||
        texto.contains('APROVAD')) {
      return 'Autorizada pela prefeitura';
    }
    if (texto.contains('CANCELAD')) return 'Cancelada na prefeitura';
    if (texto.contains('REJEIT') ||
        texto.contains('ERRO') ||
        texto.contains('FALHA')) {
      return 'Rejeitada pela prefeitura';
    }
    if (texto.contains('PROCESS') ||
        texto.contains('ENVIAD') ||
        texto.contains('ANALISE') ||
        texto.contains('RETORNO')) {
      return 'Aguardando retorno da prefeitura';
    }
    return status.toString();
  }

  static String retornoPrefeitura(Map<String, dynamic> result) {
    final status = result['status'] ?? result['situacao'];
    final linhas = [
      'NFS-e enviada para a prefeitura',
      'Status: ${statusPrefeituraLabel(status)}',
      'Número: ${_value(result['numero'] ?? result['nfseNumber'])}',
      'Protocolo: ${_value(result['protocolo'] ?? result['protocol'])}',
    ];
    final motivo = result['motivoRejeicao'] ??
        result['motivo'] ??
        result['mensagem'] ??
        result['message'];
    if (!_isBlank(motivo)) linhas.add('Retorno: ${motivo.toString().trim()}');
    final chave = result['chave'] ?? result['chaveAcesso'];
    if (!_isBlank(chave)) linhas.add('Chave: ${chave.toString().trim()}');
    return linhas.join('\n');
  }

  static String erroValidacaoMunicipal(List<String> campos) {
    return 'Dados municipais obrigatórios: ${campos.join(', ')}.';
  }

  static String readableHttpError(
      int statusCode, String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      final message = _extractMessage(decoded);
      if (!_isBlank(message)) return message.toString();
    } catch (_) {}
    return '$fallback (status $statusCode)';
  }

  static dynamic _extractMessage(dynamic decoded) {
    if (decoded is Map) {
      for (final key in [
        'mensagem',
        'message',
        'error',
        'motivoRejeicao',
        'motivo',
        'descricao',
        'detail',
        'details',
      ]) {
        final value = decoded[key];
        if (!_isBlank(value)) return value;
      }
      final data = decoded['data'];
      final nested = _extractMessage(data);
      if (!_isBlank(nested)) return nested;
    }
    return null;
  }

  static bool _isBlank(dynamic value) =>
      value == null || value.toString().trim().isEmpty;

  static String _value(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? '-' : text;
  }
}
