import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/cnpj_input_formatter.dart';

void main() {
  group('CnpjInputFormatter', () {
    final formatter = CnpjInputFormatter();

    TextEditingValue apply(String oldText, String newText) {
      return formatter.formatEditUpdate(
        TextEditingValue(text: oldText),
        TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newText.length)),
      );
    }

    test('formata CNPJ completo com máscara 00.000.000/0000-00', () {
      final result = apply('', '12345678000199');
      expect(result.text, '12.345.678/0001-99');
    });

    test('ignora caracteres não numéricos digitados', () {
      final result = apply('', 'ab12cd34ef567800--01/99gh');
      expect(result.text, '12.345.678/0001-99');
    });

    test('formata parcialmente enquanto usuário digita', () {
      expect(apply('', '1').text, '1');
      expect(apply('', '12').text, '12');
      expect(apply('', '123').text, '12.3');
      expect(apply('', '123456').text, '12.345.6');
      expect(apply('', '1234567').text, '12.345.67');
      expect(apply('', '12345678').text, '12.345.678');
      expect(apply('', '123456780001').text, '12.345.678/0001');
    });

    test('limita a 14 dígitos, ignorando excesso', () {
      final result = apply('', '123456780001999999');
      expect(result.text, '12.345.678/0001-99');
      expect(CnpjInputFormatter.onlyDigits(result.text).length, 14);
    });

    test('cursor sempre no final do texto formatado', () {
      final result = apply('', '12345678000199');
      expect(result.selection.baseOffset, result.text.length);
    });
  });

  group('CnpjInputFormatter.onlyDigits', () {
    test('extrai somente dígitos de um CNPJ formatado', () {
      expect(CnpjInputFormatter.onlyDigits('12.345.678/0001-99'),
          '12345678000199');
    });

    test('retorna string vazia quando não há dígitos', () {
      expect(CnpjInputFormatter.onlyDigits(''), '');
      expect(CnpjInputFormatter.onlyDigits('...--/'), '');
    });
  });
}
