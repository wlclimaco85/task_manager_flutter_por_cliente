import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/parceiro_model.dart';
import 'package:task_manager_flutter/models/regime_tributario_model.dart';

void main() {
  group('Parceiro dados fiscais para NF-e', () {
    test('toJson envia regime e campos fiscais usados na emissao', () {
      final parceiro = Parceiro(
        nome: 'BRASIL MODA SURF LTDA',
        cpf: '38504935000111',
        razaoSocial: 'BRASIL MODA SURF LTDA',
        regime: RegimeTributario(
          id: 1,
          codigo: 'SN',
          descricao: 'Simples Nacional',
        ),
        ie: '123456789',
        ambiente: 'HOMOLOGACAO',
        cep: '38050440',
        rua: 'Rua Rio Grande do Norte',
        numero: '360',
        bairro: 'Santa Maria',
        cidade: 'Uberaba',
        estado: 'MG',
      );

      final json = parceiro.toJson();

      expect(json['regime'], isA<Map<String, dynamic>>());
      expect(json['regime']['id'], 1);
      expect(json['ambiente'], 'HOMOLOGACAO');
      expect(json['ie'], '123456789');
      expect(json['cep'], '38050440');
      expect(json['rua'], 'Rua Rio Grande do Norte');
      expect(json['numero'], '360');
      expect(json['bairro'], 'Santa Maria');
      expect(json['cidade'], 'Uberaba');
      expect(json['estado'], 'MG');
    });

    test('fieldConfigs marca como obrigatorios os dados minimos do emitente',
        () {
      final requiredFields = Parceiro.fieldConfigsWindows()
          .where((field) => field.isRequired)
          .map((field) => field.fieldName)
          .toSet();

      expect(
        requiredFields,
        containsAll({
          'nome',
          'cpf',
          'razaoSocial',
          'regime',
          'ambiente',
          'ie',
          'cep',
          'rua',
          'numero',
          'bairro',
          'cidade',
          'estado',
        }),
      );
    });
  });
}
