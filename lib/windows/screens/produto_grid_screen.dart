import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/auth_utility.dart';
import '../../../utils/api_links.dart';
import '../../utils/grid_texts.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show FieldConfigWindows, FieldType, CustomAction;
import 'details/produto_detail_screen.dart';

class WindowsProdutoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsProdutoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    final login = AuthUtility.userInfo?.login;
    final empresa = login?.empresa;
    final parceiro = login?.parceiro;

    final hasEmpresa = empresa?.id != null;
    final hasParceiro = parceiro?.id != null;

    final empresaIdStr = empresa?.id?.toString() ?? '';
    final empresaNome = empresa?.nome ?? '';
    final parceiroIdStr = parceiro?.id?.toString() ?? '';
    final parceiroNome = parceiro?.nome ?? 'Parceiro';

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
          WindowsProdutoDetailScreen(item: item, hasPermission: hasPermission),
      // H4: ações de editar e excluir na grid de produto
      customActions: () => [
        CustomAction<Map<String, dynamic>>(
          icon: Icons.delete_outline,
          label: 'Excluir',
          onPressed: (ctx, item) => _confirmarExclusao(ctx, item),
          isVisible: (_) => true,
        ),
      ],
    );
  }

  static Future<void> _confirmarExclusao(
      BuildContext context, Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    final nome =
        item['nome']?.toString() ?? item['xProd']?.toString() ?? '#$id';
    if (id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Produto',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text(
            'Deseja excluir o produto "$nome"?\nEsta ação não pode ser desfeita.',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
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
