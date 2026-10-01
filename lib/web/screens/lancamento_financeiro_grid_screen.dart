import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../../web/dialogs/rateio_dialog.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show CustomAction, FieldConfigWindows;
import 'package:http/http.dart' as http;

class WebLancamentoFinanceiroGridScreen extends StatefulWidget {
  final SecurityCheck hasPermission;
  const WebLancamentoFinanceiroGridScreen(
      {super.key, required this.hasPermission});

  @override
  State<WebLancamentoFinanceiroGridScreen> createState() =>
      _WebLancamentoFinanceiroGridScreenState();
}

class _WebLancamentoFinanceiroGridScreenState
    extends State<WebLancamentoFinanceiroGridScreen> {
  bool _importing = false;

  Future<void> _importar() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'rem', 'ret', 'txt'],
      withData: true,
    );
    if (result == null || !mounted) return;

    final file = result.files.first;
    final Uint8List? bytes = file.bytes;
    if (bytes == null) {
      _snack('Não foi possível ler o arquivo', error: true);
      return;
    }

    setState(() => _importing = true);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiLinks.importacaoContaPagar),
      );
      request.headers.addAll(TenantContext.headers);
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: file.name),
      );
      if (TenantContext.empresaId != null) {
        request.fields['empresaId'] = TenantContext.empresaId.toString();
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        final importados = data['importados'] ?? data['count'] ?? '?';
        _snack('Importação concluída: $importados registro(s)');
      } else {
        _snack('Erro na importação (${response.statusCode})', error: true);
      }
    } catch (e) {
      if (mounted) _snack('Erro: $e', error: true);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error ? GridColors.error : GridColors.success,
      content: Text(msg),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'lancamento_financeiro',
      hasPermission: widget.hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      fetchEndpointOverride: ApiLinks.lancamentosFinanceiros,
      createEndpointOverride: ApiLinks.createContaPagar,
      updateEndpointOverride: ApiLinks.updateContaPagar(':id'),
      deleteEndpointOverride: ApiLinks.deleteContaPagar(':id'),
      fieldOverrides: const [
        FieldConfigWindows(
            fieldName: 'parceiro',
            label: 'Parceiro',
            isInForm: true,
            isInGrid: false,
            isVisibleByDefault: false),
        FieldConfigWindows(
            fieldName: 'parceiroDev',
            label: 'Parceiro Dev',
            isInForm: true,
            isInGrid: false,
            isVisibleByDefault: false),
        FieldConfigWindows(
            fieldName: 'parceiroRec',
            label: 'Parceiro Rec',
            isInForm: true,
            isInGrid: false,
            isVisibleByDefault: false),
      ],
      headerActions: [
        OutlinedButton.icon(
          onPressed: _importing ? null : _importar,
          icon: _importing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: GridColors.secondary),
                )
              : const Icon(Icons.upload_file, size: 18),
          label: const Text('Importar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: GridColors.secondary,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            side: const BorderSide(color: GridColors.divider),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ],
      customActions: () => [
        CustomAction<Map<String, dynamic>>(
          icon: Icons.scale,
          label: 'Configurar Rateio',
          onPressed: (context, object) {
            final id = object['id'];
            final tipo = object['tipo'] ?? object['lancamentoTipo'] ?? 'CONTA_PAGAR';
            final desc = object['descricao']?.toString();
            showDialog(
              context: context,
              builder: (_) => RateioDialog(
                lancamentoId: id is int ? id : int.tryParse('$id') ?? 0,
                lancamentoTipo: tipo.toString(),
                lancamentoDescricao: desc,
              ),
            );
          },
          isVisible: (_) => true,
        ),
      ],
    );
  }
}
