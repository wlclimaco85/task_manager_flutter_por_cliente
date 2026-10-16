import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Bug (2026-10-16): na web, baixar comprovante/boleto dava MissingPluginException
/// (path_provider nao existe no navegador) e o viewer de boleto so fingia "Download iniciado".
void main() {
  String ler(String caminho) =>
      File(caminho).readAsStringSync().replaceAll(RegExp(r'\s+'), ' ');

  test('widgets de anexo baixam pelo navegador na web, antes de usar getTemporaryDirectory', () {
    for (final caminho in [
      'lib/widgets/anexo_financeiro_widget.dart',
      'lib/widgets/anexos_lista_widget.dart',
      'lib/widgets/boleto_viewer_widget.dart',
    ]) {
      final fonte = ler(caminho);
      expect(fonte, contains('downloadBytes('), reason: caminho);
      expect(fonte.indexOf('downloadBytes('),
          lessThan(fonte.indexOf('getTemporaryDirectory()')),
          reason: '$caminho: web nao pode chegar em getTemporaryDirectory');
    }
  });

  test('helper de download expoe downloadBytes na web e no stub', () {
    expect(ler('lib/helpers/download_helper_web.dart'), contains('downloadBytes('));
    expect(ler('lib/helpers/download_helper_stub.dart'), contains('downloadBytes('));
  });
}
