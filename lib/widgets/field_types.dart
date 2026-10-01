import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Enum para tipos de campo
enum FieldType {
  text,
  number,
  email,
  date,
  multiline,
  dropdown,
  boolean,
  file,
  password,
  phone,
  cpf,
  cnpj,
  currency,
  percentage,
  url,
  multiselect,
}

// Configuração de arquivo
class FileConfig {
  final List<String> allowedExtensions;
  final bool allowMultiple;
  final int maxFileSize; // em bytes
  final String fileFieldName; // nome do campo para upload

  const FileConfig({
    this.allowedExtensions = const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    this.allowMultiple = false,
    this.maxFileSize = 5 * 1024 * 1024, // 5MB
    this.fileFieldName = 'file',
  });
}

// Configuração avançada de campo
class FieldConfig {
  final String label;
  final String fieldName;
  final bool isFilterable;
  final bool isInForm;
  final int flex;
  final int maxLines;
  final IconData? icon;
  final bool isSortable;
  final FieldType fieldType;
  final List<Map<String, dynamic>>? dropdownOptions;
  final Future<List<Map<String, dynamic>>> Function()? dropdownFutureBuilder;
  final String dropdownValueField;
  final String dropdownDisplayField;
  final bool isRequired;
  final String? Function(String?)? validator;
  final String? displayFieldName;
  final bool isVisibleByDefault;
  final bool isFixed;
  final bool enabled;
  final dynamic defaultValue;
  final FileConfig? fileConfig;
  final dynamic dropdownSelectedValue;
  final Map<String, dynamic>? fieldSpecificConfig;

  const FieldConfig({
    required this.label,
    required this.fieldName,
    this.isFilterable = true,
    this.isInForm = true,
    this.flex = 1,
    this.maxLines = 1,
    this.icon,
    this.isSortable = true,
    this.fieldType = FieldType.text,
    this.dropdownOptions,
    this.dropdownFutureBuilder,
    this.dropdownValueField = 'value',
    this.dropdownDisplayField = 'label',
    this.isRequired = false,
    this.validator,
    this.displayFieldName,
    this.isVisibleByDefault = true,
    this.isFixed = false,
    this.enabled = true,
    this.defaultValue,
    this.fileConfig,
    this.dropdownSelectedValue,
    this.fieldSpecificConfig,
  });
}

// Configuração de exportação
class ExportConfig {
  final bool enableCsvExport;
  final bool enablePdfExport;
  final String filenamePrefix;

  const ExportConfig({
    this.enableCsvExport = true,
    this.enablePdfExport = true,
    this.filenamePrefix = 'export',
  });
}

// Configuração de paginação
class PaginationConfig {
  final int defaultRowsPerPage;
  final List<int> availableRowsPerPage;
  final bool showItemsPerPageSelector;

  const PaginationConfig({
    this.defaultRowsPerPage = 25,
    this.availableRowsPerPage = const [10, 25, 50, 100],
    this.showItemsPerPageSelector = true,
  });
}

// Configuração de ação personalizada
class CustomAction<T> {
  final IconData icon;
  final String label;
  final void Function(BuildContext context, T item) onPressed;
  final bool Function(T item)? isVisible;

  const CustomAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isVisible,
  });
}

// Typedefs para funções comuns
typedef FromJson<T> = T Function(Map<String, dynamic> json);
typedef ToJson<T> = Map<String, dynamic> Function(T item);
typedef SecurityCheck = bool Function(String permission);
typedef OnItemTap<T> = void Function(T item, BuildContext context);
typedef CustomActionBuilder<T> = List<CustomAction<T>> Function();

// Formatters específicos para diferentes tipos de campo
class NumberInputFormatter extends TextInputFormatter {
  final int decimalDigits;

  NumberInputFormatter({this.decimalDigits = 2});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final cleaned = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');
    final parts = cleaned.split('.');

    if (parts.length > 2) return oldValue;
    if (parts.length == 2 && parts[1].length > decimalDigits) {
      return oldValue;
    }

