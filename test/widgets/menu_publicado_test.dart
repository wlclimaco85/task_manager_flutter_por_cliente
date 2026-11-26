import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/services/menu_publicado_service.dart';
import 'package:task_manager_flutter/services/permission_service.dart';
import 'package:task_manager_flutter/utils/menu_config.dart';
import 'package:task_manager_flutter/utils/role_permission_catalog.dart';

void main() {
  tearDown(() => MenuPublicadoService.aplicarNoMenu(const []));

  test('item publicado entra no grupo, na busca e no Controle de Acesso', () {
    final fixos = MenuConfig.groups.length;
    MenuPublicadoService.aplicarNoMenu(const [
      ItemPublicado(id: 30, tipo: 'PLANILHA', refId: 5, titulo: 'Resumo Zzz Publicado', grupo: 'Sistema'),
      ItemPublicado(id: 31, tipo: 'RELATORIO', refId: 2, titulo: 'Vendas do Mes', grupo: 'Personalizados'),
    ]);

    final sistema = MenuConfig.groups.firstWhere((g) => g.label == 'Sistema');
    expect(sistema.items.map((i) => i.id), contains('pub_30'));
    expect(MenuConfig.groups.length, fixos + 1);
    expect(MenuConfig.groups.last.items.single.id, 'pub_31');
    expect(MenuConfig.fixos.expand((g) => g.items).any((i) => i.id.startsWith('pub_')), isFalse);
    expect(MenuConfig.search('zzz publicado').single.screenIndex, MenuConfig.kIndicePublicado + 30);
    expect(MenuPublicadoService.porIndice(MenuConfig.kIndicePublicado + 31)!.refId, 2);
    final entradas = RolePermissionCatalog.groups().expand((g) => g.entries);
    expect(entradas.map((e) => e.telaNome), containsAll(['pub_30', 'pub_31', 'construtor_planilhas']));
    expect(PermissionService.telaNomeForMenuItem('pub_30'), 'pub_30');
  });

  test('sem publicacao o menu e o original', () {
    expect(MenuConfig.groups, same(MenuConfig.fixos));
  });
}
