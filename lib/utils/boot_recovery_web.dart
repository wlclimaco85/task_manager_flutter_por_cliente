// Recuperação de boot — web. Limpa localStorage + IndexedDB da contingência,
// desregistra service workers (para baixar a versão nova) e recarrega.
// ignore_for_file: avoid_print, avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> limparDadosLocaisERecarregar() async {
  try {
    html.window.localStorage.clear();
  } catch (e) {
    print('[RECOVERY] localStorage.clear falhou: $e');
  }
  try {
    html.window.indexedDB?.deleteDatabase('vendas_contingencia');
  } catch (e) {
    print('[RECOVERY] deleteDatabase falhou: $e');
  }
  try {
    final sw = html.window.navigator.serviceWorker;
    if (sw != null) {
      final regs = await sw.getRegistrations();
      for (final r in regs) {
        await r.unregister();
      }
    }
  } catch (e) {
    print('[RECOVERY] unregister service worker falhou: $e');
  }
  html.window.location.reload();
}
