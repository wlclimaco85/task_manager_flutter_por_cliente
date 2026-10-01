import '../services/permission_service.dart';
import 'menu_config.dart';

class RolePermissionMenuEntry {
  final String groupId;
  final String groupLabel;
  final String menuItemId;
  final String label;
  final String telaNome;

  const RolePermissionMenuEntry({
    required this.groupId,
    required this.groupLabel,
    required this.menuItemId,
    required this.label,
    required this.telaNome,
  });

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return label.toLowerCase().contains(normalized) ||
        groupLabel.toLowerCase().contains(normalized) ||
        menuItemId.toLowerCase().contains(normalized) ||
        telaNome.toLowerCase().contains(normalized);
  }
}

class RolePermissionGroup {
  final String id;
  final String label;
  final List<RolePermissionMenuEntry> entries;

  const RolePermissionGroup({
    required this.id,
    required this.label,
    required this.entries,
  });
}

class RolePermissionCatalog {
  RolePermissionCatalog._();

  static List<RolePermissionGroup> groups({String query = ''}) {
    final result = <RolePermissionGroup>[];

    for (final group in MenuConfig.groups) {
      final entries = group.items
          .map((item) => _entry(group.id, group.label, item))
          .whereType<RolePermissionMenuEntry>()
          .where((entry) => entry.matches(query))
          .toList();
      if (entries.isNotEmpty) {
        result.add(RolePermissionGroup(
          id: group.id,
          label: group.label,
          entries: entries,
        ));
      }
    }

    final looseEntries = MenuConfig.loose
        .map((item) => _entry('atalhos', 'Atalhos', item))
        .whereType<RolePermissionMenuEntry>()
        .where((entry) => entry.matches(query))
        .toList();
    if (looseEntries.isNotEmpty) {
      result.add(RolePermissionGroup(
        id: 'atalhos',
        label: 'Atalhos',
        entries: looseEntries,
      ));
    }

    return result;
  }

  static RolePermissionMenuEntry? _entry(
    String groupId,
    String groupLabel,
    MenuItem item,
  ) {
    final telaNome = PermissionService.telaNomeForMenuItem(item.id);
    if (telaNome == null || telaNome.isEmpty || item.screenIndex < 0) {
      return null;
    }
    return RolePermissionMenuEntry(
      groupId: groupId,
      groupLabel: groupLabel,
      menuItemId: item.id,
      label: item.label,
      telaNome: telaNome,
    );
  }
}
