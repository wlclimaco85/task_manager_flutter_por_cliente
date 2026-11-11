import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import '../utils/grid_colors.dart';

/// Busca os módulos pagos cadastrados no Painel do Dono (endpoint público
/// `GET /api/public/modulos`, apenas módulos ativos).
Future<List<Map<String, dynamic>>> carregarModulosPublicos() async {
  final res = await http
      .get(Uri.parse('${ApiLinks.baseUrl}/api/public/modulos'))
      .timeout(const Duration(seconds: 10));
  if (res.statusCode != 200) {
    throw Exception('HTTP ${res.statusCode}');
  }
  final data = jsonDecode(utf8.decode(res.bodyBytes));
  if (data is! List) return const [];
  return data.whereType<Map<String, dynamic>>().toList();
}

/// Vitrine de módulos da tela de login (propaganda): o que já vem no sistema
/// e os módulos opcionais/pagos cadastrados no Painel do Dono.
class LoginModulosVitrine extends StatefulWidget {
  final double maxWidth;
  final Future<List<Map<String, dynamic>>> Function() carregar;

  const LoginModulosVitrine({
    super.key,
    required this.maxWidth,
    this.carregar = carregarModulosPublicos,
  });

  /// Funcionalidades base do Conta Própria (propaganda do que já está incluso).
  static const List<ModuloVitrine> inclusos = [
    ModuloVitrine('Fluxo de caixa',
        'Extrato unificado, importação e conciliação do seu caixa.',
        Icons.account_balance_wallet_outlined),
    ModuloVitrine('Pagar e receber',
        'Vencimentos, baixas e visão clara do que entra e sai.',
        Icons.payments_outlined),
    ModuloVitrine('Contatos',
        'Clientes e fornecedores em um só cadastro.',
        Icons.contacts_outlined),
    ModuloVitrine('Produtos e serviços',
        'Catálogo com preços, estoque e dados fiscais.',
        Icons.inventory_2_outlined),
    ModuloVitrine('DRE',
        'Resultado do negócio mês a mês, sem planilha.',
        Icons.stacked_line_chart_outlined),
    ModuloVitrine('Vendas e emissão',
        'Pedidos, cupons e notas direto do sistema.',
        Icons.point_of_sale_outlined),
  ];

  @override
  State<LoginModulosVitrine> createState() => _LoginModulosVitrineState();
}

/// Ícone da vitrine por palavra-chave do nome do módulo.
IconData iconeParaModulo(String nome) => _LoginModulosVitrineState._icone(nome);

class ModuloVitrine {
  final String titulo;
  final String descricao;
  final IconData icone;
  final double? valorMensal;
  const ModuloVitrine(this.titulo, this.descricao, this.icone,
      {this.valorMensal});
}

class _LoginModulosVitrineState extends State<LoginModulosVitrine> {
  List<ModuloVitrine> _opcionais = const [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final lista = await widget.carregar();
      if (!mounted) return;
      setState(() => _opcionais = lista.map(_paraModulo).toList());
    } catch (e) {
      // Vitrine é opcional: sem rede/endpoint, apenas não exibe os pagos.
      AppLogger.i.warn('Vitrine de módulos do login indisponível: $e');
    }
  }

  static ModuloVitrine _paraModulo(Map<String, dynamic> m) {
    final nome = (m['nome'] ?? '').toString();
    final valor = double.tryParse((m['valorMensal'] ?? '').toString());
    return ModuloVitrine(
      nome,
      (m['descricao'] ?? '').toString(),
      _icone(nome),
      valorMensal: (valor != null && valor > 0) ? valor : null,
    );
  }

  static IconData _icone(String nome) {
    final n = nome.toLowerCase();
    if (n.contains('nfc')) return Icons.point_of_sale_outlined;
    if (n.contains('nfs')) return Icons.description_outlined;
    if (n.contains('fiscal') || n.contains('nf-e') || n.contains('nfe')) {
      return Icons.receipt_long_outlined;
    }
    if (n.contains('transporte') || n.contains('mdf') || n.contains('ct-e')) {
      return Icons.local_shipping_outlined;
    }
    if (n.contains('estoque')) return Icons.inventory_2_outlined;
    if (n.contains('dre')) return Icons.stacked_line_chart_outlined;
    if (n.contains('financeiro')) return Icons.insights_outlined;
    if (n.contains('precifica')) return Icons.sell_outlined;
    if (n.contains('service desk') || n.contains('suporte')) {
      return Icons.headset_mic_outlined;
    }
    if (n.contains('projeto')) return Icons.account_tree_outlined;
    if (n.contains('gme')) return Icons.storefront_outlined;
    return Icons.extension_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titulo('Já vem no sistema'),
          const SizedBox(height: 10),
          _grade(LoginModulosVitrine.inclusos, 'Incluso'),
          if (_opcionais.isNotEmpty) ...[
            const SizedBox(height: 24),
            _titulo('Módulos que podem ser contratados'),
            const SizedBox(height: 10),
            _grade(_opcionais, 'Opcional'),
          ],
        ],
      ),
    );
  }

  Widget _titulo(String texto) => Text(
        texto,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      );

  Widget _grade(List<ModuloVitrine> itens, String selo) {
    return LayoutBuilder(builder: (context, c) {
      final largura = c.maxWidth.isFinite ? c.maxWidth : widget.maxWidth;
      final colunas =
          largura >= 900 ? 4 : (largura >= 600 ? 3 : (largura >= 400 ? 2 : 1));
      const espaco = 10.0;
      final itemW = (largura - espaco * (colunas - 1)) / colunas;
      return Wrap(
        spacing: espaco,
        runSpacing: espaco,
        children: [
          for (final m in itens)
            SizedBox(width: itemW, child: _CartaoModulo(modulo: m, selo: selo)),
        ],
      );
    });
  }
}

class _CartaoModulo extends StatelessWidget {
  final ModuloVitrine modulo;
  final String selo;
  const _CartaoModulo({required this.modulo, required this.selo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GridColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: GridColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(modulo.icone, size: 18, color: GridColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  modulo.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: GridColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                selo,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: GridColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            modulo.descricao,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.3,
              color: GridColors.textSecondary,
            ),
          ),
          if (modulo.valorMensal != null) ...[
            const SizedBox(height: 4),
            Text(
              'R\$ ${modulo.valorMensal!.toStringAsFixed(2).replaceAll('.', ',')}/mês',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: GridColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
