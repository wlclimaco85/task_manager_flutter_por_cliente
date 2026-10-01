import 'dart:convert';

class NfeEmissionPayload {
  static const authorizedStatus = 'AUTORIZADA';
  static const canceledStatus = 'CANCELADA';

  /// DANFE/XML só existem de fato (blob salvo) a partir do momento em que a
  /// NF-e é autorizada pela SEFAZ -- inclui notas já canceladas depois
  /// (cancelamento só é permitido para nota que já estava AUTORIZADA, o XML
  /// autorizado continua existindo e precisa continuar consultável).
  static bool isAuthorized(String? status) {
    final normalized = status?.trim().toUpperCase();
    return normalized == authorizedStatus || normalized == canceledStatus;
  }

  static List<String> validate({
    required String? empresaId,
    required String? destinatarioId,
    required String? serie,
    required String? numero,
    required String? finalidade,
    required List<Map<String, dynamic>> itens,
  }) {
    final errors = <String>[];
    if (_isBlank(empresaId)) errors.add('Empresa');
    if (_isBlank(destinatarioId)) errors.add('Destinatario');
    if (_isBlank(serie)) errors.add('Serie');
    if (_isBlank(numero)) errors.add('Numero');
    if (_isBlank(finalidade)) errors.add('Finalidade');
    if (itens.isEmpty) {
      errors.add('Itens');
    } else {
      for (var index = 0; index < itens.length; index++) {
        final itemErrors = _validateItem(itens[index]);
        if (itemErrors.isNotEmpty) {
          errors.add('Item ${index + 1}: ${itemErrors.join(', ')}');
        }
      }
    }
    return errors;
  }

  static Map<String, dynamic> build({
    required String empresaId,
    required String destinatarioId,
    required String serie,
    required String numero,
    required String finalidade,
    required List<Map<String, dynamic>> itens,
  }) {
    final payloadItens = itens.map(itemPayload).toList();
    final valorTotal = payloadItens.fold<double>(
      0,
      (total, item) => total + (_asDouble(item['vProd']) ?? 0),
    );

    return {
      'empresa_id': int.tryParse(empresaId) ?? empresaId,
      'destinatario_id': int.tryParse(destinatarioId) ?? destinatarioId,
      'serie': serie.trim(),
      'numero': numero.trim(),
      'finalidade': finalidade.trim(),
      'itens': payloadItens,
      'subtotal': valorTotal,
      'valorTotal': valorTotal,
    };
  }

  static Map<String, dynamic> itemPayload(Map<String, dynamic> item) {
    final qCom = _asDouble(item['q_com'] ?? item['qCom'] ?? item['quantidade']);
    final vUnCom =
        _asDouble(item['v_un_com'] ?? item['vUnCom'] ?? item['precoUnitario']);
    final vProd =
        _asDouble(item['v_prod'] ?? item['vProd'] ?? item['precoTotal']) ??
            ((qCom ?? 0) * (vUnCom ?? 0));

    return {
      'cProd': _stringValue(
        item['cProd'] ??
            item['codigoProduto'] ??
            item['codigo'] ??
            item['produto']?['codigo'] ??
            item['produto']?['id'] ??
            item['id'],
      ),
      'xProd': _stringValue(
        item['x_prod'] ??
            item['xProd'] ??
            item['descricao'] ??
            item['produto']?['nome'],
      ),
      'ncm': _stringValue(item['ncm']),
      'cfop': _stringValue(item['cfop']),
      'uCom': _stringValue(item['u_com'] ?? item['uCom'] ?? item['unidade']),
      'qCom': qCom,
      'vUnCom': vUnCom,
      'vProd': vProd,
      if (!_isBlank(item['cst_icms'] ?? item['cstIcms']))
        'cstIcms': _stringValue(item['cst_icms'] ?? item['cstIcms']),
      if (_asDouble(item['aliq_icms'] ?? item['aliqIcms']) != null)
        'aliqIcms': _asDouble(item['aliq_icms'] ?? item['aliqIcms']),
      if (_asDouble(item['v_bc_icms'] ?? item['vBcIcms']) != null)
        'vBcIcms': _asDouble(item['v_bc_icms'] ?? item['vBcIcms']),
      if (_asDouble(item['v_icms'] ?? item['vIcms']) != null)
        'vIcms': _asDouble(item['v_icms'] ?? item['vIcms']),
    };
  }

  static String readableHttpError(int statusCode, String body) {
    var fallback = 'Erro $statusCode';
    try {
      final decoded = jsonDecode(body);
      final message = _extractMessage(decoded);
      final sanitized = _sanitizeMessage(message);
      if (!_isBlank(sanitized)) return sanitized;
    } catch (_) {}
    return fallback;
  }

  static dynamic _extractMessage(dynamic decoded) {
    if (decoded is Map) {
      for (final key in [
        'message',
        'mensagem',
        'error',
        'motivoAut',
        'motivoRejeicao',
        'motivo',
        'descricao',
        'detail',
        'details',
      ]) {
        final value = decoded[key];
        if (!_isBlank(value)) return value;
      }
      final nested = _extractMessage(decoded['data']);
      if (!_isBlank(nested)) return nested;
    }
    return null;
  }

  static String _sanitizeMessage(dynamic value) {
    var text = value?.toString().trim() ?? '';
    if (text.isEmpty) return '';
    text = text.split(RegExp(r'\r?\n')).first.trim();
    text = text.replaceFirst(
      RegExp(r'^(?:[a-zA-Z_$][\w$]*\.)+[A-Za-z_$][\w$]*(?::\s*)?'),
      '',
    );
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  static List<String> _validateItem(Map<String, dynamic> item) {
    final payload = itemPayload(item);
    final errors = <String>[];
    if (_isBlank(payload['cProd'])) errors.add('codigo do produto');
    if (_isBlank(payload['xProd'])) errors.add('descricao');
    if (_isBlank(payload['ncm'])) errors.add('NCM');
    if (_isBlank(payload['cfop'])) errors.add('CFOP');
    if (_isBlank(payload['uCom'])) errors.add('unidade');
    if ((_asDouble(payload['qCom']) ?? 0) <= 0) errors.add('quantidade');
    if ((_asDouble(payload['vUnCom']) ?? 0) <= 0) {
      errors.add('valor unitario');
    }
    return errors;
  }

  static bool _isBlank(dynamic value) =>
      value == null || value.toString().trim().isEmpty;

  static String _stringValue(dynamic value) =>
      value == null ? '' : value.toString().trim();

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    final normalized = text.contains(',')
        ? text.replaceAll('.', '').replaceAll(',', '.')
        : text;
    return double.tryParse(normalized);
  }
}
