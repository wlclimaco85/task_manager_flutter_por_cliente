import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/services/dp_exportacao_folha_service.dart';
import 'package:task_manager_flutter/utils/menu_config.dart';
import 'package:task_manager_flutter/utils/role_permission_catalog.dart';

void main() {
  test('Exportar p/ Folha aparece no catalogo dinamico de permissoes e no menu', () {
    final telas = RolePermissionCatalog.groups().expand((g) => g.entries).toList();
    final tela = telas.firstWhere((t) => t.menuItemId == 'dp_exportacao_folha');
    expect(tela.telaNome, 'dp_exportacao_folha');
    expect(MenuConfig.search('exportar').map((m) => m.id), contains('dp_exportacao_folha'));
  });

  group('DpExportacaoFolhaService', () {
    test('extrai erros do corpo 422', () {
      expect(DpExportacaoFolhaService.extrairErros('{"erros":["a","b"]}', 422), ['a', 'b']);
    });

    test('corpo invalido cai no HTTP', () {
      expect(DpExportacaoFolhaService.extrairErros('<html>', 500).single, contains('HTTP 500'));
    });

    test('nome do arquivo vem do Content-Disposition', () {
      expect(DpExportacaoFolhaService.nomeArquivo('attachment; filename=folha_dominio_2026-10.txt', 'x.txt'),
          'folha_dominio_2026-10.txt');
      expect(DpExportacaoFolhaService.nomeArquivo(null, 'x.txt'), 'x.txt');
    });

    test('mapeamento serializa codigo vazio como null', () {
      final l = DpMapeamentoLinha(eventoPonto: 'HE50', descricao: 'HE', unidade: 'HORAS', codigoEvento: ' ');
      expect(l.toJson()['codigoEvento'], isNull);
      l.codigoEvento = ' 50 ';
      expect(l.toJson()['codigoEvento'], '50');
    });
  });
}