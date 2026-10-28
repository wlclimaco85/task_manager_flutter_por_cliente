import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Empresa passa a ter, como o Parceiro, a aba "POP/Mail" com os dados de envio de e-mail (SMTP).
void main() {
  String ler(String caminho) =>
      File(caminho).readAsStringSync().replaceAll(RegExp(r'\s+'), ' ');

  test('detalhe de Empresa tem a aba POP/Mail ligada ao SMTP da empresa', () {
    final fonte = ler('lib/web/screens/details/empresa_detail_screen.dart');

    expect(fonte, contains("title: 'POP/Mail'"));
    expect(fonte, contains('scope: SmtpConfigScope.empresa'));
    expect(fonte, contains('id: empresaId'));
    expect(fonte, contains("import '../../../widgets/smtp_config_tab.dart';"));
  });

  test('aba da Empresa usa o endpoint /api/smtp-config/empresa do backend', () {
    final widget = ler('lib/widgets/smtp_config_tab.dart');
    final links = ler('lib/utils/api_links.dart');

    expect(widget, contains('ApiLinks.smtpConfigEmpresa(widget.id)'));
    expect(links, contains('/api/smtp-config/empresa/'));
  });
}
