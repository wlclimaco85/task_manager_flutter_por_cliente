import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/nfce/item_venda_model.dart';

void main() {
  group('PagamentoModel', () {
    test('envia codigo SEFAZ para pagamento textual do PDV NFC-e', () {
      final dinheiro = PagamentoModel(formaPagamento: 'DINHEIRO', valor: 30);
      final pix = PagamentoModel(formaPagamento: 'PIX', valor: 23);

      expect(dinheiro.toJson(), {'formaPagamento': '01', 'valor': 30});
      expect(pix.toJson(), {'formaPagamento': '17', 'valor': 23});
    });
  });
}
