import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/nfe/nfe_item_model.dart';
import 'package:task_manager_flutter/utils/nfe_emission_payload.dart';

void main() {
  group('NfeEmissionPayload', () {
    test('monta payload exigido pelo backend de emissao', () {
      final item = const NfeItemModel(
        sequencial: 1,
        codigoProduto: 'PRD-1',
        descricao: 'Produto Teste',
        ncm: '12345678',
        cfop: '5102',
        cstIcms: '00',
        quantidade: 2,
        unidade: 'UN',
        precoUnitario: 10,
        precoTotal: 20,
        aliqIcms: 18,
        vlIcms: 3.6,
        aliqPis: 0,
        vlPis: 0,
        aliqCofins: 0,
        vlCofins: 0,
      ).toJson();

      final payload = NfeEmissionPayload.build(
        empresaId: '1',
        destinatarioId: '814',
        serie: '1',
        numero: '99',
        finalidade: 'NORMAL',
        itens: [item],
      );

      expect(payload['empresa_id'], 1);
      expect(payload['destinatario_id'], 814);
      expect(payload['serie'], '1');
      expect(payload['numero'], '99');
      expect(payload['finalidade'], 'NORMAL');
      expect(payload['valorTotal'], 20);
      expect(payload['itens'], hasLength(1));
      expect(payload['itens'].first['cProd'], 'PRD-1');
      expect(payload['itens'].first['xProd'], 'Produto Teste');
      expect(payload['itens'].first['vProd'], 20);
    });

    test('valida campos obrigatorios antes de emitir', () {
      final errors = NfeEmissionPayload.validate(
        empresaId: '1',
        destinatarioId: null,
        serie: '',
        numero: '99',
        finalidade: 'NORMAL',
        itens: const [],
      );

      expect(errors, contains('Destinatario'));
      expect(errors, contains('Serie'));
      expect(errors, contains('Itens'));
    });

    test('extrai mensagem legivel do backend', () {
      final message = NfeEmissionPayload.readableHttpError(
        400,
        '{"message":"cStat=539 - Duplicidade de NF-e"}',
      );

      expect(message, 'cStat=539 - Duplicidade de NF-e');
    });

    test('remove stack trace tecnico da mensagem Sefaz', () {
      final message = NfeEmissionPayload.readableHttpError(
        400,
        '{"data":{"message":"java.lang.IllegalStateException: cStat=539 - Duplicidade de NF-e\\n\\tat br.com.appAcademia.NfeService.emitir(NfeService.java:42)"}}',
      );

      expect(message, 'cStat=539 - Duplicidade de NF-e');
      expect(message, isNot(contains('java.lang')));
      expect(message, isNot(contains('br.com.appAcademia')));
    });

    test('identifica status autorizado para liberar XML e DANFE', () {
      expect(NfeEmissionPayload.isAuthorized('AUTORIZADA'), isTrue);
      expect(NfeEmissionPayload.isAuthorized(' autorizada '), isTrue);
      // Nota cancelada ja foi autorizada antes (cancelamento so e permitido
      // partindo de AUTORIZADA) -- o XML/DANFE ja gerados continuam validos
      // e precisam continuar consultaveis apos o cancelamento.
      expect(NfeEmissionPayload.isAuthorized('CANCELADA'), isTrue);
      expect(NfeEmissionPayload.isAuthorized('PENDENTE'), isFalse);
      expect(NfeEmissionPayload.isAuthorized('REJEITADA'), isFalse);
    });

    test(
        'monta payload a partir do shape real retornado por GET /api/nfe_item (cProd/xProd/qCom/vUnCom/vProd)',
        () {
      // Diferente do teste acima (que usa NfeItemModel.toJson(), so usado em
      // nfe_saida_create_screen.dart), este reproduz o shape que _itens
      // realmente tem dentro de nfe_detail_screen.dart -- e o branch
      // primario de itemPayload() que roda em producao ao clicar "Emitir".
      final item = {
        'cProd': 'PRD-2',
        'xProd': 'Produto Real',
        'ncm': '87654321',
        'cfop': '5102',
        'uCom': 'UN',
        'qCom': 3,
        'vUnCom': 15.5,
        'vProd': 46.5,
        'cstIcms': '00',
        'aliqIcms': 18,
        'vBcIcms': 46.5,
        'vIcms': 8.37,
      };

      final payload = NfeEmissionPayload.build(
        empresaId: '1',
        destinatarioId: '814',
        serie: '1',
        numero: '100',
        finalidade: 'NORMAL',
        itens: [item],
      );

      final itemPayload = payload['itens'].first;
      expect(itemPayload['cProd'], 'PRD-2');
      expect(itemPayload['xProd'], 'Produto Real');
      expect(itemPayload['qCom'], 3);
      expect(itemPayload['vUnCom'], 15.5);
      expect(itemPayload['vProd'], 46.5);
      expect(itemPayload['vIcms'], 8.37);
      expect(payload['valorTotal'], 46.5);
    });
  });
}
