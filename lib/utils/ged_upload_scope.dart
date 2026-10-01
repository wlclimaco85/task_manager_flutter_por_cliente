String resolveGedUploadModule(String? sourceModule) {
  final normalized = sourceModule?.trim();
  return normalized == null || normalized.isEmpty ? 'ged' : normalized;
}
