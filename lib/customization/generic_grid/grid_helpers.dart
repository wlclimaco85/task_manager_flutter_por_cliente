// lib/data/customization/generic_grid/grid_helpers.dart
// -----------------------------------------------------------------------------
// 🧰 Funções utilitárias do Grid (normalização, multipart, datas, helpers, etc.)
// -----------------------------------------------------------------------------
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart' as http_parser;

// -----------------------------------------------------------------------------
// 📦 Estruturas auxiliares
// -----------------------------------------------------------------------------
class _MultipartFieldFile {
  final String fieldName;
  final PlatformFile file;
  _MultipartFieldFile({required this.fieldName, required this.file});
}

class _LocalResponse {
  final int statusCode;
  final Map<String, dynamic>? body;
  _LocalResponse({required this.statusCode, this.body});
}

// -----------------------------------------------------------------------------
// 🧩 Lookup de ContentType
// -----------------------------------------------------------------------------
http_parser.MediaType? lookupContentType(String filename) {
  final ext = filename.split('.').last.toLowerCase();
  switch (ext) {
    case 'png':
      return http_parser.MediaType('image', 'png');
    case 'jpg':
    case 'jpeg':
      return http_parser.MediaType('image', 'jpeg');
    case 'pdf':
      return http_parser.MediaType('application', 'pdf');
    case 'doc':
      return http_parser.MediaType('application', 'msword');
    case 'docx':
      return http_parser.MediaType('application',
          'vnd.openxmlformats-officedocument.wordprocessingml.document');
    default:
      return null;
  }
}

// -----------------------------------------------------------------------------
// 🧩 Extração segura de listas a partir de respostas dinâmicas
// -----------------------------------------------------------------------------
List<Map<String, dynamic>> extractAnyList(dynamic body) {
  if (body == null) return <Map<String, dynamic>>[];

  if (body is List) {
    return body
        .whereType<Map>()
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  if (body is Map) {
    final map = Map<String, dynamic>.from(body);

    final candidates = [
      map['data'],
      map['dados'],
      map['content'],
      map['items'],
      map['results'],
      map['list'],
    ];

    for (final c in candidates) {
      if (c is List) {
        return c
            .whereType<Map>()
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }

    return [map];
  }

  if (body is String) {
    try {
      return extractAnyList(jsonDecode(body));
    } catch (_) {}
  }

  return <Map<String, dynamic>>[];
}

// -----------------------------------------------------------------------------
// 🔧 Normalizadores e construtores de campos aninhados (ex: "empresa.id")
// -----------------------------------------------------------------------------
void addToFormData(Map<String, dynamic> map, String fieldName, dynamic value) {
  if (!fieldName.contains('.')) {
    map[fieldName] = value;
    return;
  }
  final parts = fieldName.split('.');
  _buildNested(map, parts, value);
}

void _buildNested(Map<String, dynamic> map, List<String> parts, dynamic value) {
  final head = parts.first;
  if (parts.length == 1) {
    map[head] = value;
    return;
  }
  map[head] =
      (map[head] is Map<String, dynamic>) ? map[head] : <String, dynamic>{};
  _buildNested(map[head] as Map<String, dynamic>, parts.sublist(1), value);
}

void addAllNested(Map<String, dynamic> target, Map<String, dynamic> src) {
  for (final e in src.entries) {
    addToFormData(target, e.key, e.value);
  }
}

Map<String, dynamic> normalizeDotted(Map<String, dynamic> input) {
  final out = <String, dynamic>{};
  for (final e in input.entries) {
    addToFormData(out, e.key, e.value);
  }
  return out;
}

// -----------------------------------------------------------------------------
// 🗓️ Conversões de data (string ⇄ ISO)
// -----------------------------------------------------------------------------
String? tryDateToIso(String input, String format) {
  try {
    final regex = RegExp(r'(\d{2})/(\d{2})/(\d{4})');
    final m = regex.firstMatch(input);
    if (m != null) {
      final d = m.group(1);
      final mo = m.group(2);
      final y = m.group(3);
      return '$y-$mo-$d';
    }
    return null;
  } catch (_) {
    return null;
  }
}

DateTime? parseDate(String v, String format) {
  if (v.isEmpty) return null;
  try {
    final parts = v.split('/');
    if (parts.length == 3) {
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    }
    return DateTime.tryParse(v);
  } catch (_) {
    return null;
  }
}

// -----------------------------------------------------------------------------
// 🧩 Manipulação segura de objetos aninhados
// -----------------------------------------------------------------------------
dynamic getNestedValue(dynamic map, String fieldName) {
  if (map == null) return null;
  if (!fieldName.contains('.')) {
    if (map is! Map) return null;
    return map[fieldName];
  }
  final parts = fieldName.split('.');
  dynamic v = map;
  for (final p in parts) {
    if (v is Map && v.containsKey(p)) {
      v = v[p];
    } else {
      return null;
    }
  }
  return v;
}

// -----------------------------------------------------------------------------
// 🧱 Helpers para multipart e responses locais
// -----------------------------------------------------------------------------
Map<String, String> flattenForMultipart(Map<String, dynamic> src) {
  final out = <String, String>{};
  void walk(String prefix, dynamic v) {
    if (v == null) return;
    if (v is Map) {
      v.forEach((k, val) {
        final key = prefix.isEmpty ? k.toString() : '$prefix.$k';
        walk(key, val);
      });
    } else {
      out[prefix] = v.toString();
    }
  }

  src.forEach((k, v) => walk(k, v));
  return out;
}
