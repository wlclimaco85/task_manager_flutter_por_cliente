import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/role_model.dart';
import 'package:task_manager_flutter/models/aplicativo_model.dart';

void main() {
  group('Role Model', () {
    test('Role model deve conter campo moduloNecessario', () {
      final role = Role(
        id: 1,
        description: 'Gerente',
        available: true,
        key: 'ROLE_GERENTE',
        moduloNecessario: 'COBRANCA',
      );

      expect(role.moduloNecessario, equals('COBRANCA'));
    });

    test('Role model suporta moduloNecessario null', () {
      final role = Role(
        id: 2,
        description: 'Admin',
        available: true,
        key: 'ROLE_ADMIN',
        moduloNecessario: null,
      );

      expect(role.moduloNecessario, isNull);
    });

    test('fromJson deve parsear moduloNecessario do JSON', () {
      final json = {
        'id': 21,
        'description': 'Gerente de Cliente',
        'key': 'ROLE_GERENTE',
        'available': true,
        'moduloNecessario': null,
        'aplicativo': {
          'id': 3,
          'nome': 'APP_ACADEMIA',
        },
      };

      final role = Role.fromJson(json);

      expect(role.id, equals(21));
      expect(role.description, equals('Gerente de Cliente'));
      expect(role.moduloNecessario, isNull);
    });

    test('fromJson deve parsear moduloNecessario quando presente', () {
      final json = {
        'id': 32,
        'description': 'Financeiro',
        'key': 'ROLE_FINANCEIRO',
        'available': true,
        'moduloNecessario': 'COBRANCA',
        'aplicativo': {
          'id': 3,
          'nome': 'APP_ACADEMIA',
        },
      };

      final role = Role.fromJson(json);

      expect(role.id, equals(32));
      expect(role.moduloNecessario, equals('COBRANCA'));
    });

    test('toJson deve serializar moduloNecessario', () {
      final role = Role(
        id: 32,
        description: 'Financeiro',
        available: true,
        key: 'ROLE_FINANCEIRO',
        moduloNecessario: 'COBRANCA',
      );

      final json = role.toJson();

      expect(json['moduloNecessario'], equals('COBRANCA'));
    });

    test('toJson deve serializar moduloNecessario como null quando apropriado', () {
      final role = Role(
        id: 21,
        description: 'Gerente',
        available: true,
        key: 'ROLE_GERENTE',
        moduloNecessario: null,
      );

      final json = role.toJson();

      expect(json['moduloNecessario'], isNull);
    });
  });
}
