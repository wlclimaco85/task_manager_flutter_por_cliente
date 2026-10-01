import 'package:hive/hive.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

/// Repository que gerencia cache local de NFes usando Hive
///
/// Responsabilidades:
/// - Persistir NFes localmente (offline)
/// - Limpar cache antigo (>90 dias)
/// - Fila offline para transmissões futuras
/// - Verificação TTL (30 minutos)
class NfeLocalRepository {
  static const int _maxCacheSize = 1000;
  static const int _cacheTtlMinutes = 30;
  static const int _cacheExpireDays = 90;

  final Box<NfeModel> boxNfe;

  NfeLocalRepository({required this.boxNfe});

  /// Cacheia lista de NFes, limpando antigas primeiro
  Future<void> cacheNfes(List<NfeModel> nfes) async {
    try {
      L.d('[NfeLocalRepository] Cacheando ${nfes.length} NFes');

      // Limpa cache antigo
      await limparCacheAntigo();

      // Armazena novas
      for (final nfe in nfes) {
        await boxNfe.put(nfe.id, nfe);
      }

      L.d('[NfeLocalRepository] ${nfes.length} NFes cacheadas com sucesso');
    } catch (e) {
      L.e('[NfeLocalRepository] Erro ao cachear NFes: $e');
      rethrow;
    }
  }

  /// Obtém todas as NFes do cache
  Future<List<NfeModel>> obterTodosCached() async {
    try {
      final nfes = boxNfe.values.toList();
      L.d('[NfeLocalRepository] Obtendo ${nfes.length} NFes do cache');
      return nfes;
    } catch (e) {
      L.e('[NfeLocalRepository] Erro ao obter todos do cache: $e');
      return [];
    }
  }

  /// Obtém uma NFe específica do cache
  Future<NfeModel?> obterCached(int id) async {
    try {
      final nfe = boxNfe.get(id);
      if (nfe != null) {
        L.d('[NfeLocalRepository] Obteve NFe $id do cache');
      }
      return nfe;
    } catch (e) {
      L.e('[NfeLocalRepository] Erro ao obter NFe $id do cache: $e');
      return null;
    }
  }

  /// Limpa todo o cache
  Future<void> limparCache() async {
    try {
      await boxNfe.clear();
      L.d('[NfeLocalRepository] Cache limpado completamente');
    } catch (e) {
      L.e('[NfeLocalRepository] Erro ao limpar cache: $e');
      rethrow;
    }
  }

  /// Limpa NFes com mais de 90 dias de criação
  Future<void> limparCacheAntigo() async {
    try {
      final agora = DateTime.now();
      final entries = boxNfe.toMap().entries.toList();
      int deleted = 0;

      for (final entry in entries) {
        final nfe = entry.value;
        final diasAtras = agora.difference(nfe.criadoEm).inDays;

        if (diasAtras > _cacheExpireDays) {
          await entry.key.delete();
          deleted++;
        }
      }

      if (deleted > 0) {
        L.d('[NfeLocalRepository] Deletou $deleted NFes antigas (>$_cacheExpireDays dias)');
      }
    } catch (e) {
      L.e('[NfeLocalRepository] Erro ao limpar cache antigo: $e');
      // Não faz rethrow para não interromper sync
    }
  }

  /// Retorna estatísticas do cache
  Future<Map<String, dynamic>> getSizeStats() async {
    try {
      final count = boxNfe.length;
      final isLimitExceeded = count > _maxCacheSize;

      return {
        'count': count,
        'maxSize': _maxCacheSize,
        'isLimitExceeded': isLimitExceeded,
      };
    } catch (e) {
      L.e('[NfeLocalRepository] Erro ao obter stats: $e');
      return {'count': 0, 'maxSize': _maxCacheSize, 'isLimitExceeded': false};
    }
  }

  /// Verifica se cache é válido (TTL de 30 min)
  Future<bool> isCacheValid() async {
    try {
      if (boxNfe.isEmpty) {
        return false;
      }

      // Usa a NFe mais recente como referência
      final nfes = boxNfe.values.toList();
      if (nfes.isEmpty) {
        return false;
      }

      nfes.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
      final maisRecente = nfes.first;

      final minutosAtras =
          DateTime.now().difference(maisRecente.criadoEm).inMinutes;

      final isValid = minutosAtras < _cacheTtlMinutes;
      L.d('[NfeLocalRepository] Cache válido? $isValid (${minutosAtras}min)');

      return isValid;
    } catch (e) {
      L.e('[NfeLocalRepository] Erro ao verificar validade cache: $e');
      return false;
    }
  }

  /// Adiciona NFe à fila de transmissão offline
  Future<void> addToOfflineQueue(NfeModel nfe) async {
    try {
      final boxQueue = await _getOfflineQueueBox();
      await boxQueue.add(nfe);
      L.d('[NfeLocalRepository] NFe ${nfe.id} adicionada à fila offline');
    } catch (e) {
      L.e('[NfeLocalRepository] Erro ao adicionar NFe à fila offline: $e');
      rethrow;
    }
  }

  /// Obtém fila de NFes offline
  Future<List<NfeModel>> getOfflineQueue() async {
    try {
      final boxQueue = await _getOfflineQueueBox();
      final queue = boxQueue.values.toList();
      L.d('[NfeLocalRepository] Obtendo fila offline: ${queue.length} NFes');
      return queue;
    } catch (e) {
      L.e('[NfeLocalRepository] Erro ao obter fila offline: $e');
      return [];
    }
  }

  /// Limpa fila de transmissão offline
  Future<void> clearOfflineQueue() async {
    try {
      final boxQueue = await _getOfflineQueueBox();
      await boxQueue.clear();
      L.d('[NfeLocalRepository] Fila offline limpa');
    } catch (e) {
      L.e('[NfeLocalRepository] Erro ao limpar fila offline: $e');
      rethrow;
    }
  }

  /// Obtém ou cria box para fila offline
  Future<Box<NfeModel>> _getOfflineQueueBox() async {
    try {
      if (Hive.isBoxOpen('nfe_queue_offline')) {
        return Hive.box<NfeModel>('nfe_queue_offline');
      }
      return await Hive.openBox<NfeModel>('nfe_queue_offline');
    } catch (e) {
      L.e('[NfeLocalRepository] Erro ao abrir box fila offline: $e');
      rethrow;
    }
  }

  /// Remove NFe específica do cache
  Future<void> removerDoCached(int id) async {
    try {
      await boxNfe.delete(id);
      L.d('[NfeLocalRepository] NFe $id removida do cache');
    } catch (e) {
      L.e('[NfeLocalRepository] Erro ao remover NFe $id: $e');
      rethrow;
    }
  }

  /// Verifica se NFe está em cache
  Future<bool> estEmCache(int id) async {
    try {
      return boxNfe.containsKey(id);
    } catch (e) {
      L.e('[NfeLocalRepository] Erro ao verificar se em cache: $e');
      return false;
    }
  }
}
