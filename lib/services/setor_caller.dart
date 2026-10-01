import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../utils/api_links.dart';

import '../models/setor_model.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

class SetorCaller {
  List<Setor> _extrairListaSetores(dynamic body) {
    if (body == null) return [];
    if (body is List) {
      return body
          .map((item) {
            if (item is Map<String, dynamic>) {
              return Setor.fromJson(item);
            } else if (item is Map) {
              return Setor.fromJson(Map<String, dynamic>.from(item));
            }
            return null;
          })
          .whereType<Setor>()
          .toList();
    }
    if (body is Map) {
      final rawData =
          body['data'] ?? body['content'] ?? body['dados'] ?? body['items'];
      if (rawData is List) {
        return _extrairListaSetores(rawData);
      }
      if (rawData is Map) {
        final rawInner =
            rawData['dados'] ?? rawData['content'] ?? rawData['items'];
        if (rawInner is List) {
          return _extrairListaSetores(rawInner);
        }
      }
    }
    return [];
  }

  Future<List<Setor>> fetchAllSetores() async {
    List<Setor> list = [];
    try {
      final NetworkResponse response = await NetworkCaller().getRequest(
        ApiLinks.allSetores,
      );

      if (response.isSuccess && response.body != null) {
        list = _extrairListaSetores(response.body);
      }
    } catch (e) {
      L.d('Erro ao carregar setores: $e');
      throw Exception('Erro ao carregar setores: $e');
    }
    return list;
  }

  Future<List<Map<String, dynamic>>> fetchSetorDropdown() async {
    final setores = await fetchAllSetores();
    return setores.map((s) => {'value': s.id, 'label': s.nome}).toList();
  }

  Future<List<Setor>> fetchSetoresDoLogin(int loginId) async {
    List<Setor> list = [];
    try {
      final NetworkResponse response = await NetworkCaller().getRequest(
        ApiLinks.getSetoresLoginId(loginId),
      );
      if (response.isSuccess && response.body != null) {
        list = _extrairListaSetores(response.body);
      }
    } catch (e) {
      L.d('Erro ao carregar setores do login $loginId via getSetoresLoginId: $e');
    }

    if (list.isEmpty) {
      try {
        final NetworkResponse responseAlt = await NetworkCaller().getRequest(
          '${ApiLinks.allSetores}?loginId=$loginId',
        );
        if (responseAlt.isSuccess && responseAlt.body != null) {
          list = _extrairListaSetores(responseAlt.body);
        }
      } catch (e) {
        L.d('Erro ao carregar setores do login $loginId via allSetores?loginId: $e');
      }
    }

    return list;
  }

  Future<bool> associarSetorAoLogin(int loginId, int setorId) async {
    try {
      final NetworkResponse response = await NetworkCaller().postRequest(
        ApiLinks.associateSetorToLogin(loginId, setorId),
        {},
      );
      return response.isSuccess;
    } catch (e) {
      L.d('Erro ao associar setor $setorId ao login $loginId: $e');
      return false;
    }
  }

  Future<bool> removerSetorDoLogin(int loginId, int setorId) async {
    try {
      final NetworkResponse response = await NetworkCaller().deleteRequest(
        ApiLinks.removeSetorFromLogin(loginId, setorId),
      );
      return response.isSuccess;
    } catch (e) {
      L.d('Erro ao remover setor $setorId do login $loginId: $e');
      return false;
    }
  }

  Future<bool> atualizarSetoresDoLogin(int loginId, List<int> setorIds) async {
    try {
      final NetworkResponse response = await NetworkCaller().putRequest(
        ApiLinks.updateSetoresLoginId(loginId),
        setorIds,
      );
      if (response.isSuccess) return true;
    } catch (e) {
      L.d('Erro ao atualizar setores do login $loginId via PUT: $e');
    }

    // Fallback sequencial seguro caso o PUT falhe ou nao esteja disponivel
    try {
      final atuais = await fetchSetoresDoLogin(loginId);
      final idsAtuais =
          atuais.where((s) => s.id != null).map((s) => s.id!).toSet();
      final novos = setorIds.toSet();

      final paraAdicionar = novos.difference(idsAtuais);
      final paraRemover = idsAtuais.difference(novos);

      bool ok = true;
      for (final id in paraAdicionar) {
        final res = await associarSetorAoLogin(loginId, id);
        if (!res) ok = false;
      }
      for (final id in paraRemover) {
        final res = await removerSetorDoLogin(loginId, id);
        if (!res) ok = false;
      }
      return ok;
    } catch (e) {
      L.d('Erro no fallback de sincronizacao de setores: $e');
      return false;
    }
  }
}
