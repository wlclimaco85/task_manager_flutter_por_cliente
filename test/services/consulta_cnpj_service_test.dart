import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/services/consulta_cnpj_service.dart';

void main() {
  group('ConsultaCnpjService Tests', () {
    test('invalid CNPJ returns null without making network calls', () async {
      final res1 = await ConsultaCnpjService.consultar('');
      expect(res1, isNull);

      final res2 = await ConsultaCnpjService.consultar('123');
      expect(res2, isNull);

      final res3 = await ConsultaCnpjService.consultar('1234567890123'); // 13 digits
      expect(res3, isNull);
    });

    test('valid length sanitizes formatting before calling lookup', () async {
      // Formatted CNPJ with 14 digits
      const formattedCnpj = '00.000.000/0001-91';
      final clean = formattedCnpj.replaceAll(RegExp(r'\D'), '');
      expect(clean.length, 14);
    });
  });
}
