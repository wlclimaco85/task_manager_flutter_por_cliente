import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/auth_utility.dart';
import '../utils/api_links.dart';
import '../utils/grid_colors.dart';
import '../utils/tenant_context.dart';

/// Aba "Estoque" do detalhe de Produto.
///
/// Busca `GET /api/produto/{id}/detalhes` e exibe estoque atual, estoque
/// mínimo, unidade, vendas no mês e valor vendido no mês.
class ProdutoEstoqueTab extends StatefulWidget {
  final int produtoId;

  const ProdutoEstoqueTab({super.key, required this.produtoId});

  @override
  State<ProdutoEstoqueTab> createState() => _ProdutoEstoqueTabState();
}

class _ProdutoEstoqueTabState extends State<ProdutoEstoqueTab> {
  bool _carregando = true;
  Map<String, dynamic>? _detalhes;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarDetalhes();
  }

  Future<void> _carregarDetalhes() async {
    try {
      final url = TenantContext.applyToUrl(
          '${ApiLinks.baseUrl}/api/produto/${widget.produtoId}/detalhes');
      final token = AuthUtility.userInfo?.token;
      final resp = await http.get(
        Uri.parse(url),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        setState(() {
          _detalhes = body is Map<String, dynamic> ? body : {};
          _carregando = false;
        });
      } else {
        setState(() {
          _carregando = false;
          _erro = 'Erro ao carregar (${resp.statusCode})';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _erro = 'Erro ao carregar: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return Center(
        child: Text(_erro!, style: const TextStyle(color: GridColors.error)),
      );
    }

    final d = _detalhes ?? {};
    final cartoes = <_InfoCartao>[
      _InfoCartao('Estoque Atual', _formatarNumero(d['estoque']),
          d['unidade']?.toString(), Icons.inventory_2),
      _InfoCartao('Estoque Mínimo', _formatarNumero(d['estoqueMinimo']),
          d['unidade']?.toString(), Icons.warning_amber),
      _InfoCartao('Unidade', d['unidade']?.toString() ?? '-', null,
          Icons.straighten),
      _InfoCartao('Vendas no Mês', d['vendasMes']?.toString() ?? '0', null,
          Icons.shopping_cart),
      _InfoCartao('Valor Vendido no Mês',
          _formatarMoeda(d['valorVendasMes']), null, Icons.attach_money),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: cartoes.map(_buildCartao).toList(),
      ),
    );
  }

  Widget _buildCartao(_InfoCartao info) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GridColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(info.icone, size: 18, color: GridColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  info.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: GridColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            info.unidade != null ? '${info.valor} ${info.unidade}' : info.valor,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatarNumero(dynamic valor) {
    if (valor == null) return '0';
    final v = double.tryParse(valor.toString()) ?? 0.0;
    return v.toStringAsFixed(3);
  }

  String _formatarMoeda(dynamic valor) {
    if (valor == null) return 'R\$ 0,00';
    final v = double.tryParse(valor.toString()) ?? 0.0;
    return 'R\$ ${v.toStringAsFixed(2)}';
  }
}

class _InfoCartao {
  final String label;
  final String valor;
  final String? unidade;
  final IconData icone;

  const _InfoCartao(this.label, this.valor, this.unidade, this.icone);
}

/// Tipo de operação das notas exibidas: ENTRADA (compras) ou SAIDA (vendas).
enum TipoOperacaoNota { entrada, saida }

/// Aba "Notas de Compras"/"Notas de Saídas" do detalhe de Produto.
///
/// Busca `GET /api/produto/{id}/notas?tipoOperacao=...` (paginado) e exibe
/// uma tabela com número, série, data, parceiro, quantidade, valor unitário
/// e valor total.
class ProdutoNotasTab extends StatefulWidget {
  final int produtoId;
  final TipoOperacaoNota tipoOperacao;

  const ProdutoNotasTab({
    super.key,
    required this.produtoId,
    required this.tipoOperacao,
  });

  @override
  State<ProdutoNotasTab> createState() => _ProdutoNotasTabState();
}

class _ProdutoNotasTabState extends State<ProdutoNotasTab> {
  static const int _tamanhoPagina = 50;

  bool _carregando = true;
  List<Map<String, dynamic>> _notas = [];
  String? _erro;

  String get _tipoOperacaoParam =>
      widget.tipoOperacao == TipoOperacaoNota.entrada ? 'ENTRADA' : 'SAIDA';

  String get _rotuloParceiro =>
      widget.tipoOperacao == TipoOperacaoNota.entrada ? 'Fornecedor' : 'Cliente';

  String get _mensagemVazia => widget.tipoOperacao == TipoOperacaoNota.entrada
      ? 'Nenhuma nota de compra encontrada.'
      : 'Nenhuma nota de saída encontrada.';

  @override
  void initState() {
    super.initState();
    _carregarNotas();
  }

  Future<void> _carregarNotas() async {
    try {
      final url = TenantContext.applyToUrl(
          '${ApiLinks.baseUrl}/api/produto/${widget.produtoId}/notas'
          '?tipoOperacao=$_tipoOperacaoParam&pagina=0&tamanho=$_tamanhoPagina');
      final token = AuthUtility.userInfo?.token;
      final resp = await http.get(
        Uri.parse(url),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final content = body is Map && body['content'] is List
            ? body['content'] as List
            : <dynamic>[];
        setState(() {
          _notas = content.map((e) => Map<String, dynamic>.from(e)).toList();
          _carregando = false;
        });
      } else {
        setState(() {
          _carregando = false;
          _erro = 'Erro ao carregar (${resp.statusCode})';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _erro = 'Erro ao carregar: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return Center(
        child: Text(_erro!, style: const TextStyle(color: GridColors.error)),
      );
    }
    if (_notas.isEmpty) {
      return Center(
        child: Text(_mensagemVazia,
            style: const TextStyle(color: GridColors.textMuted)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingRowColor: WidgetStateProperty.all(
              GridColors.secondary.withValues(alpha: 0.1)),
          columns: [
            const DataColumn(
                label: Text('Número',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(
                label: Text('Série',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(
                label: Text('Data',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text(_rotuloParceiro,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(
                label: Text('Quantidade',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                numeric: true),
            const DataColumn(
                label: Text('Valor Unitário',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                numeric: true),
            const DataColumn(
                label: Text('Valor Total',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                numeric: true),
          ],
          rows: _notas.map(_buildLinha).toList(),
        ),
      ),
    );
  }

  DataRow _buildLinha(Map<String, dynamic> nota) {
    return DataRow(cells: [
      DataCell(Text(nota['numero']?.toString() ?? '-')),
      DataCell(Text(nota['serie']?.toString() ?? '-')),
      DataCell(Text(_formatarData(nota['dataEmissao']))),
      DataCell(Text(nota['parceiroNome']?.toString() ?? '-')),
      DataCell(Text(_formatarNumero(nota['quantidade']))),
      DataCell(Text(_formatarMoeda(nota['valorUnitario']))),
      DataCell(Text(_formatarMoeda(nota['valorTotal']))),
    ]);
  }

  String _formatarData(dynamic valor) {
    if (valor == null) return '-';
    final data = DateTime.tryParse(valor.toString());
    if (data == null) return valor.toString();
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  String _formatarNumero(dynamic valor) {
    if (valor == null) return '0';
    final v = double.tryParse(valor.toString()) ?? 0.0;
    return v.toStringAsFixed(3);
  }

  String _formatarMoeda(dynamic valor) {
    if (valor == null) return 'R\$ 0,00';
    final v = double.tryParse(valor.toString()) ?? 0.0;
    return 'R\$ ${v.toStringAsFixed(2)}';
  }
}
