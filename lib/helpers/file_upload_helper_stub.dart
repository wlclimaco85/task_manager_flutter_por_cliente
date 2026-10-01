Future<FileUploadResult?> pickAndReadFile({String accept = '.csv,.txt'}) async {
  throw UnsupportedError('File pick only supported on web');
}

class FileUploadResult {
  final String name;
  final int size;
  final List<int> bytes;
  const FileUploadResult({required this.name, required this.size, required this.bytes});
}
