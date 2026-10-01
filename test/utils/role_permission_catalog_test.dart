import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/menu_config.dart';
import 'package:task_manager_flutter/utils/role_permission_catalog.dart';

void main() {
  test('catalogo de permissoes usa menus reais agrupados e pesquisaveis', () {
    final grupos = RolePermissionCatalog.groups();
    final todasAsTelas = grupos.expand((grupo) => grupo.entries).toList();

    final financeiro =
        grupos.firstWhere((grupo) => grupo.label == 'Financeiro');
    final contasPagar = financeiro.entries.firstWhere(
      (tela) => tela.menuItemId == 'contas_pagar',
    );

    expect(contasPagar.label, 'Contas a Pagar');
    expect(contasPagar.telaNome, 'ContasPagar');
    expect(
      todasAsTelas.any(
        (tela) => tela.label.toLowerCase().contains('gerada automaticamente'),
      ),
      isFalse,
    );

    final filtrados = RolePermissionCatalog.groups(query: 'pagar')
        .expand((grupo) => grupo.entries)
        .map((tela) => tela.label);

    expect(filtrados, contains('Contas a Pagar'));
  });

  test('catalogo de permissoes cobre todos os itens reais do menu', () {
    final itensDoMenu = [
      ...MenuConfig.groups.expand((grupo) => grupo.items),
      ...MenuConfig.loose,
    ].where((item) => item.screenIndex >= 0).map((item) => item.id).toSet();

    final itensDoCatalogo = RolePermissionCatalog.groups()
        .expand((grupo) => grupo.entries)
        .map((tela) => tela.menuItemId)
        .toSet();

    expect(itensDoCatalogo, containsAll(itensDoMenu));
  });

  // Pedido explicito do usuario (2026-09-18): o menu antigo "Fiscal / NFC-e"
  // misturava NF-e, NFS-e e NFC-e juntos, dificultando achar cada tela --
  // separado em 3 grupos dedicados. O que e' comum aos tres (Série,
  // Dashboard Fiscal) ficou no grupo Comercial.
  test('catalogo de permissoes separa NF-e, NFS-e e NFC-e em grupos proprios',
      () {
    final grupos = RolePermissionCatalog.groups();

    final nfe = grupos.firstWhere((grupo) => grupo.label == 'NF-e');
    final telasNfe = nfe.entries.map((tela) => tela.label).toSet();
    expect(telasNfe, contains('NF-e Entrada'));
    expect(telasNfe, contains('NF-e Saída'));
    expect(telasNfe, contains('Consulta DF-e'));
    expect(telasNfe, contains('Manifestação Destinatário'));
    expect(telasNfe, contains('Cancelamento e CC-e'));
    expect(telasNfe, contains('Agendar NFe Recorrente'));

    final nfse = grupos.firstWhere((grupo) => grupo.label == 'NFS-e');
    final telasNfse = nfse.entries.map((tela) => tela.label).toSet();
    expect(telasNfse, contains('NFSe'));
    expect(telasNfse, contains('Importar XML NFS-e'));

    final nfce = grupos.firstWhere((grupo) => grupo.label == 'NFC-e');
    final telasNfce = nfce.entries.map((tela) => tela.label).toSet();
    expect(telasNfce, contains('PDV / NFC-e'));
    expect(telasNfce, contains('NFC-e (Cupons)'));
    expect(telasNfce, contains('Config. Fiscal'));

    final comercial = grupos.firstWhere((grupo) => grupo.label == 'Comercial');
    final telasComercial = comercial.entries.map((tela) => tela.label).toSet();
    expect(telasComercial, contains('NF-e Série'));
    expect(telasComercial, contains('Séries NFS-e'));
    expect(telasComercial, contains('Dashboard Fiscal'));
  });

  // Bug de producao (2026-09-16, ver bugs.md): "NFC-e (Cupons)" e "Envio EDI
  // (Remessa)" foram criadas e ganharam permissao manual via INSERT direto
  // em role_permissao pra 2 roles especificas (nao dinamico, nao aparecia
  // em Controle de Acesso pras demais roles) -- faltava a entrada em
  // PermissionService._menuIdToTelaNome, unico requisito real pra uma tela
  // aparecer na grade dinamica de Permissoes (RolePermissionCatalog).
  test('catalogo de permissoes mostra NFC-e (Cupons) e Envio EDI (Remessa)',
      () {
    final todasAsTelas = RolePermissionCatalog.groups()
        .expand((grupo) => grupo.entries)
        .toList();

    final nfceGrid =
        todasAsTelas.firstWhere((tela) => tela.menuItemId == 'nfce_grid');
    expect(nfceGrid.label, 'NFC-e (Cupons)');
    expect(nfceGrid.telaNome, 'nfce_grid');

    final cnabRemessa =
        todasAsTelas.firstWhere((tela) => tela.menuItemId == 'cnab_remessa');
    expect(cnabRemessa.label, 'Envio EDI (Remessa)');
    expect(cnabRemessa.telaNome, 'cnab_remessa');
  });

  // Bug de producao (2026-09-16, ver bugs.md): o dropdown "Serie" ao emitir
  // NFSe buscava em /api/nfse-serie (tabela separada de nfe_serie), sempre
  // vazio porque nao havia tela Web/Windows pra cadastrar essa serie -- so'
  // o Mobile tinha. Nova tela 'nfse_serie' criada (Web/Windows), reaproveita
  // a tela dinamica ja existente no backend (mesma estrutura de nfe_serie).
  test('catalogo de permissoes mostra Séries NFS-e', () {
    final nfseSerie = RolePermissionCatalog.groups()
        .expand((grupo) => grupo.entries)
        .firstWhere((tela) => tela.menuItemId == 'nfse_serie');

    expect(nfseSerie.label, 'Séries NFS-e');
    expect(nfseSerie.telaNome, 'nfse_serie');
  });

  // Card: Importacao de XML de NFS-e -- mesma regra "toda tela nova tem
  // que aparecer em Controle de Acesso" ja documentada no CLAUDE.md pros
  // casos de nfce_grid/cnab_remessa acima.
  test('catalogo de permissoes mostra Importar XML NFS-e', () {
    final nfseImportXml = RolePermissionCatalog.groups()
        .expand((grupo) => grupo.entries)
        .firstWhere((tela) => tela.menuItemId == 'nfse_import_xml');

    expect(nfseImportXml.label, 'Importar XML NFS-e');
    expect(nfseImportXml.telaNome, 'nfse_import_xml');
  });

  test('catalogo de permissoes mostra telas de aprovacao de acesso', () {
    final porAcesso = RolePermissionCatalog.groups(query: 'acesso')
        .expand((grupo) => grupo.entries)
        .toList();
    final porPermissao = RolePermissionCatalog.groups(query: 'permi')
        .expand((grupo) => grupo.entries)
        .toList();

    expect(
      porAcesso.map((tela) => tela.label),
      contains('Solicitações de Acesso'),
    );
    expect(
      porPermissao.map((tela) => tela.label),
      contains('Permissões Multi-Empresa'),
    );
    expect(
      porPermissao
          .firstWhere((tela) => tela.menuItemId == 'permissoes_multi_empresa')
          .telaNome,
      'PermissoesMultiEmpresa',
    );
  });
}