    return newValue.copyWith(text: cleaned);
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final cleaned = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) return newValue;

    final value = int.parse(cleaned) / 100;
    final formatted = 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.length <= 11) {
      String formatted = cleaned;
      if (cleaned.length > 2) {
        formatted = '(${cleaned.substring(0, 2)}) ${cleaned.substring(2)}';
      }
      if (cleaned.length > 7) {
        formatted =
            '(${cleaned.substring(0, 2)}) ${cleaned.substring(2, 7)}-${cleaned.substring(7)}';
      }
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    return oldValue;
  }
}

class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.length <= 11) {
      String formatted = cleaned;
      if (cleaned.length > 3) {
        formatted = '${cleaned.substring(0, 3)}.${cleaned.substring(3)}';
      }
      if (cleaned.length > 6) {
        formatted =
            '${cleaned.substring(0, 3)}.${cleaned.substring(3, 6)}.${cleaned.substring(6)}';
      }
      if (cleaned.length > 9) {
        formatted =
            '${cleaned.substring(0, 3)}.${cleaned.substring(3, 6)}.${cleaned.substring(6, 9)}-${cleaned.substring(9)}';
      }
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    return oldValue;
  }
}

class CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.length <= 14) {
      String formatted = cleaned;
      if (cleaned.length > 2) {
        formatted = '${cleaned.substring(0, 2)}.${cleaned.substring(2)}';
      }
      if (cleaned.length > 5) {
        formatted =
            '${cleaned.substring(0, 2)}.${cleaned.substring(2, 5)}.${cleaned.substring(5)}';
      }
      if (cleaned.length > 8) {
        formatted =
            '${cleaned.substring(0, 2)}.${cleaned.substring(2, 5)}.${cleaned.substring(5, 8)}/${cleaned.substring(8)}';
      }
      if (cleaned.length > 12) {
        formatted =
            '${cleaned.substring(0, 2)}.${cleaned.substring(2, 5)}.${cleaned.substring(5, 8)}/${cleaned.substring(8, 12)}-${cleaned.substring(12)}';
      }
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    return oldValue;
  }
}

// Validações comuns
class FieldValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(value) ? null : 'Digite um email válido';
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }

  static String? validateMinLength(
    String? value,
    int minLength,
    String fieldName,
  ) {
    if (value == null || value.length < minLength) {
      return '$fieldName deve ter pelo menos $minLength caracteres';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return null;
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    return cleaned.length >= 10 ? null : 'Digite um telefone válido';
  }

  static String? validateCpf(String? value) {
    if (value == null || value.isEmpty) return null;
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length != 11) return 'CPF deve ter 11 dígitos';
    // Implementar validação real do CPF aqui
    return null;
  }

  static String? validateCnpj(String? value) {
    if (value == null || value.isEmpty) return null;
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length != 14) return 'CNPJ deve ter 14 dígitos';
    // Implementar validação real do CNPJ aqui
    return null;
  }

  static String? validateNumber(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) return null;
    final number = double.tryParse(value.replaceAll(',', '.'));
    if (number == null) return 'Digite um número válido';
    if (min != null && number < min) return 'Valor mínimo: $min';
    if (max != null && number > max) return 'Valor máximo: $max';
    return null;
  }
}

