import '../models/auth_utility.dart';

class GridUserPreferencesKey {
  static const String namespace = 'grid_columns_v2';

  static String currentUserKey() {
    final userInfo = AuthUtility.userInfo;
    final login = userInfo?.login ?? userInfo?.data?.login;
    final id = login?.id ?? userInfo?.data?.id;

    if (id != null && id > 0) {
      return 'u$id';
    }

    final email = (login?.email ?? userInfo?.data?.email)?.trim().toLowerCase();
    if (email != null && email.isNotEmpty) {
      return 'e${sanitize(email)}';
    }

    return 'anon';
  }

  static String base({
    required String storageKey,
    required String title,
    String? userKey,
  }) {
    return [
      namespace,
      userKey ?? currentUserKey(),
      sanitize(storageKey),
      sanitize(title),
    ].join('__');
  }

  static String legacyBase({
    required String storageKey,
    required String title,
  }) {
    return '${storageKey}_$title';
  }

  static String storageOnlyLegacyBase(String storageKey) => storageKey;

  static String columnKey(String base, String fieldName) {
    return '${base}_${sanitize(fieldName)}';
  }

  static String legacyColumnKey(String legacyBase, String fieldName) {
    return '$legacyBase$fieldName';
  }

  static String sanitize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_@.-]+'), '_');
  }
}
