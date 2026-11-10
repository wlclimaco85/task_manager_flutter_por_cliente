import 'dart:convert';

import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import '../utils/nfse_faturar_utils.dart';
import '../utils/tenant_context.dart';

/// Falha do faturamento com a mensagem completa para exibir/copiar no popUp.
class NfseFaturarException implements Exception {
  final String mensagem;
  const NfseFaturarException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Chamadas HTTP da acao "Faturar" da tela de NFS-e.
class NfseFaturarService {
  const NfseFaturarService._();

  /// Valor mensal do tomador, já faturado na competência e saldo.
  static Future<Map<String, dynamic>> resumo({
    required int tomadorId,
    required int mes,
    required int ano,
  }) async {
    try {
      final r = await TenantContext.get(
          ApiLinks.nfseFaturarResumo(tomadorId, mes, ano));
      if (r.statusCode != 200) {
        throw NfseFaturarException(nfseMensagemErroHttp(r.statusCode, r.body));
      }
      final corpo = jsonDecode(r.body);
      return corpo is Map<String, dynamic> ? corpo : <String, dynamic>{};
    } on NfseFaturarException {
      rethrow;
    } catch (e, st) {
      AppLogger.i.error('Faturar NFS-e: erro ao consultar resumo do tomador '
          '$tomadorId ($mes/$ano): $e', st);
      throw NfseFaturarException('Falha ao consultar o valor mensal: $e');
    }
  }

  /// Dispara o faturamento. Em qualquer erro nada foi gravado no backend (rollback total).
  static Future<NfseFaturarResultado> faturar({
    required int tomadorId,
    required int serieId,
    required int produtoId,
    required int mes,
    required int ano,
    required double valor,
    int? emissorParceiroId,
  }) async {
    try {
      final r = await TenantContext.post(ApiLinks.nfseFaturar, {
        'tomadorId': tomadorId,
        'serieId': serieId,
        'produtoId': produtoId,
        'mesReferencia': mes,
        'anoReferencia': ano,
        'valor': valor,
        if (emissorParceiroId != null) 'emissorParceiroId': emissorParceiroId,
      });
      if (r.statusCode != 200 && r.statusCode != 201) {
        final msg = nfseMensagemErroHttp(r.statusCode, r.body);
        AppLogger.i.warn('Faturar NFS-e recusado (HTTP ${r.statusCode}) '
            'tomador=$tomadorId $mes/$ano: $msg');
        throw NfseFaturarException(msg);
      }
      final corpo = jsonDecode(r.body);
      if (corpo is! Map<String, dynamic>) {
        throw const NfseFaturarException('Resposta inesperada do servidor.');
      }
      return NfseFaturarResultado.fromJson(corpo);
    } on NfseFaturarException {
      rethrow;
    } catch (e, st) {
      AppLogger.i.error('Faturar NFS-e: erro de comunicacao tomador=$tomadorId '
          '$mes/$ano: $e', st);
      throw NfseFaturarException('Falha de comunicação ao faturar: $e');
    }
  }

  /// Séries de NFS-e (tabela nfe_serie, tipo NFS-e) da empresa logada.
  static Future<List<Map<String, dynamic>>> series() async {
    final empId = TenantContext.empresaId;
    final url = '${ApiLinks.baseUrl}/api/nfe-serie?tamanho=100'
        '${empId != null ? '&empId=$empId' : ''}';
    final lista = await _lista(url, 'series de NFS-e');
    return lista.where((s) {
      final tipo =
          s['tipo']?.toString().trim().replaceAll('_', '-').toUpperCase();
      return tipo == 'NFS-E' || tipo == 'NFSE';
    }).map((s) {
      final serie = s['serie']?.toString().trim() ?? '';
      final descricao = s['descricao']?.toString().trim() ?? '';
      return <String, dynamic>{
        'id': s['id']?.toString() ?? '',
        'nome': descricao.isNotEmpty ? '$serie - $descricao' : serie,
      };
    }).toList();
  }

  /// Produtos marcados como serviço da empresa logada.
  static Future<List<Map<String, dynamic>>> servicos() async {
    final empId = TenantContext.empresaId;
    final url = '${ApiLinks.baseUrl}/api/produto-contabil?tamanho=500'
        '${empId != null ? '&empId=$empId' : ''}&isServico=true';
    final lista = await _lista(url, 'servicos');
    return lista
        .map((p) => <String, dynamic>{
              'id': p['id']?.toString() ?? '',
              'nome': p['nome']?.toString() ?? 'Serviço ${p['id']}',
            })
        .where((p) => (p['id'] as String).isNotEmpty)
        .toList();
  }

  static Future<List<Map<String, dynamic>>> _lista(
      String url, String descricao) async {
    try {
      final r = await TenantContext.get(url);
      if (r.statusCode != 200) {
        AppLogger.i.warn('Faturar NFS-e: HTTP ${r.statusCode} ao listar $descricao');
        throw NfseFaturarException(
            'Não foi possível carregar $descricao (HTTP ${r.statusCode}).');
      }
      final b = jsonDecode(r.body);
      List raw = [];
      if (b is List) {
        raw = b;
      } else if (b is Map) {
        final data = b['data'];
        if (data is List) {
          raw = data;
        } else if (data is Map) {
          raw = data['dados'] ?? data['content'] ?? data['items'] ?? [];
        } else {
          raw = b['dados'] ?? b['content'] ?? b['items'] ?? [];
        }
      }
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on NfseFaturarException {
      rethrow;
    } catch (e, st) {
      AppLogger.i.error('Faturar NFS-e: erro ao listar $descricao: $e', st);
      throw NfseFaturarException('Falha ao carregar $descricao: $e');
    }
  }
}
