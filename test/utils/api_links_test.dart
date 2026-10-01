// test/utils/api_links_test.dart
//
// Testes automatizados para validar as constantes de URL do ApiLinks
// relacionadas ao módulo de Import CSV e Calendário Financeiro.

import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/api_links.dart';

void main() {
  group('ApiLinks — Contas a Pagar', () {
    test('allContasPagar contém /api/conta_pagar (underscore, singular)', () {
      expect(ApiLinks.allContasPagar, contains('/api/conta_pagar'));
    });

    test('allContasPagar NÃO contém /api/contas-pagar (plural com hífen)', () {
      expect(ApiLinks.allContasPagar, isNot(contains('/api/contas-pagar')));
    });

    test('allContasPagar contém o context-path /boletobancos', () {
      expect(ApiLinks.allContasPagar, contains('/boletobancos'));
    });

    test('createContaPagar usa /api/conta_pagar', () {
      expect(ApiLinks.createContaPagar, contains('/api/conta_pagar'));
    });

    test('updateContaPagar usa /api/conta_pagar/{id}', () {
      expect(ApiLinks.updateContaPagar('42'), contains('/api/conta_pagar/42'));
    });

    test('deleteContaPagar usa /api/conta_pagar/{id}', () {
      expect(ApiLinks.deleteContaPagar('99'), contains('/api/conta_pagar/99'));
    });

    test('registrarBaixaContaPagar usa /api/conta_pagar/{id}/baixa', () {
      expect(ApiLinks.registrarBaixaContaPagar('1'),
          contains('/api/conta_pagar/1/baixa'));
    });

    test('desfazerContaPagar usa /api/conta_pagar/desfazer/{id}', () {
      expect(ApiLinks.desfazerContaPagar('5'),
          contains('/api/conta_pagar/desfazer/5'));
    });
  });

  group('ApiLinks — Contas a Receber', () {
    test('allContasReceber contém /api/conta_receber (underscore, singular)',
        () {
      expect(ApiLinks.allContasReceber, contains('/api/conta_receber'));
    });

    test('allContasReceber NÃO contém /api/contas-receber (plural com hífen)',
        () {
      expect(ApiLinks.allContasReceber, isNot(contains('/api/contas-receber')));
    });

    test('allContasReceber contém o context-path /boletobancos', () {
      expect(ApiLinks.allContasReceber, contains('/boletobancos'));
    });

    test('createContaReceber usa /api/conta_receber', () {
      expect(ApiLinks.createContaReceber, contains('/api/conta_receber'));
    });

    test('updateContaReceber usa /api/conta_receber/{id}', () {
      expect(
          ApiLinks.updateContaReceber('10'), contains('/api/conta_receber/10'));
    });

    test('deleteContaReceber usa /api/conta_receber/{id}', () {
      expect(
          ApiLinks.deleteContaReceber('7'), contains('/api/conta_receber/7'));
    });

    test('registrarBaixaContaReceber usa /api/conta_receber/{id}/baixa', () {
      expect(ApiLinks.registrarBaixaContaReceber('3'),
          contains('/api/conta_receber/3/baixa'));
    });

    test('desfazerContaReceber usa /api/conta_receber/desfazer/{id}', () {
      expect(ApiLinks.desfazerContaReceber('8'),
          contains('/api/conta_receber/desfazer/8'));
    });
  });

  group('ApiLinks — Importação CSV', () {
    test('importacaoContaPagar contém /api/importacao/conta-pagar (hífen)', () {
      expect(ApiLinks.importacaoContaPagar,
          contains('/api/importacao/conta-pagar'));
    });

    test('importacaoContaReceber contém /api/importacao/conta-receber (hífen)',
        () {
      expect(ApiLinks.importacaoContaReceber,
          contains('/api/importacao/conta-receber'));
    });

    test('importacaoPreview contém /api/importacao/preview', () {
      expect(ApiLinks.importacaoPreview, contains('/api/importacao/preview'));
    });

    test('importacaoContaPagar contém o context-path /boletobancos', () {
      expect(ApiLinks.importacaoContaPagar, contains('/boletobancos'));
    });

    test('importacaoContaReceber contém o context-path /boletobancos', () {
      expect(ApiLinks.importacaoContaReceber, contains('/boletobancos'));
    });

    test('importacaoPreview contém o context-path /boletobancos', () {
      expect(ApiLinks.importacaoPreview, contains('/boletobancos'));
    });
  });

  group('ApiLinks — Separação de padrões CP vs CR vs Importação', () {
    test('URLs de CP usam underscore; URLs de importação CP usam hífen', () {
      // CP CRUD: underscore
      expect(ApiLinks.allContasPagar, contains('conta_pagar'));
      // Importação CP: hífen (endpoint diferente no backend)
      expect(ApiLinks.importacaoContaPagar, contains('conta-pagar'));
    });

    test('URLs de CR usam underscore; URLs de importação CR usam hífen', () {
      expect(ApiLinks.allContasReceber, contains('conta_receber'));
      expect(ApiLinks.importacaoContaReceber, contains('conta-receber'));
    });

    test('baseUrl expõe _baseUrlNew (contém /boletobancos)', () {
      expect(ApiLinks.baseUrl, contains('/boletobancos'));
    });

    test('baseUrl local usa backend dev em 9001 com context-path', () {
      expect(ApiLinks.baseUrl, equals('http://127.0.0.1:9001/boletobancos'));
      expect(ApiLinks.baseUrl, isNot(contains(':8080')));
    });

    test('login aponta para o endpoint POST /rest/auth/login correto', () {
      expect(
        ApiLinks.login,
        equals('http://127.0.0.1:9001/boletobancos/rest/auth/login'),
      );
      expect(ApiLinks.login, isNot(contains(':8080')));
    });
  });

  group('ApiLinks — NFS-e', () {
    test('nfseIssue aponta para /api/nfse/issue', () {
      expect(ApiLinks.nfseIssue, contains('/api/nfse/issue'));
    });

    test('nfseStatusUrl codifica parâmetros especiais corretamente', () {
      final url = ApiLinks.nfseStatusUrl('São Paulo', '123/A');
      expect(url, contains('municipalityCode=S%C3%A3o%20Paulo'));
      expect(url, contains('nfseNumber=123%2FA'));
    });

    test('nfseCancel aponta para /api/nfse/cancel', () {
      expect(ApiLinks.nfseCancel, contains('/api/nfse/cancel'));
    });

    test('nfseContingency aponta para /api/nfse/contingency', () {
      expect(ApiLinks.nfseContingency, contains('/api/nfse/contingency'));
    });

    test('nfseAudit aponta para /api/nfse/audit', () {
      expect(ApiLinks.nfseAudit, contains('/api/nfse/audit'));
    });
  });

  group('ApiLinks — CRM / Recorrências e Faturas', () {
    test('allRecurringContracts aponta para /api/crm/contracts', () {
      expect(ApiLinks.allRecurringContracts, contains('/api/crm/contracts'));
    });

    test('createRecurringContract aponta para /api/crm/contracts', () {
      expect(ApiLinks.createRecurringContract, contains('/api/crm/contracts'));
    });

    test('allInvoiceRecords aponta para /api/crm/invoices', () {
      expect(ApiLinks.allInvoiceRecords, contains('/api/crm/invoices'));
    });

    test('generateInvoice aponta para /api/crm/invoices', () {
      expect(ApiLinks.generateInvoice, contains('/api/crm/invoices'));
    });

    test('allReminderNotifications aponta para /api/crm/reminders', () {
      expect(ApiLinks.allReminderNotifications, contains('/api/crm/reminders'));
    });

    test('sendReminder aponta para /api/crm/reminders', () {
      expect(ApiLinks.sendReminder, contains('/api/crm/reminders'));
    });
  });

  // Fix (2026-09-16): "Vincular Filial Existente" (filiais_parceiro_screen.dart)
  // usava URL RELATIVA hardcoded "/api/parceiros/{id}" (plural, sem host e
  // sem match no backend -- ParceiroController mapeia "/api/parceiro",
  // singular). Sem host, o navegador resolvia a chamada contra a propria
  // origem da pagina Flutter Web (o dev-server), que devolvia 200 com o
  // index.html no lugar do JSON do parceiro -- getResp.isSuccess ficava
  // false (jsonDecode falhava), o PUT nunca era chamado, o popup nao
  // fechava e a grid nao atualizava. Fix usa os helpers ja existentes e
  // testados do ApiLinks (allParceiros/updateParceiro), que sempre incluem
  // o host ($_baseUrlNew) e o path singular correto.
  group('ApiLinks — Parceiro (fix Vincular Filial Existente)', () {
    test('allParceiros usa /api/parceiro (singular) e inclui o host', () {
      expect(ApiLinks.allParceiros, contains('/api/parceiro'));
      expect(ApiLinks.allParceiros, isNot(contains('/api/parceiros')));
      expect(Uri.parse(ApiLinks.allParceiros).hasAuthority, isTrue);
    });

    test('updateParceiro usa /api/parceiro/update/{id} e inclui o host', () {
      final url = ApiLinks.updateParceiro('1755');
      expect(url, contains('/api/parceiro/update/1755'));
      expect(url, isNot(contains('/api/parceiros')));
      expect(Uri.parse(url).hasAuthority, isTrue);
    });

    test('GET de parceiro por id (allParceiros + "/id") continua singular e absoluto',
        () {
      const id = '1755';
      final url = '${ApiLinks.allParceiros}/$id';
      expect(url, contains('/api/parceiro/1755'));
      expect(url, isNot(contains('/api/parceiros')));
      expect(Uri.parse(url).hasAuthority, isTrue);
    });
  });

  group('ApiLinks — Limpar Base de Produção (Preservar Empresas 1 e 20001)', () {
    test('limparBasePreservarEmpresas aponta para /api/admin/limpar-base-preservar-empresas com context-path', () {
      expect(ApiLinks.limparBasePreservarEmpresas,
          contains('/api/admin/limpar-base-preservar-empresas'));
      expect(ApiLinks.limparBasePreservarEmpresas, contains('/boletobancos'));
      expect(Uri.parse(ApiLinks.limparBasePreservarEmpresas).hasAuthority, isTrue);
    });
  });
}
