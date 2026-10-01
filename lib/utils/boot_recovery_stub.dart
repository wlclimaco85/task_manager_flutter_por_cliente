// Recuperação de boot — plataformas nativas (mobile/windows).
// Não há reload de página; apenas limpa o storage local corrompido.
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> limparDadosLocaisERecarregar() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  } catch (_) {}
  try {
    await Hive.deleteFromDisk();
  } catch (_) {}
}
