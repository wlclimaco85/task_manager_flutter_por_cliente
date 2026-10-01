import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/nfce/nfce_config_fiscal_cache_model.dart';
import 'package:task_manager_flutter/utils/api_links.dart';

void main() {
  group('NFC-e config fiscal por cliente', () {
    test('URL sem cliente busca configuracao da empresa', () {
      final url = ApiLinks.configFiscal(1);

      expect(url, endsWith('/api/v1/fiscal/nfce/config/1'));
      expect(url, isNot(contains('parceiroId=')));
    });

    test('URL com cliente busca configuracao especifica do parceiro', () {
      final url = ApiLinks.configFiscal(1, parceiroId: 814);

      expect(url, endsWith('/api/v1/fiscal/nfce/config/1?parceiroId=814'));
    });

    test('cache separa empresa e cliente na chave local', () {
      expect(
        NfceConfigFiscalCacheModel.chave(empresaId: 1),
        equals('emp1_par-'),
      );
      expect(
        NfceConfigFiscalCacheModel.chave(empresaId: 1, parceiroId: 814),
        equals('emp1_par814'),
      );
    });

    test('cache preserva temCertificado e contingencia no round-trip json', () {
      final modelo = NfceConfigFiscalCacheModel(
        configId: 10,
        empresaId: 1,
        escopo: 'EMPRESA',
        uf: 'SP',
        ambiente: 'PRODUCAO',
        idCsc: 'abc123',
        csc: 'segredo',
        serieNfce: '001',
        contingenciaHabilitada: true,
        temCertificado: true,
        cacheadoEm: DateTime(2026, 1, 1),
      );

      final restaurado = NfceConfigFiscalCacheModel.fromJson(modelo.toJson());

      expect(restaurado.temCertificado, isTrue);
      expect(restaurado.contingenciaHabilitada, isTrue);
    });

    test('cache antigo sem flags booleanas assume false (compat retroativa)',
        () {
      final jsonAntigo = {
        'configId': 10,
        'empresaId': 1,
        'escopo': 'EMPRESA',
        'uf': 'SP',
        'ambiente': 'PRODUCAO',
        'idCsc': 'abc123',
        'csc': 'segredo',
        'serieNfce': '001',
        'cacheadoEm': DateTime(2026, 1, 1).toIso8601String(),
      };

      final restaurado = NfceConfigFiscalCacheModel.fromJson(jsonAntigo);

      expect(restaurado.temCertificado, isFalse);
      expect(restaurado.contingenciaHabilitada, isFalse);
    });
  });
}
