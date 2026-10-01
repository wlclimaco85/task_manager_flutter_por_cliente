import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/services/nfse_caller.dart';

void main() {
  group('NfseCaller', () {
    test('monta payload de emissao com contrato aceito pelo backend', () {
      final body = NfseCaller.buildEmitirBody(
        municipio: 'Uberlandia',
        cnpjTomador: '12345678000190',
        nomeTomador: 'Tomador Teste',
        descricaoServico: 'Servico de teste',
        valor: 150,
        aliquotaIss: 2,
        cnae: '6201501',
        codigoTributacao: '01.01',
        empresaId: '1',
        nfseId: 500,
      );

      expect(body['municipio'], 'Uberlandia');
      expect(body['tomadorCnpj'], '12345678000190');
      expect(body['tomadorNome'], 'Tomador Teste');
      expect(body['servicoDescricao'], 'Servico de teste');
      expect(body['valor'], 150);
      expect(body['aliquotaIss'], 2);
      expect(body['cnae'], '6201501');
      expect(body['codTributacao'], '01.01');
      expect(body['empresaId'], 1);
      expect(body['nfseId'], 500);
      expect(body, isNot(contains('cnpjTomador')));
      expect(body, isNot(contains('nomeTomador')));
      expect(body, isNot(contains('descricaoServico')));
      expect(body, isNot(contains('codigoTributacao')));
    });

    test('monta payload de cancelamento com nfseId do registro real', () {
      final body = NfseCaller.buildCancelarBody(
        numero: '1001',
        motivo: 'Cancelamento solicitado pelo usuario',
        empresaId: '1',
        municipio: 'Uberlandia',
        nfseId: 501,
      );

      expect(body['nfseNumber'], '1001');
      expect(body['motivo'], 'Cancelamento solicitado pelo usuario');
      expect(body['empresaId'], 1);
      expect(body['municipio'], 'Uberlandia');
      expect(body['nfseId'], 501);
      expect(body, isNot(contains('numero')));
    });
  });
}
