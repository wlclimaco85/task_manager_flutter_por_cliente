import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/api_links.dart';

const String _railway = 'https://appacademia-production-be7e.up.railway.app';

/// Regressao: desde o commit 1c3163a0 (iOS no Railway) o app passou a usar o Railway por padrao e a
/// exigir BACKEND_CONTEXT_PATH para o backend local, entao o dev local deixou de funcionar sozinho.
void main() {
  const auto = '__auto__';

  test('producao: sem defines e fora do dev local continua Railway na raiz (sem mudanca)', () {
    final r = ApiLinks.resolverBackend(
        urlDefine: '', contextPathDefine: auto, desenvolvimentoLocal: false);
    expect(r, [_railway, '']);
  });

  test('dev local automatico (web em localhost / Windows debug): backend local com /boletobancos', () {
    final r = ApiLinks.resolverBackend(
        urlDefine: '', contextPathDefine: auto, desenvolvimentoLocal: true);
    expect(r, ['http://127.0.0.1:9001', '/boletobancos']);
  });

  test('BACKEND_URL http:// informado (ex.: o .bat) ganha /boletobancos sozinho', () {
    final r = ApiLinks.resolverBackend(
        urlDefine: 'http://127.0.0.1:9001', contextPathDefine: auto, desenvolvimentoLocal: false);
    expect(r, ['http://127.0.0.1:9001', '/boletobancos']);
  });

  test('BACKEND_URL https:// (Railway) nao ganha context-path', () {
    final r = ApiLinks.resolverBackend(
        urlDefine: _railway, contextPathDefine: auto, desenvolvimentoLocal: true);
    expect(r, [_railway, '']);
  });

  test('BACKEND_CONTEXT_PATH informado sempre vale, inclusive vazio', () {
    expect(
        ApiLinks.resolverBackend(
            urlDefine: 'http://10.0.0.5:9001',
            contextPathDefine: '/outro',
            desenvolvimentoLocal: false),
        ['http://10.0.0.5:9001', '/outro']);
    expect(
        ApiLinks.resolverBackend(
            urlDefine: 'http://10.0.0.5:9001', contextPathDefine: '', desenvolvimentoLocal: false),
        ['http://10.0.0.5:9001', '']);
  });

  test('URL que ja termina em /boletobancos nao duplica o prefixo', () {
    final r = ApiLinks.resolverBackend(
        urlDefine: 'http://127.0.0.1:9001/boletobancos',
        contextPathDefine: auto,
        desenvolvimentoLocal: false);
    expect(r, ['http://127.0.0.1:9001/boletobancos', '']);
  });

  test('no flutter test (nao e web nem Windows) o ApiLinks segue o build: Railway na raiz', () {
    if (const String.fromEnvironment('BACKEND_URL').isNotEmpty) return;
    expect(ApiLinks.login, startsWith(_railway));
    expect(ApiLinks.login, isNot(contains('/boletobancos')));
  });
}
