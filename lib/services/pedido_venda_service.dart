import 'dart:convert';
import '../../../utils/api_links.dart';
import '../../services/network_caller.dart';
import '../models/pedido_venda_model.dart';
import '../utils/tenant_context.dart';

class PedidoVendaService {
  static Future<List<Map<String, dynamic>>> fetchAll({
    String? status,
    String? cliente,
    String? dataInicio,
    String? dataFim,
  }) async {
    try {
      String url = ApiLinks.pedidosVenda;
      final params = <String, String>{};
      if (status != null && status != 'Todos') params['status'] = status;
      if (cliente != null && cliente.isNotEmpty) params['cliente'] = cliente;
      if (dataInicio != null) params['dataInicio'] = dataInicio;
      if (dataFim != null) params['dataFim'] = dataFim;
      if (params.isNotEmpty) {
        final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
        url = '$url?$query';
      }
      final response = await NetworkCaller().getRequest(url);
      if (response.isSuccess && response.body != null) {
        final data = response.body!['data']?['dados'] ?? response.body!['data'] ?? [];
        if (data is List) {
          return data.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> fetchById(int id) async {
    try {
      final response = await NetworkCaller().getRequest(ApiLinks.pedidoVendaById(id.toString()));
      if (response.isSuccess && response.body != null) {
        return response.body!['data'] ?? response.body;
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> create(Map<String, dynamic> data) async {
    try {
      final response = await NetworkCaller().postRequest(ApiLinks.pedidosVenda, data);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> update(int id, Map<String, dynamic> data) async {
    try {
      final response = await NetworkCaller().putRequest(ApiLinks.pedidoVendaById(id.toString()), data);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> aprovar(int id) async {
    try {
      final response = await NetworkCaller().postRequest(ApiLinks.aprovarPedidoVenda(id.toString()), null);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> rejeitar(int id) async {
    try {
      final response = await NetworkCaller().postRequest(ApiLinks.rejeitarPedidoVenda(id.toString()), null);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> faturarParcial(int id, Map<String, dynamic> data) async {
    try {
      final response = await NetworkCaller().postRequest(ApiLinks.faturarParcialPedidoVenda(id.toString()), data);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> faturarTotal(int id) async {
    try {
      final response = await NetworkCaller().postRequest(ApiLinks.faturarTotalPedidoVenda(id.toString()), null);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> cancelar(int id) async {
    try {
      final response = await NetworkCaller().postRequest(ApiLinks.cancelarPedidoVenda(id.toString()), null);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> criarDeOrcamento(int orcamentoId) async {
    try {
      final response = await NetworkCaller().postRequest(ApiLinks.criarPedidoVendaDeOrcamento(orcamentoId.toString()), null);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<List<PedidoVendaItem>> fetchItens(int pedidoId) async {
    try {
      final response = await TenantContext.get(ApiLinks.pedidoVendaItens(pedidoId));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> raw = [];
        if (body is List) {
          raw = body;
        } else if (body is Map) {
          raw = body['data'] ?? body['dados'] ?? body['itens'] ?? [];
        }
        return raw.whereType<Map>().map((e) => PedidoVendaItem.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<PedidoVendaHistorico>> fetchHistorico(int pedidoId) async {
    try {
      final response = await TenantContext.get(ApiLinks.pedidoVendaHistorico(pedidoId));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> raw = [];
        if (body is List) {
          raw = body;
        } else if (body is Map) {
          raw = body['data'] ?? body['dados'] ?? body['historico'] ?? [];
        }
        return raw.whereType<Map>().map((e) => PedidoVendaHistorico.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } catch (_) {}
    return [];
  }
}
