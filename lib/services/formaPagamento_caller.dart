import '../../../models/forma_pagamento_model.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../utils/api_links.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
class FormaPagamentoCaller {
  // Cache estático para dropdown
  static List<Map<String, dynamic>>? _dropdownCache;
  static DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(minutes: 5);

  /// 🔹 Limpa o cache de dropdown (chamar após criar/atualizar/deletar)
  static void clearCache() {
    _dropdownCache = null;
    _cacheTimestamp = null;
    L.d('Cache de FormaPagamento limpo');
  }

  /// 🔹 Busca e retorna a lista de objetos FormaPagamento
  Future<List<FormaPagamento>> fetchAllFormasPagamento() async {
    List<FormaPagamento> list = [];
    try {
      final NetworkResponse response = await NetworkCaller().getRequest(
        ApiLinks.allFormasPagamento,
      );

      if (response.isSuccess && response.body != null) {
        final data = response.body!['data']['dados'] ?? [];
        list = (data as List)
            .map((item) => FormaPagamento.fromJson(item))
            .toList();
      }
    } catch (e) {
      L.d('Erro ao carregar formas de pagamento: $e');
      throw Exception('Erro ao carregar formas de pagamento: $e');
    }
    return list;
  }

  /// 🔹 Usa fetchAllFormasPagamento e converte para lista de Map (com cache)
  Future<List<Map<String, dynamic>>> fetchFormasPagamentoDropDown() async {
    // Verifica se cache é válido
    if (_dropdownCache != null && _cacheTimestamp != null) {
      final cacheAge = DateTime.now().difference(_cacheTimestamp!);
      if (cacheAge < _cacheDuration) {
        L.d('Usando cache de FormaPagamento (idade: ${cacheAge.inSeconds}s)');
        return _dropdownCache!;
      }
    }

    // Cache inválido ou expirado, busca novos dados
    final formasPagamento = await fetchAllFormasPagamento();
    _dropdownCache = formasPagamento
        .map((fp) => {'value': fp.id, 'label': fp.nome})
        .toList();
    _cacheTimestamp = DateTime.now();
    L.d('Cache de FormaPagamento atualizado (${_dropdownCache!.length} itens)');
    return _dropdownCache!;
  }
}
