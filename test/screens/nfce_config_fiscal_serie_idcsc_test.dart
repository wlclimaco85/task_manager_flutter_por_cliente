import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Bug: "value too long for type character varying(6)" ao salvar a config fiscal NFC-e:
  // o ID CSC (coluna id_csc varchar(6)) aceitava qualquer tamanho. A serie agora e um
  // dropdown com as series NFC-e cadastradas para o cliente (tela de Series).
  for (final plataforma in ['web', 'windows']) {
    test('config fiscal NFC-e ($plataforma): ID CSC limitado a 6 e serie via dropdown', () {
      final fonte = File('lib/$plataforma/screens/nfce/config_fiscal_screen.dart')
          .readAsStringSync();

      expect(fonte, contains('maxLength: 6'));
      expect(fonte, contains('O ID CSC tem no maximo 6 caracteres.'));
      expect(fonte, contains("labelText: 'ID CSC'"));

      final trechoSerie = fonte.substring(fonte.indexOf("label: 'Série NFC-e'") - 200);
      expect(trechoSerie, contains('SearchableDropdownField('));
      expect(trechoSerie, contains('items: _opcoesSerie'));
      expect(fonte, contains("tipo != 'NFC-E' && tipo != 'NFCE'"));
      expect(fonte, isNot(contains("decoration: const InputDecoration(\n                      labelText: 'Série NFC-e'")));
    });
  }
}
