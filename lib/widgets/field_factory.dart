import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'field_types.dart'; // Importa FieldConfig de field_types.dart

class FieldFactory {
  static Widget buildField({
    required FieldConfig config,
    required TextEditingController controller,
    required BuildContext context,
    required Map<String, List<PlatformFile>> fileCache,
    required Map<String, List<Map<String, dynamic>>> dropdownCache,
    dynamic item,
  }) {
    if (item == null &&
        config.fieldType == FieldType.dropdown &&
        config.dropdownSelectedValue != null &&
        controller.text.isEmpty) {
      controller.text = config.dropdownSelectedValue.toString();
    }

    final fieldWidget = _buildSpecificField(
      config,
      controller,
      context,
      fileCache,
      dropdownCache,
    );

    return AbsorbPointer(
      absorbing: !config.enabled,
      child: Opacity(opacity: config.enabled ? 1.0 : 0.6, child: fieldWidget),
    );
  }

  static Widget _buildSpecificField(
    FieldConfig config,
    TextEditingController controller,
    BuildContext context,
    Map<String, List<PlatformFile>> fileCache,
    Map<String, List<Map<String, dynamic>>> dropdownCache,
  ) {
    switch (config.fieldType) {
      case FieldType.number:
        return _buildNumberField(config, controller);
      case FieldType.email:
        return _buildEmailField(config, controller);
      case FieldType.date:
        return _buildDateField(config, controller, context);
      case FieldType.password:
        return _buildPasswordField(config, controller);
      case FieldType.phone:
        return _buildPhoneField(config, controller);
      case FieldType.cpf:
        return _buildCpfField(config, controller);
      case FieldType.cnpj:
        return _buildCnpjField(config, controller);
      case FieldType.multiline:
        return _buildMultilineField(config, controller);
      case FieldType.dropdown:
        return _buildDropdownField(config, controller, dropdownCache);
      case FieldType.file:
        return _buildFileField(config, controller, fileCache, context);
      case FieldType.boolean:
        return _buildBooleanField(config, controller);
      default:
        return _buildTextField(config, controller);
    }
  }

