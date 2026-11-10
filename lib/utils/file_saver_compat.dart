import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

import '../helpers/download_helper.dart';

enum MimeType { pdf, csv, xml, other }

class FileSaver {
  FileSaver._();

  static final FileSaver instance = FileSaver._();

  /// Contrato testavel: na web baixa pelo navegador (path_provider/File nao existem la).
  static bool? debugForcarWeb;

  Future<String> saveFile({
    required String name,
    required Uint8List bytes,
    String? fileExtension,
    MimeType? mimeType,
    Future<void> Function(List<int> bytes, String filename, String mimeType)?
        baixarNoNavegador,
  }) async {
    var fileName = name;
    if (fileExtension != null && !fileName.toLowerCase().endsWith('.$fileExtension')) {
      fileName = '$fileName.$fileExtension';
    }
    if (debugForcarWeb ?? kIsWeb) {
      final baixar = baixarNoNavegador ??
          (b, f, m) => downloadBytes(b, f, mimeType: m);
      await baixar(bytes, fileName, _mimeHttp(mimeType));
      return fileName;
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static String _mimeHttp(MimeType? mimeType) {
    switch (mimeType) {
      case MimeType.pdf:
        return 'application/pdf';
      case MimeType.csv:
        return 'text/csv';
      case MimeType.xml:
        return 'application/xml';
      default:
        return 'application/octet-stream';
    }
  }
}
