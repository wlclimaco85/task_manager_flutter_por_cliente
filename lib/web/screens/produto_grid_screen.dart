import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/auth_utility.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show FieldConfigWindows, FieldType, CustomAction;
import '../../../widgets/produto_saidas_chart_dialog.dart';
import './ged_arquivos_screen.dart';
import 'details/produto_detail_screen.dart';
import '../../utils/grid_texts.dart';

class WebProdutoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebProdutoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    final login = AuthUtility.userInfo?.login;
    final empresa  = login?.empresa;
    final parceiro = login?.parceiro;

    final hasEmpresa  = empresa?.id != null;
    final hasParceiro = parceiro?.id != null;

    final empresaIdStr  = empresa?.id?.toString() ?? '';
    final empresaNome   = empresa?.nome ?? '';
    final parceiroIdStr = parceiro?.id?.toString() ?? '';
    final parceiroNome  = parceiro?.nome ?? 'Parceiro';

    final fieldOverrides = <FieldConfigWindows>[
      if (hasEmpresa)
        FieldConfigWindows(
          label: 'Empresa',
          fieldName: 'empresa',
          displayFieldName: 'empresa.nome',
          icon: Icons.business,
          isFilterable: true,
          isInForm: true,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: () async => [
            {'id': empresaIdStr, 'nome': empresaNome},
          ],
          dropdownValueField: 'id',
          dropdownDisplayField: 'nome',
          dropdownSelectedValue: empresaIdStr,
          enabled: false,
        ),
      if (hasParceiro)
        FieldConfigWindows(
          label: parceiroNome,
          fieldName: 'parceiro',
          displayFieldName: 'parceiro.nome',
          icon: Icons.person_outline,
          isFilterable: true,
          isInForm: true,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: () async => [
            {'id': parceiroIdStr, 'nome': parceiroNome},
          ],
          dropdownValueField: 'id',
          dropdownDisplayField: 'nome',
          dropdownSelectedValue: parceiroIdStr,
          enabled: false,
        ),
    ];

    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'produto',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      fieldOverrides: fieldOverrides.isNotEmpty ? fieldOverrides : null,
      detailScreenBuilder: (item) =>
          WebProdutoDetailScreen(item: item, hasPermission: hasPermission),
      // H4: ações na grid de produto; H5-21: GED filtrado pelo produto
      customActions: () => [
        CustomAction<Map<String, dynamic>>(
          icon: Icons.info_outline,
          label: 'Detalhes',
          onPressed: (ctx, item) => Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) =>
                  WebProdutoDetailScreen(item: item, hasPermission: hasPermission),
            ),
          ),
          isVisible: (_) => true,
        ),
        CustomAction<Map<String, dynamic>>(
          icon: Icons.bar_chart,
          label: 'Saídas Mensais',
          onPressed: (ctx, item) => showDialog(
            context: ctx,
            builder: (_) => ProdutoSaidasChartDialog(produto: item),
          ),
          isVisible: (_) => true,
        ),
        CustomAction<Map<String, dynamic>>(
          icon: Icons.folder_open,
          label: 'Ver GED',
          onPressed: (ctx, item) {
            final id = item['id'] is int ? item['id'] as int : int.tryParse(item['id']?.toString() ?? '');
            final nome = item['nome']?.toString() ?? item['xProd']?.toString() ?? '';
            Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => GedArquivosScreen(
                moduloOrigem: 'produto',
                idOrigem: id,
                nomeOrigem: nome,
              ),
            ));
          },
          isVisible: (_) => true,
        ),
        CustomAction<Map<String, dynamic>>(
          icon: Icons.delete_outline,
          label: 'Excluir',
          onPressed: (ctx, item) => _confirmarExclusao(ctx, item),
          isVisible: (_) => true,
        ),
      ],
    );
  }

  static Future<void> _confirmarExclusao(BuildContext context, Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    final nome = item['nome']?.toString() ?? item['xProd']?.toString() ?? '#$id';
    if (id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Produto', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Deseja excluir o produto "$nome"?\nEsta ação não pode ser desfeita.',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final token = AuthUtility.userInfo?.token;
      final resp = await http.delete(
        Uri.parse('${ApiLinks.baseUrl}/api/produto/$id'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(resp.statusCode == 200 || resp.statusCode == 204
            ? 'Produto excluído com sucesso!'
            : 'Erro ao excluir (${resp.statusCode})'),
        backgroundColor: resp.statusCode == 200 || resp.statusCode == 204
            ? Colors.green
            : Colors.red,
      ));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
