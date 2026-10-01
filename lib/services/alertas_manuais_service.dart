import 'dart:convert';

import '../models/alerta_manual_model.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

abstract class AlertasManuaisRepository {
  Future<List<AlertaManual>> listar();
  Future<List<ParceiroAlertaOpcao>> listarParceiros();
  Future<ResultadoDisparoAlerta> disparar({
    required String texto,
    required List<int> parceiroIds,
  });
}

class AlertasManuaisService implements AlertasManuaisRepository {
  @override
  Future<List<AlertaManual>> listar() async {
    final response = await TenantContext.get(ApiLinks.alertasManuais);
    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar alertas (${response.statusCode})');
    }
    final body = jsonDecode(response.body);
    final raw = body is List ? body : <dynamic>[];
    return raw
        .whereType<Map>()
        .map((item) => AlertaManual.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<List<ParceiroAlertaOpcao>> listarParceiros() async {
    final response = await TenantContext.get(
      '${ApiLinks.allParceiros}?pagina=0&tamanho=200&semFiltroParceiro=true',
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar parceiros (${response.statusCode})');
    }
    final body = jsonDecode(response.body);
    final raw = _extrairLista(body);
    return raw
        .whereType<Map>()
        .map((item) =>
            ParceiroAlertaOpcao.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id > 0)
        .toList();
  }

  @override
  Future<ResultadoDisparoAlerta> disparar({
    required String texto,
    required List<int> parceiroIds,
  }) async {
    final response = await TenantContext.post(
      ApiLinks.alertasManuaisDisparar,
      {'texto': texto, 'parceiroIds': parceiroIds},
    );
    if (response.statusCode != 201) {
      throw Exception('Erro ao enviar alerta (${response.statusCode})');
    }
    return ResultadoDisparoAlerta.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body)),
    );
  }

  List<dynamic> _extrairLista(dynamic body) {
    if (body is List) return body;
    if (body is! Map) return const [];
    final data = body['data'];
    if (data is Map && data['dados'] is List) return data['dados'] as List;
    if (data is Map && data['content'] is List) return data['content'] as List;
    if (data is List) return data;
    if (body['dados'] is List) return body['dados'] as List;
    if (body['content'] is List) return body['content'] as List;
    return const [];
  }
}
