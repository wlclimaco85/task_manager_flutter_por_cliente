Future<void> downloadCsvBytes(List<int> bytes, String filename) async {
  throw UnsupportedError('CSV download only supported on web');
}

Future<void> downloadBytes(List<int> bytes, String filename,
    {String mimeType = 'application/octet-stream'}) async {
  throw UnsupportedError('Download pelo navegador so e suportado na web');
}
