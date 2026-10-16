import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('viewer de boleto avisa quando o arquivo sumiu do servidor (404) e le a linha digitavel', () {
    final fonte = File('lib/widgets/boleto_viewer_widget.dart')
        .readAsStringSync()
        .replaceAll(RegExp(r'\s+'), ' ');

    expect(fonte, contains('resp.statusCode == 404'));
    expect(fonte, contains('Anexe o boleto novamente'));
    expect(fonte, contains('anexoFinanceiroLinhaDigitavel'));
  });
}
