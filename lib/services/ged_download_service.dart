import 'dart:io';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

typedef GedDownloadRequest = Future<http.Response> Function(
  Uri uri,
  Map<String, String> headers,
);

class GedDownloadException implements Exception {
  final int statusCode;
  const GedDownloadException(this.statusCode);
  @override
  String toString() => 'Falha ao baixar arquivo (HTTP $statusCode)';
}

class GedDownloadService {
  final GedDownloadRequest _request;
  final Future<Directory> Function() _temporaryDirectory;
  final Future<void> Function(String path, String fileName) _share;

  GedDownloadService({
    GedDownloadRequest? request,
    Future<Directory> Function()? temporaryDirectory,
    Future<void> Function(String path, String fileName)? share,
  })  : _request =
            request ?? ((uri, headers) => http.get(uri, headers: headers)),
        _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
        _share = share ?? _shareFile;

  Future<String> download(int fileId, String fileName) async {
    final response = await _request(
      Uri.parse(TenantContext.applyToUrl(ApiLinks.downloadArquivo('$fileId'))),
      TenantContext.headers,
    );
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw GedDownloadException(response.statusCode);
    }
    final safeName = _safeFileName(fileName, fileId);
    final directory = await _temporaryDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$safeName');
    await file.writeAsBytes(response.bodyBytes);
    await _share(file.path, safeName);
    return file.path;
  }

  static String _safeFileName(String fileName, int fileId) {
    final normalized = fileName.trim().replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return normalized.isEmpty ? 'arquivo_$fileId' : normalized;
  }

  static Future<void> _shareFile(String path, String fileName) async {
    await Share.shareXFiles(
      [XFile(path, name: fileName)],
      sharePositionOrigin: ui.Rect.largest,
    );
  }
}
