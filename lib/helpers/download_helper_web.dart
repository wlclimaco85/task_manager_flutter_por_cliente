// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> downloadCsvBytes(List<int> bytes, String filename) async {
  final blob = html.Blob([bytes], 'text/csv');
  final urlBlob = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: urlBlob)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(urlBlob);
}
