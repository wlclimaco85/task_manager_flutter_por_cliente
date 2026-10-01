// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

class FileUploadResult {
  final String name;
  final int size;
  final List<int> bytes;
  const FileUploadResult({required this.name, required this.size, required this.bytes});
}

Future<FileUploadResult?> pickAndReadFile({String accept = '.csv,.txt'}) async {
  final input = html.FileUploadInputElement()
    ..accept = accept
    ..multiple = false;
  input.click();
  await input.onChange.first;
  final files = input.files;
  if (files == null || files.isEmpty) return null;

  final file = files.first;
  final reader = html.FileReader()..readAsArrayBuffer(file);
  await reader.onLoadEnd.first;
  final raw = reader.result;
  final bytes = raw is ByteBuffer
      ? raw.asUint8List()
      : raw is Uint8List
          ? raw
          : Uint8List.fromList(raw is List<int> ? raw : const <int>[]);
  return FileUploadResult(name: file.name, size: file.size, bytes: bytes);
}
