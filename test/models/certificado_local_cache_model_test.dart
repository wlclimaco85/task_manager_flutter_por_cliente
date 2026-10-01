import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/certificado/certificado_local_cache_model.dart';

/// Teste de serialização pura (sem plugin de plataforma) do modelo de cache
/// de metadado do certificado A1 (card W3R3, item B). Confirma que o modelo
/// carrega apenas metadado de exibição — nunca senha nem bytes do arquivo.
void main() {
  test('fromCertificadoApi extrai só metadado, nunca senha/arquivo do certificado',
      () {
    final apiResponse = {
      'id': 7,
      'nomeArquivo': 'empresa.pfx',
      'cnpjCert': '12345678000199',
      'validade': '2027-01-01',
      'statusValidade': 'VALIDO',
      'diasParaVencer': 120,
      'ativo': true,
      // Campos que NUNCA devem ser lidos/persistidos pelo cache local:
      'senha': 'segredo123',
      'arquivoBase64': 'AAAA....',
    };

    final model = CertificadoLocalCacheModel.fromCertificadoApi(
      apiResponse,
      empresaId: 5,
    );

    expect(model.id, 7);
    expect(model.nomeArquivo, 'empresa.pfx');
    expect(model.statusValidade, 'VALIDO');
    expect(model.ativo, isTrue);

    final json = model.toJson();
    expect(json.containsKey('senha'), isFalse);
    expect(json.containsKey('arquivoBase64'), isFalse);
    expect(json.keys, containsAll(['id', 'nomeArquivo', 'validade', 'statusValidade']));
  });

  test('round-trip toJson/fromJson preserva os campos', () {
    final original = CertificadoLocalCacheModel(
      id: 1,
      empresaId: 2,
      nomeArquivo: 'x.pfx',
      cnpjCert: '000',
      validade: '2026-12-31',
      statusValidade: 'VENCE_EM_BREVE',
      diasParaVencer: 10,
      ativo: false,
      cacheadoEm: DateTime(2026, 8, 11),
    );

    final restored = CertificadoLocalCacheModel.fromJson(original.toJson());

    expect(restored.id, original.id);
    expect(restored.empresaId, original.empresaId);
    expect(restored.statusValidade, original.statusValidade);
    expect(restored.diasParaVencer, original.diasParaVencer);
    expect(restored.ativo, original.ativo);
  });
}
