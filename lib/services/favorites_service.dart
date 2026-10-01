import 'package:shared_preferences/shared_preferences.dart';

/// Serviço de favoritos — persiste por usuário em SharedPreferences
class FavoritesService {
  FavoritesService._();

  static const _prefix = 'favoritos_';

  static String _key(String userId) => '$_prefix$userId';

  /// Carrega os IDs favoritos do usuário
  static Future<Set<String>> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key(userId)) ?? [];
    return list.toSet();
  }

  /// Salva os IDs favoritos do usuário
  static Future<void> save(String userId, Set<String> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key(userId), favorites.toList());
  }

  /// Alterna favorito — retorna o novo estado (true = favoritado)
  static Future<bool> toggle(String userId, String itemId) async {
    final favs = await load(userId);
    if (favs.contains(itemId)) {
      favs.remove(itemId);
    } else {
      favs.add(itemId);
    }
    await save(userId, favs);
    return favs.contains(itemId);
  }

  /// Verifica se um item é favorito
  static Future<bool> isFavorite(String userId, String itemId) async {
    final favs = await load(userId);
    return favs.contains(itemId);
  }
}
