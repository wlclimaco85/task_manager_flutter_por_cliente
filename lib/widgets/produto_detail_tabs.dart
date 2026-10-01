import 'package:flutter/material.dart';

import 'generic_detail_form_screen.dart';
import 'produto_impostos_tab.dart';
import 'produto_notas_tab.dart';

List<RelatedGridTab> buildProdutoRelatedTabs(int produtoId) {
  final idIndisponivel =
      const Center(child: Text('ID do produto nao disponivel'));

  return [
    RelatedGridTab(
      title: 'Tributos',
      icon: Icons.receipt_long,
      customWidget: produtoId > 0
          ? ProdutoImpostosTab(produtoId: produtoId)
          : idIndisponivel,
    ),
    RelatedGridTab(
      title: 'Estoque',
      icon: Icons.inventory_2,
      customWidget: produtoId > 0
          ? ProdutoEstoqueTab(produtoId: produtoId)
          : idIndisponivel,
    ),
    RelatedGridTab(
      title: 'Notas de Compras',
      icon: Icons.shopping_cart,
      customWidget: produtoId > 0
          ? ProdutoNotasTab(
              produtoId: produtoId,
              tipoOperacao: TipoOperacaoNota.entrada,
            )
          : idIndisponivel,
    ),
    RelatedGridTab(
      title: 'Notas de Saidas',
      icon: Icons.local_shipping,
      customWidget: produtoId > 0
          ? ProdutoNotasTab(
              produtoId: produtoId,
              tipoOperacao: TipoOperacaoNota.saida,
            )
          : idIndisponivel,
    ),
  ];
}
