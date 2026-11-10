// test/utils/api_links_production_context_path_test.dart
//
// Regressao do context-path do ApiLinks (incidente P0 2026-08-21, que quebrou
// login em producao quando o prefixo /boletobancos ficou condicional).
//
// Desde o commit 1c3163a0 (iOS apontando para o Railway) o padrao e:
//   - BACKEND_URL padrao = https://appacademia-production-be7e.up.railway.app
//   - BACKEND_CONTEXT_PATH padrao = '' (Railway atende na raiz; /boletobancos
//     devolve 308). Backend local so usa o prefixo quando o build passa
//     --dart-define=BACKEND_CONTEXT_PATH=/boletobancos.
//
// Os valores sao const (String.fromEnvironment), entao este arquivo valida o
// que foi compilado. Para validar o cenario local:
//
//   flutter test --dart-define=BACKEND_URL=http://127.0.0.1:9001 \
//       --dart-define=BACKEND_CONTEXT_PATH=/boletobancos \
//       test/utils/api_links_production_context_path_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/api_links.dart';

const String _backendUsadoNoBuild = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'https://appacademia-production-be7e.up.railway.app',
);
const String _contextPathUsadoNoBuild = String.fromEnvironment(
  'BACKEND_CONTEXT_PATH',
  defaultValue: '',
);

void main() {
  group('ApiLinks — context-path segue a configuracao do build', () {
    test('login = backend + context-path configurado + /rest/auth/login', () {
      expect(
        ApiLinks.login,
        equals('$_backendUsadoNoBuild$_contextPathUsadoNoBuild/rest/auth/login'),
      );
    });

    test('baseUrl = backend + context-path configurado', () {
      expect(
        ApiLinks.baseUrl,
        equals('$_backendUsadoNoBuild$_contextPathUsadoNoBuild'),
      );
    });

    test('padrao de producao (Railway na raiz): login sem /boletobancos', () {
      if (_contextPathUsadoNoBuild.isNotEmpty) {
        return; // build com context-path explicito (ex.: backend local)
      }
      expect(ApiLinks.login, startsWith('https://'));
      expect(ApiLinks.login, isNot(contains('/boletobancos')));
    });
  });
}