  static Widget _buildNumberField(
    FieldConfig config,
    TextEditingController controller,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _buildInputDecoration(config),
      inputFormatters: [
        _NumberInputFormatter(
          decimalDigits: config.fieldSpecificConfig?['decimalDigits'] ?? 2,
        ),
      ],
      validator: (value) {
        if (config.isRequired && (value == null || value.isEmpty)) {
          return '${config.label} é obrigatório';
        }
        if (value != null && value.isNotEmpty) {
          final number = double.tryParse(value.replaceAll(',', '.'));
          if (number == null) {
            return 'Digite um número válido';
          }
          if (config.fieldSpecificConfig?['minValue'] != null &&
              number < config.fieldSpecificConfig!['minValue']) {
            return 'Valor mínimo: ${config.fieldSpecificConfig!['minValue']}';
          }
          if (config.fieldSpecificConfig?['maxValue'] != null &&
              number > config.fieldSpecificConfig!['maxValue']) {
            return 'Valor máximo: ${config.fieldSpecificConfig!['maxValue']}';
          }
        }
        return config.validator?.call(value);
      },
    );
  }

  static Widget _buildEmailField(
    FieldConfig config,
    TextEditingController controller,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      decoration: _buildInputDecoration(config),
      validator: (value) {
        if (config.isRequired && (value == null || value.isEmpty)) {
          return '${config.label} é obrigatório';
        }
        if (value != null && value.isNotEmpty && !_isValidEmail(value)) {
          return 'Digite um email válido';
        }
        return config.validator?.call(value);
      },
    );
  }

  static Widget _buildDateField(
    FieldConfig config,
    TextEditingController controller,
    BuildContext context,
  ) {
    return TextFormField(
      controller: controller,
      decoration: _buildInputDecoration(config),
      readOnly: true,
      onTap: () => _selectDate(context, controller, config),
      validator: (value) {
        if (config.isRequired && (value == null || value.isEmpty)) {
          return '${config.label} é obrigatório';
        }
        if (value != null && value.isNotEmpty) {
          try {
            DateFormat('yyyy-MM-dd').parseStrict(value);
          } catch (e) {
            return 'Data inválida';
          }
        }
        return config.validator?.call(value);
      },
    );
  }

  static Widget _buildPasswordField(
    FieldConfig config,
    TextEditingController controller,
  ) {
    final confirmPassword =
        config.fieldSpecificConfig?['confirmPassword'] ?? false;
    final passwordController = confirmPassword
        ? TextEditingController()
        : controller;

    return Column(
      children: [
        TextFormField(
          controller: passwordController,
          obscureText: true,
          decoration: _buildInputDecoration(config),
          validator: (value) {
            if (config.isRequired && (value == null || value.isEmpty)) {
              return '${config.label} é obrigatório';
            }
            if (value != null && value.isNotEmpty && value.length < 6) {
              return 'A senha deve ter pelo menos 6 caracteres';
            }
            return config.validator?.call(value);
          },
        ),
        if (confirmPassword) ...[
          const SizedBox(height: 10),
          TextFormField(
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Confirmar ${config.label}',
              prefixIcon: const Icon(Icons.lock_outline),
            ),
            validator: (value) {
              if (value != passwordController.text) {
                return 'As senhas não coincidem';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  static Widget _buildPhoneField(
    FieldConfig config,
    TextEditingController controller,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      decoration: _buildInputDecoration(config),
      inputFormatters: [_PhoneInputFormatter()],
      validator: (value) {
        if (config.isRequired && (value == null || value.isEmpty)) {
          return '${config.label} é obrigatório';
        }
        if (value != null && value.isNotEmpty && !_isValidPhone(value)) {
          return 'Digite um telefone válido';
        }
        return config.validator?.call(value);
      },
    );
  }

  static Widget _buildCpfField(
    FieldConfig config,
    TextEditingController controller,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: _buildInputDecoration(config),
      inputFormatters: [_CpfInputFormatter()],
      validator: (value) {
        if (config.isRequired && (value == null || value.isEmpty)) {
          return '${config.label} é obrigatório';
        }
        if (value != null && value.isNotEmpty && !_isValidCpf(value)) {
          return 'CPF inválido';
        }
        return config.validator?.call(value);
      },
    );
  }

  static Widget _buildCnpjField(
    FieldConfig config,
    TextEditingController controller,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: _buildInputDecoration(config),
      inputFormatters: [_CnpjInputFormatter()],
      validator: (value) {
        if (config.isRequired && (value == null || value.isEmpty)) {
          return '${config.label} é obrigatório';
        }
        if (value != null && value.isNotEmpty && !_isValidCnpj(value)) {
          return 'CNPJ inválido';
        }
        return config.validator?.call(value);
      },
    );
  }

  static Widget _buildTextField(
    FieldConfig config,
    TextEditingController controller,
  ) {
    return TextFormField(
      controller: controller,
      decoration: _buildInputDecoration(config),
      maxLines: config.maxLines,
      validator: config.validator,
    );
  }

  static Widget _buildMultilineField(
    FieldConfig config,
    TextEditingController controller,
  ) {
    return TextFormField(
      controller: controller,
      decoration: _buildInputDecoration(config),
      maxLines: config.maxLines,
      validator: config.validator,
    );
  }

  static Widget _buildBooleanField(
    FieldConfig config,
    TextEditingController controller,
  ) {
    return CheckboxListTile(
      title: Text(config.label),
      value: controller.text.toLowerCase() == 'true',
      onChanged: (value) {
        controller.text = value.toString();
      },
    );
  }

  static Widget _buildDropdownField(
    FieldConfig config,
    TextEditingController controller,
    Map<String, List<Map<String, dynamic>>> dropdownCache,
  ) {
    final cacheKey = '${config.fieldName}_dropdown';

    if (dropdownCache.containsKey(cacheKey)) {
      return _buildDropdownContent(
        config: config,
        controller: controller,
        options: dropdownCache[cacheKey]!,
      );
    } else if (config.dropdownFutureBuilder != null) {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: config.dropdownFutureBuilder!(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Erro ao carregar opções: ${snapshot.error}');
          } else {
            final options = snapshot.data ?? [];
            dropdownCache[cacheKey] = options;
            return _buildDropdownContent(
              config: config,
              controller: controller,
              options: options,
            );
          }
        },
      );
    } else {
      return _buildDropdownContent(
        config: config,
        controller: controller,
        options: config.dropdownOptions ?? [],
      );
    }
  }

  static Widget _buildDropdownContent({
    required FieldConfig config,
    required TextEditingController controller,
    required List<Map<String, dynamic>> options,
  }) {
    bool expectInteger = _isIntegerField(config);
    dynamic currentValue = _getCurrentValue(config, controller);

    final uniqueOptions = options
        .fold<Map<dynamic, Map<String, dynamic>>>({}, (map, item) {
          dynamic key = item[config.dropdownValueField];
          if (key != null && !map.containsKey(key)) {
            map[key] = item;
          }
          return map;
        })
        .values
        .toList();

    bool valueExists = uniqueOptions.any(
      (option) => option[config.dropdownValueField] == currentValue,
    );

    if (!valueExists && config.dropdownSelectedValue != null) {
      currentValue = config.dropdownSelectedValue;
    } else if (!valueExists) {
      currentValue = null;
    }

    return DropdownButtonFormField<dynamic>(
      initialValue: currentValue,
      decoration: _buildInputDecoration(config),
      isExpanded: true,
      menuMaxHeight: 300,
      itemHeight: 48,
      items: uniqueOptions.map<DropdownMenuItem<dynamic>>((option) {
        final optionValue = option[config.dropdownValueField];
        final optionLabel =
            option[config.dropdownDisplayField]?.toString() ?? '';
        return DropdownMenuItem<dynamic>(
          value: optionValue,
          child: Text(optionLabel, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) {
        controller.text = value?.toString() ?? '';
      },
      validator: (value) {
        if (config.validator != null) {
          return config.validator!(value?.toString());
        }
        return null;
      },
    );
  }

  static Widget _buildFileField(
    FieldConfig config,
    TextEditingController controller,
    Map<String, List<PlatformFile>> fileCache,
    BuildContext context,
  ) {
    final currentFiles = fileCache[config.fieldName] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (currentFiles.isNotEmpty)
          ...currentFiles.map(
            (file) => ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(file.name),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  fileCache[config.fieldName]?.remove(file);
                  controller.text = '';
                },
              ),
            ),
          ),
        ElevatedButton.icon(
          onPressed: () => _selectFiles(config, controller, fileCache, context),
          icon: const Icon(Icons.attach_file),
          label: Text(
            currentFiles.isEmpty
                ? 'Selecionar Arquivo'
                : 'Adicionar Mais Arquivos',
          ),
        ),
      ],
    );
  }

  static Future<void> _selectFiles(
    FieldConfig config,
    TextEditingController controller,
    Map<String, List<PlatformFile>> fileCache,
    BuildContext context,
  ) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions:
            config.fileConfig?.allowedExtensions ??
            ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: config.fileConfig?.allowMultiple ?? false,
      );

      if (result != null && result.files.isNotEmpty) {
        fileCache[config.fieldName] = result.files;
        controller.text = result.files.map((f) => f.name).join(', ');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar arquivo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static InputDecoration _buildInputDecoration(FieldConfig config) {
    return InputDecoration(
      labelText: config.label + (config.isRequired ? ' *' : ''),
      prefixIcon: config.icon != null ? Icon(config.icon) : null,
      border: const OutlineInputBorder(),
    );
  }

  static Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
    FieldConfig config,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  // Métodos auxiliares
  static dynamic _getCurrentValue(
    FieldConfig config,
    TextEditingController controller,
  ) {
    bool expectInteger = _isIntegerField(config);

    if (controller.text.isNotEmpty) {
      if (expectInteger) {
        return int.tryParse(controller.text);
      } else {
        return controller.text;
      }
    } else {
      return null;
    }
  }

  static bool _isIntegerField(FieldConfig config) {
    return config.dropdownValueField == 'id' ||
        config.fieldName.toLowerCase().contains('id');
  }

  // Validações
  static bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  static bool _isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    return cleaned.length >= 10;
  }

  static bool _isValidCpf(String cpf) {
    final cleaned = cpf.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length != 11) return false;
    return true;
  }

  static bool _isValidCnpj(String cnpj) {
    final cleaned = cnpj.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length != 14) return false;
    return true;
  }
}

// Formatters para os campos
class _NumberInputFormatter extends TextInputFormatter {
  final int decimalDigits;

  _NumberInputFormatter({this.decimalDigits = 2});

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

class _PhoneInputFormatter extends TextInputFormatter {
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

class _CpfInputFormatter extends TextInputFormatter {
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

class _CnpjInputFormatter extends TextInputFormatter {
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
