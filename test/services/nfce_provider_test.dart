import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/empresa_model.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/services/nfce_provider.dart';


void main() {
  setUp(() {
    AuthUtility.userInfo = LoginModel(
      token: 'token-teste',
      login: Login(id: 10, empresa: Empresa(id: 20001)),
    );
  });

  tearDown(() => AuthUtility.userInfo = null);

  NfceProvider providerComItem() {
    final provider = NfceProvider();
    provider.adicionarItem({'id': 5, 'nome': 'CAMISETA', 'preco': 100.0});
    return provider;
  }

  test('sem pagamento informado envia dinheiro pelo total (evita <pag> vazio, rejeicao 215)', () {
    final json = providerComItem().buildVendaJson()!;

    final pagamentos = json['pagamentos'] as List;
    expect(pagamentos, hasLength(1));
    expect(pagamentos.first['formaPagamento'], '01');
    expect(pagamentos.first['valor'], 100.0);
  });

  test('pagamento informado pelo operador e mantido', () {
    final provider = providerComItem()..adicionarPagamento('PIX', 100.0);

    final pagamentos = provider.buildVendaJson()!['pagamentos'] as List;

    expect(pagamentos, hasLength(1));
    expect(pagamentos.first['formaPagamento'], '17');
  });

  test('desconto geral reduz o total, e enviado e e limitado ao subtotal', () {
    final provider = providerComItem()..descontoGeral = 10;

    expect(provider.total, 90.0);
    expect(provider.buildVendaJson()!['desconto'], 10.0);

    provider.descontoGeral = 500;
    expect(provider.descontoGeral, 100.0);
    provider.descontoGeral = -3;
    expect(provider.descontoGeral, 0.0);
  });

  test('telas do PDV (web/mobile e windows) tem o campo de desconto ligado ao provider', () {
    for (final caminho in [
      'lib/web/screens/nfce/pdv_screen.dart',
      'lib/windows/screens/nfce/pdv_screen.dart',
    ]) {
      final fonte = File(caminho).readAsStringSync().replaceAll(RegExp(r'\s+'), ' ');
      expect(fonte, contains('controller: _descontoCtrl'), reason: caminho);
      expect(fonte, contains('_provider.descontoGeral ='), reason: caminho);
    }
  });
}
