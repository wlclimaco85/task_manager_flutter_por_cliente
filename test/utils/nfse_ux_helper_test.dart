import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/nfse_ux_helper.dart';

void main() {
  group('NfseUxHelper', () {
    test('resolve codigo municipal por chaves conhecidas da cidade', () {
      expect(
        NfseUxHelper.resolveCodigoServicoMunicipal(
          {'codigoServicoMunicipal': '101'},
        ),
        '101',
      );
      expect(
        NfseUxHelper.resolveCodigoServicoMunicipal(
          {'codigo_servico_municipal': '202'},
        ),
        '202',
      );
      expect(
        NfseUxHelper.resolveCodigoServicoMunicipal({'ibge': 3170107}),
        '3170107',
      );
    });

    test('valida campos municipais obrigatorios antes de emitir', () {
      final erros = NfseUxHelper.validarDadosMunicipais(
        municipio: '',
        codigoTributacao: '',
        descricaoServico: '',
        valor: 0,
        aliquotaIss: 0,
      );

      expect(erros, contains('Município de Prestação'));
      expect(erros, contains('Código de Tributação Municipal'));
      expect(erros, contains('Descrição do Serviço'));
      expect(erros, contains('Valor do Serviço'));
      expect(erros, contains('Alíquota ISS'));
      expect(
        NfseUxHelper.erroValidacaoMunicipal(erros),
        contains('Dados municipais obrigatórios'),
      );
    });

    test('mapeia retorno da prefeitura em texto legivel', () {
      final texto = NfseUxHelper.retornoPrefeitura({
        'numero': '15',
        'protocolo': 'abc',
        'status': 'AUTORIZADA',
        'mensagem': 'Processada',
      });

      expect(texto, contains('NFS-e enviada para a prefeitura'));
      expect(texto, contains('Autorizada pela prefeitura'));
      expect(texto, contains('Número: 15'));
      expect(texto, contains('Protocolo: abc'));
      expect(texto, contains('Retorno: Processada'));
    });

    test('extrai erro legivel de payload aninhado do backend', () {
      final texto = NfseUxHelper.readableHttpError(
        400,
        '{"data":{"motivoRejeicao":"Código municipal inválido"}}',
        'Falha ao emitir NFS-e',
      );

      expect(texto, 'Código municipal inválido');
    });

    // BUG produção (card #504, reprovado 5x): os adaptadores reais de
    // município (SaoPauloMunicipioAdapter/BrasiliaMunicipioAdapter, em
    // AppAcademia/.../fiscal/MunicipioAdapter.java) retornam status em
    // INGLÊS -- ISSUED/AUTHORIZED/CANCELLED/CONTINGENCY -- que nunca
    // batiam com nenhum "contains" em português no helper.
    group('statusPrefeituraLabel reconhece valores reais em inglês dos adaptadores', () {
      test('ISSUED e AUTHORIZED mapeiam para "Autorizada pela prefeitura"', () {
        expect(NfseUxHelper.statusPrefeituraLabel('ISSUED'),
            'Autorizada pela prefeitura');
        expect(NfseUxHelper.statusPrefeituraLabel('AUTHORIZED'),
            'Autorizada pela prefeitura');
      });

      test('CANCELLED mapeia para "Cancelada na prefeitura" '
          '(não é capturado por "contains(CANCELAD)" -- grafia com LL dobrado)',
          () {
        expect(NfseUxHelper.statusPrefeituraLabel('CANCELLED'),
            'Cancelada na prefeitura');
      });

      test('CONTINGENCY mapeia para um texto legível dedicado', () {
        expect(NfseUxHelper.statusPrefeituraLabel('CONTINGENCY'),
            'Emitida em contingência');
      });

      test('continua reconhecendo os valores em português do mock adapter',
          () {
        expect(NfseUxHelper.statusPrefeituraLabel('EMITIDA'),
            'Autorizada pela prefeitura');
        expect(NfseUxHelper.statusPrefeituraLabel('CANCELADA'),
            'Cancelada na prefeitura');
        expect(NfseUxHelper.statusPrefeituraLabel('CONTINGENCIA'),
            'Emitida em contingência');
      });
    });
  });
}