// Helper para criar configurações comuns de campo
class FieldConfigBuilder {
  static FieldConfig text({
    required String label,
    required String fieldName,
    String? displayFieldName,
    bool isRequired = false,
    bool isFilterable = true,
    bool isInForm = true,
    bool isVisibleByDefault = true,
    bool isFixed = false,
    bool enabled = true,
    int maxLines = 1,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    return FieldConfig(
      label: label,
      fieldName: fieldName,
      displayFieldName: displayFieldName,
      isFilterable: isFilterable,
      isInForm: isInForm,
      isVisibleByDefault: isVisibleByDefault,
      isFixed: isFixed,
      enabled: enabled,
      maxLines: maxLines,
      icon: icon,
      fieldType: FieldType.text,
      isRequired: isRequired,
      validator: validator,
    );
  }

  static FieldConfig number({
    required String label,
    required String fieldName,
    String? displayFieldName,
    bool isRequired = false,
    bool isFilterable = true,
    bool isInForm = true,
    bool isVisibleByDefault = true,
    bool isFixed = false,
    bool enabled = true,
    int decimalDigits = 2,
    double? minValue,
    double? maxValue,
    IconData? icon,
  }) {
    return FieldConfig(
      label: label,
      fieldName: fieldName,
      displayFieldName: displayFieldName,
      isFilterable: isFilterable,
      isInForm: isInForm,
      isVisibleByDefault: isVisibleByDefault,
      isFixed: isFixed,
      enabled: enabled,
      icon: icon ?? Icons.numbers,
      fieldType: FieldType.number,
      isRequired: isRequired,
      fieldSpecificConfig: {
        'decimalDigits': decimalDigits,
        'minValue': minValue,
        'maxValue': maxValue,
      },
      validator: (value) =>
          FieldValidators.validateNumber(value, min: minValue, max: maxValue),
    );
  }

  static FieldConfig email({
    required String label,
    required String fieldName,
    String? displayFieldName,
    bool isRequired = false,
    bool isFilterable = true,
    bool isInForm = true,
    bool isVisibleByDefault = true,
    bool isFixed = false,
    bool enabled = true,
    IconData? icon,
  }) {
    return FieldConfig(
      label: label,
      fieldName: fieldName,
      displayFieldName: displayFieldName,
      isFilterable: isFilterable,
      isInForm: isInForm,
      isVisibleByDefault: isVisibleByDefault,
      isFixed: isFixed,
      enabled: enabled,
      icon: icon ?? Icons.email,
      fieldType: FieldType.email,
      isRequired: isRequired,
      validator: FieldValidators.validateEmail,
    );
  }

  static FieldConfig date({
    required String label,
    required String fieldName,
    String? displayFieldName,
    bool isRequired = false,
    bool isFilterable = true,
    bool isInForm = true,
    bool isVisibleByDefault = true,
    bool isFixed = false,
    bool enabled = true,
    IconData? icon,
  }) {
    return FieldConfig(
      label: label,
      fieldName: fieldName,
      displayFieldName: displayFieldName,
      isFilterable: isFilterable,
      isInForm: isInForm,
      isVisibleByDefault: isVisibleByDefault,
      isFixed: isFixed,
      enabled: enabled,
      icon: icon ?? Icons.calendar_today,
      fieldType: FieldType.date,
      isRequired: isRequired,
      validator: (value) => FieldValidators.validateRequired(value, label),
    );
  }

  static FieldConfig password({
    required String label,
    required String fieldName,
    String? displayFieldName,
    bool isRequired = false,
    bool isFilterable = false,
    bool isInForm = true,
    bool isVisibleByDefault = true,
    bool isFixed = false,
    bool enabled = true,
    bool confirmPassword = false,
    IconData? icon,
  }) {
    return FieldConfig(
      label: label,
      fieldName: fieldName,
      displayFieldName: displayFieldName,
      isFilterable: isFilterable,
      isInForm: isInForm,
      isVisibleByDefault: isVisibleByDefault,
      isFixed: isFixed,
      enabled: enabled,
      icon: icon ?? Icons.lock,
      fieldType: FieldType.password,
      isRequired: isRequired,
      fieldSpecificConfig: {'confirmPassword': confirmPassword},
      validator: (value) => FieldValidators.validateMinLength(value, 6, label),
    );
  }

  static FieldConfig dropdown({
    required String label,
    required String fieldName,
    String? displayFieldName,
    required Future<List<Map<String, dynamic>>> Function()
    dropdownFutureBuilder,
    bool isRequired = false,
    bool isFilterable = true,
    bool isInForm = true,
    bool isVisibleByDefault = true,
    bool isFixed = false,
    bool enabled = true,
    IconData? icon,
    String dropdownValueField = 'value',
    String dropdownDisplayField = 'label',
    dynamic defaultValue,
  }) {
    return FieldConfig(
      label: label,
      fieldName: fieldName,
      displayFieldName: displayFieldName,
      isFilterable: isFilterable,
      isInForm: isInForm,
      isVisibleByDefault: isVisibleByDefault,
      isFixed: isFixed,
      enabled: enabled,
      icon: icon ?? Icons.arrow_drop_down,
      fieldType: FieldType.dropdown,
      isRequired: isRequired,
      dropdownFutureBuilder: dropdownFutureBuilder,
      dropdownValueField: dropdownValueField,
      dropdownDisplayField: dropdownDisplayField,
      dropdownSelectedValue: defaultValue,
    );
  }
}
