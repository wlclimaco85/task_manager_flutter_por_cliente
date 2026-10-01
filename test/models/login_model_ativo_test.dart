import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/login_model.dart';

/// Bug de produção: o checkbox "Ativo" na tela de Cadastro do Login sempre
/// voltava desmarcado ao reabrir/recarregar o registro, mesmo depois de
/// clicar "Salvar alterações" e ver "Salvo com sucesso".
///
/// Causa raiz (parte frontend): `Login.fromJson`/`toJson` nunca carregavam o
/// campo `ativo` -- ele existia no JSON bruto vindo do backend, mas ao
/// converter para `Login` (fromJson) e depois de volta pra JSON (toJson,
/// usado por WebLoginDetailScreen/WindowsLoginDetailScreen para alimentar o
/// GenericDetailFormScreen), o valor era descartado nesse round-trip antes
/// mesmo do formulário genérico enxergar o dado.
///
/// (Causa raiz backend, corrigida em paralelo: a coluna `ativo` não existia
/// em `login` e LoginController nunca lia esse campo do payload de
/// criação/atualização -- ver V20261006__Add_ativo_login.sql, Login.java e
/// LoginController.java.)
void main() {
  group('Login.ativo — round-trip fromJson/toJson', () {
    test('ativo=true sobrevive ao round-trip fromJson -> toJson', () {
      final login = Login.fromJson({'id': 1, 'nome': 'Teste', 'ativo': true});

      expect(login.ativo, isTrue);
      expect(login.toJson()['ativo'], isTrue);
    });

    test('ativo=false sobrevive ao round-trip fromJson -> toJson', () {
      final login =
          Login.fromJson({'id': 1, 'nome': 'Teste', 'ativo': false});

      expect(login.ativo, isFalse);
      expect(login.toJson()['ativo'], isFalse);
    });

    test('ativo ausente no JSON do backend não vira false (evita PUT '
        'sobrescrever um valor que nunca foi carregado)', () {
      final login = Login.fromJson({'id': 1, 'nome': 'Teste'});

      expect(login.ativo, isNull);
      expect(login.toJson()['ativo'], isNull);
    });
  });
}
