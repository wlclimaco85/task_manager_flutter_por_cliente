import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:task_manager_flutter/models/certificado/certificado_local_cache_model.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

/// Cache seguro de METADADO do certificado A1 local (card W3R3, item B).
///
/// Usa `flutter_secure_storage` (Keychain/Keystore no mobile, DPAPI no
/// Windows) — mesmo não guardando dado ultra-sensível, evita persistir o
/// metadado do certificado em texto plano em disco. Não guarda arquivo
/// .pfx/.p12 nem senha: ver `CertificadoLocalCacheModel` para o racional
/// completo dessa decisão de escopo.
class CertificadoLocalCacheService {
  final FlutterSecureStorage _storage;

  CertificadoLocalCacheService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  String _chave({int? empresaId, int? parceiroId}) =>
      'certificado_local_cache_emp${empresaId ?? '-'}_par${parceiroId ?? '-'}';

  Future<void> salvarCache(
    List<CertificadoLocalCacheModel> certificados, {
    int? empresaId,
    int? parceiroId,
  }) async {
    try {
      final chave = _chave(empresaId: empresaId, parceiroId: parceiroId);
      final json = jsonEncode(certificados.map((c) => c.toJson()).toList());
      await _storage.write(key: chave, value: json);
      L.d('[CertificadoLocalCacheService] Cache salvo ($chave): ${certificados.length} certificado(s)');
    } catch (e) {
      L.e('[CertificadoLocalCacheService] Erro ao salvar cache: $e');
    }
  }

  Future<List<CertificadoLocalCacheModel>> obterCache({
    int? empresaId,
    int? parceiroId,
  }) async {
    try {
      final chave = _chave(empresaId: empresaId, parceiroId: parceiroId);
      final json = await _storage.read(key: chave);
      if (json == null || json.isEmpty) return [];
      final lista = jsonDecode(json) as List;
      return lista
          .map((e) =>
              CertificadoLocalCacheModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      L.e('[CertificadoLocalCacheService] Erro ao ler cache: $e');
      return [];
    }
  }

  Future<void> limparCache({int? empresaId, int? parceiroId}) async {
    final chave = _chave(empresaId: empresaId, parceiroId: parceiroId);
    await _storage.delete(key: chave);
  }
}
