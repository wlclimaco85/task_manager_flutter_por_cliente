// test/utils/api_links_production_context_path_test.dart
//
// Regressão dedicada do incidente P0 2026-08-21: entre 2026-08-14 e
// 2026-08-21, ApiLinks anexava /boletobancos SOMENTE quando o backend era
// "local" (detectado por não começar com "https://"). Todo backend de
// produção é https:// — então em produção o prefixo NUNCA era anexado,
// quebrando /rest/auth/login (e toda outra rota) silenciosamente, com o
// navegador reportando "bloqueado por CORS" (mensagem genérica do Chrome
// para fetch cross-origin sem resposta, mascarando a causa real: 404 do
// Tomcat fora do context-path, antes até de chegar no CorsFilter do Spring).
//
// IMPORTANTE: este arquivo só exercita o cenário de produção de verdade
// quando rodado com o dart-define de produção, porque `_backendUrl` é um
// `String.fromEnvironment` const (resolvido em tempo de compilação, não dá
// pra trocar em runtime dentro do teste). Rodar assim:
//
//   flutter test --dart-define=BACKEND_URL=https://appacademia-production-be7e.up.railway.app \
//       test/utils/api_links_production_context_path_test.dart
//
// Sem esse dart-define, os testes abaixo usam o default local
// (http://127.0.0.1:9001) e ainda validam que o context-path está presente
// — mas a validação forte "backend é https" só ocorre com o comando acima
// (ver `tests.yml`, step "Flutter test — cenário de producao (context-path)").

import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/api_links.dart';

const String _backendUrlUsadoNoBuild = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://127.0.0.1:9001',
);

void main() {
  group('ApiLinks — context-path /boletobancos sempre anexado', () {
    test('login sempre contém /boletobancos, independente do esquema do backend', () {
      expect(ApiLinks.login, contains('/boletobancos/rest/auth/login'));
    });

    test('login NUNCA reproduz o bug do incidente P0 2026-08-21 '
        '(URL sem /boletobancos logo após o host)', () {
      // Bug real reportado em producao: POST para
      // https://appacademia-production-be7e.up.railway.app/rest/auth/login
      // (sem /boletobancos) bloqueado no preflight CORS pelo navegador,
      // porque o Tomcat devolve 404 fora do context-path.
      expect(
        ApiLinks.login,
        isNot(equals('$_backendUrlUsadoNoBuild/rest/auth/login')),
        reason: 'Login sem /boletobancos reproduziria o incidente P0 '
            '2026-08-21 (escritorio-contabil-production.up.railway.app).',
      );
    });

    test('baseUrl sempre termina com /boletobancos', () {
      expect(ApiLinks.baseUrl, endsWith('/boletobancos'));
    });

    // Quando o teste roda com --dart-define=BACKEND_URL=https://... (ver
    // instrução no topo do arquivo), este bloco valida especificamente o
    // cenário de producao real: esquema https E context-path presente na
    // posição correta, batendo com o endpoint real do backend
    // (AuthController: @RequestMapping("/rest/auth") + @PostMapping("/login"),
    // sob server.servlet.context-path=/boletobancos).
    test('cenario de producao (https): login bate com /boletobancos/rest/auth/login', () {
      final backendEhProducaoHttps = _backendUrlUsadoNoBuild.startsWith('https://');

      expect(
        ApiLinks.login,
        equals('$_backendUrlUsadoNoBuild/boletobancos/rest/auth/login'),
      );

      if (backendEhProducaoHttps) {
        // Só roda de fato quando invocado com o dart-define de producao
        // (ver cabecalho do arquivo) — confirma o cenario exato do incidente.
        expect(ApiLinks.login, startsWith('https://'));
        expect(ApiLinks.login, contains('/boletobancos/rest/auth/login'));
      }
    });
  });
}
