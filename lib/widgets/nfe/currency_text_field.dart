import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TextFormField especializado em entrada de valores monetários (BRL)
///
/// Aplica máscara automática no formato 1.234,56
/// Retorna value como double via callback
/// Tap targets: 48dp+
class CurrencyTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final double? initialValue;
  final ValueChanged<double> onChanged;
  final bool readOnly;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;

  const CurrencyTextField({
    super.key,
    required this.label,
    this.hint,
    this.initialValue,
    required this.onChanged,
    this.readOnly = false,
    this.validator,
    this.textInputAction = TextInputAction.next,
  });

  @override
  State<CurrencyTextField> createState() => _CurrencyTextFieldState();
}

class _CurrencyTextFieldState extends State<CurrencyTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    if (widget.initialValue != null && widget.initialValue! > 0) {
      _controller.text = _formatCurrency(widget.initialValue!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Formata valor para string moeda (1.234,56)
  String _formatCurrency(double value) {
    String str = value.toStringAsFixed(2);
    List<String> parts = str.split('.');
    String integerPart = parts[0];
    String decimalPart = parts[1];

    // Formatar parte inteira com separador de milhar
    StringBuffer result = StringBuffer();
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result.write('.');
      }
      result.write(integerPart[i]);
      count++;
    }

    String reversedInteger = result.toString().split('').reversed.join('');
    return '$reversedInteger,$decimalPart';
  }

  /// Converte string formatada para double
  double _parseCurrency(String value) {
    if (value.isEmpty) return 0.0;

    // Remove símbolos de formatação
    String cleaned = value.replaceAll('.', '').replaceAll(',', '.');

    return double.tryParse(cleaned) ?? 0.0;
  }

  /// TextInputFormatter para máscara de moeda
  TextEditingValue _formatInput(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Se está limpando, deixe passar
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove tudo que não é número
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      return TextEditingValue.empty;
    }

    // Garante que tem pelo menos 2 dígitos (centavos)
    if (digits.length == 1) {
      digits = '0$digits';
    }

    // Separa parte inteira e decimal
    String integerPart = digits.substring(0, digits.length - 2);
    String decimalPart = digits.substring(digits.length - 2);

    if (integerPart.isEmpty) {
      integerPart = '0';
    }

    // Formata com separador de milhar
    StringBuffer result = StringBuffer();
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result.write('.');
      }
      result.write(integerPart[i]);
      count++;
    }

    String formattedInteger = result.toString().split('').reversed.join('');
    String formatted = '$formattedInteger,$decimalPart';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: widget.readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        TextInputFormatter.withFunction(_formatInput),
      ],
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onChanged: (value) {
        widget.onChanged(_parseCurrency(value));
      },
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint ?? '0,00',
        prefixIcon: const Padding(
          padding: EdgeInsets.all(12),
          child: Text('R\$'),
        ),
        prefixIconConstraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        errorMaxLines: 2,
      ),
    );
  }
}
