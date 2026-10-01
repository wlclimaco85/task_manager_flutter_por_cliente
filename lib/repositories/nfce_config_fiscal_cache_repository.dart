import 'package:hive/hive.dart';
import 'package:task_manager_flutter/models/nfce/nfce_config_fiscal_cache_model.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

/// Cache local (Hive) da config fiscal NFC-e por Empresa/Cliente.
///
/// Segue a mesma infraestrutura ja usada por NfeDraftRepository (box propria +
/// registro de adapter por typeId). Ao reabrir a ConfigFiscalScreen, se ja
/// existir cache para a combinacao empresaId+parceiroId atual, os campos vem
/// pre-preenchidos e desabilitados (leitura via obterCache).
class NfceConfigFiscalCacheRepository {
  static const String boxName = 'nfce_config_fiscal_cache';
  static bool _adapterRegistered = false;

  Future<Box<NfceConfigFiscalCacheModel>> _abrirBox() async {
    if (!_adapterRegistered && !Hive.isAdapterRegistered(43)) {
      Hive.registerAdapter(NfceConfigFiscalCacheModelAdapter());
      _adapterRegistered = true;
    }
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<NfceConfigFiscalCacheModel>(boxName);
    }
    return Hive.openBox<NfceConfigFiscalCacheModel>(boxName);
  }

  Future<void> salvarCache(NfceConfigFiscalCacheModel config) async {
    try {
      final box = await _abrirBox();
      await box.put(config.chaveInstancia, config);
      L.d('[NfceConfigFiscalCacheRepository] Cache salvo (' +
          config.chaveInstancia +
          ')');
    } catch (e) {
      L.e('[NfceConfigFiscalCacheRepository] Erro ao salvar cache: ' +
          e.toString());
    }
  }

  Future<NfceConfigFiscalCacheModel?> obterCache({
    required int empresaId,
    int? parceiroId,
  }) async {
    try {
      final box = await _abrirBox();
      final chave = NfceConfigFiscalCacheModel.chave(
        empresaId: empresaId,
        parceiroId: parceiroId,
      );
      return box.get(chave);
    } catch (e) {
      L.e('[NfceConfigFiscalCacheRepository] Erro ao ler cache: ' +
          e.toString());
      return null;
    }
  }

  Future<void> limparCache({required int empresaId, int? parceiroId}) async {
    final box = await _abrirBox();
    final chave = NfceConfigFiscalCacheModel.chave(
      empresaId: empresaId,
      parceiroId: parceiroId,
    );
    await box.delete(chave);
  }
}
