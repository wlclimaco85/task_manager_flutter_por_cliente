import 'package:flutter/services.dart';

/// Formata entrada de texto como CNPJ (00.000.000/0000-00) permitindo apenas
/// dígitos. Usado no filtro de CNPJ do parceiro/destinatário na listagem de NF-e.
class CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digits.length > 14 ? digits.substring(0, 14) : digits;
    final buffer = StringBuffer();
    final isUltimo = limited.length - 1;
    for (var i = 0; i < limited.length; i++) {
      buffer.write(limited[i]);
      if (i == isUltimo) continue;
      if (i == 1 || i == 4) buffer.write('.');
      if (i == 7) buffer.write('/');
      if (i == 11) buffer.write('-');
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Extrai somente os dígitos do CNPJ formatado (para envio à API).
  static String onlyDigits(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');
}
