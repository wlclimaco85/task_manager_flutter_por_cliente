// lib/data/customization/grid_utils.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'grid_models.dart'; // 👈 adiciona este import

/// ---------------------------------------------------------------------------
/// JSON / MAP HELPERS
/// ---------------------------------------------------------------------------

String prettyJson(Map<String, dynamic> obj) =>
    const JsonEncoder.withIndent('  ').convert(obj);

/// Resolve o valor fixo de payload de um campo (TelaField.defaultValue),
/// aceitando os templates especiais:
///   - `{{now+Nd}}`      → data/hora atual + N dias, ISO 8601
///   - `{{campo:xxx}}`   → copia o valor já coletado do campo `xxx` no formData
/// Qualquer outro valor (String, bool, num, Map) é usado literalmente.
final RegExp _templateNowRegExp = RegExp(r'^\{\{now\+(\d+)d\}\}$');
final RegExp _templateCampoRegExp = RegExp(r'^\{\{campo:([\w.]+)\}\}$');

dynamic resolveFieldDefaultTemplate(
  dynamic value,
  Map<String, dynamic> formData,
) {
  if (value is! String) return value;
  final nowMatch = _templateNowRegExp.firstMatch(value);
  if (nowMatch != null) {
    final dias = int.parse(nowMatch.group(1)!);
    return DateTime.now().add(Duration(days: dias)).toIso8601String();
  }
  final campoMatch = _templateCampoRegExp.firstMatch(value);
  if (campoMatch != null) {
    return getNestedValue(formData, campoMatch.group(1)!);
  }
  return value;
}

dynamic getNestedValue(Map<String, dynamic>? obj, String fieldPath) {
  if (obj == null) return null;
  if (!fieldPath.contains('.')) return obj[fieldPath];
  dynamic current = obj;
  for (final part in fieldPath.split('.')) {
    if (current is Map && current.containsKey(part)) {
      current = current[part];
    } else {
      return null;
    }
  }
  return current;
}

/// adiciona chave aninhada (a.b.c) no Map
void addToFormData(Map<String, dynamic> map, String key, dynamic value) {
  if (!key.contains('.')) {
    map[key] = value;
    return;
  }
  final parts = key.split('.');
  Map<String, dynamic> current = map;
  for (int i = 0; i < parts.length - 1; i++) {
    final part = parts[i];
    if (!current.containsKey(part) || current[part] is! Map) {
      current[part] = {};
    }
    current = current[part];
  }
  current[parts.last] = value;
}

/// copia todas as chaves de outro Map aninhando corretamente
void addAllNested(Map<String, dynamic> target, Map<String, dynamic> src) {
  for (final e in src.entries) {
    addToFormData(target, e.key, e.value);
  }
}

/// normaliza campos com ponto em chaves simples (ex.: user.name -> {"user":{"name":...}})
Map<String, dynamic> normalizeDotted(Map<String, dynamic> src) {
  final result = <String, dynamic>{};
  src.forEach((key, value) {
    addToFormData(result, key, value);
  });
  return result;
}

/// converte datas texto em DateTime
DateTime? tryParseDate(String text, String format) {
  try {
    return DateFormat(format).parseStrict(text);
  } catch (_) {
    return null;
  }
}

/// tenta converter data para ISO-8601
String? tryDateToIso(String text, String format) {
  final dt = tryParseDate(text, format);
  return dt?.toIso8601String();
}

/// retorna lista independente de onde está (data, dados, content, items)
List<Map<String, dynamic>> extractAnyList(dynamic data) {
  if (data is List) {
    return data.whereType<Map<String, dynamic>>().toList();
  } else if (data is Map) {
    if (data['content'] is List) return extractAnyList(data['content']);
    if (data['items'] is List) return extractAnyList(data['items']);
  }
  return [];
}

/// transforma valores em strings planas para envio multipart
Map<String, String> flattenForMultipart(Map<String, dynamic> map) {
  final result = <String, String>{};
  void recurse(String prefix, dynamic value) {
    if (value is Map<String, dynamic>) {
      value.forEach((k, v) => recurse('$prefix.$k', v));
    } else if (value is List) {
      for (int i = 0; i < value.length; i++) {
        recurse('$prefix[$i]', value[i]);
      }
    } else {
      result[prefix] = value?.toString() ?? '';
    }
  }

  map.forEach((k, v) => recurse(k, v));
  return result;
}

/// tipo de teclado sugerido para o FieldType
TextInputType keyboardForFieldType(FieldType t) {
  switch (t) {
    case FieldType.number:
      return TextInputType.number;
    case FieldType.email:
      return TextInputType.emailAddress;
    case FieldType.phone:
      return TextInputType.phone;
    case FieldType.cpf:
    case FieldType.cnpj:
    case FieldType.cpfCnpj:
    case FieldType.cep:
      return TextInputType.number;
    default:
      return TextInputType.text;
  }
}
