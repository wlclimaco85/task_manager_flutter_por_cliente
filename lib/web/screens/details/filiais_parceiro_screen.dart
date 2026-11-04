import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../utils/api_links.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../services/network_caller.dart';
import '../../../widgets/generic_detail_form_screen.dart'
    show showMultiSelectDialog;

class FiliaisParceiroScreen extends StatefulWidget {
  final int matrizId;
  final int? empresaId;
  final SecurityCheck hasPermission;

  const FiliaisParceiroScreen({
    super.key,
    required this.matrizId,
    this.empresaId,
    required this.hasPermission,
  });

  @override
  State<FiliaisParceiroScreen> createState() => _FiliaisParceiroScreenState();
}

class _FiliaisParceiroScreenState extends State<FiliaisParceiroScreen> {
  Key _gridKey = UniqueKey();

  void _mostrarMensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  /// Vincula um parceiro como filial da matriz atual. Retorna `true` em sucesso.
  Future<bool> _vincularUm(String parceiroId) async {
    // URL: singular "/api/parceiro" e absoluta (ver bugs.md 2026-09-16).
    final getResp =
        await NetworkCaller().getRequest('${ApiLinks.allParceiros}/$parceiroId');
    if (!getResp.isSuccess || getResp.body == null) {
      AppLogger.i.warn(
          'Vincular filial: falha ao buscar parceiro $parceiroId (status ${getResp.statusCode})');
      return false;
    }
    final parceiroData = getResp.body!;
    parceiroData['matriz'] = {'id': widget.matrizId};
    final putResp = await NetworkCaller()
        .putRequest(ApiLinks.updateParceiro(parceiroId), parceiroData);
    final ok = putResp.statusCode == 200 || putResp.statusCode == 201;
    if (!ok) {
      AppLogger.i.warn(
          'Vincular filial: falha ao atualizar parceiro $parceiroId (status ${putResp.statusCode})');
    }
    return ok;
  }

  Future<void> _vincularFilial() async {
    List<Map<String, dynamic>> opcoes;
    try {
      final parceiros =
          await DropdownHelpers.parceirosPorEmpresa(widget.empresaId?.toString());
      opcoes = parceiros
          .where((p) => p['id']?.toString() != widget.matrizId.toString())
          .map((p) => {
                'id': p['id'],
                'label': (p['nome'] ?? p['razaoSocial'] ?? '').toString(),
                'cnpj': (p['cpf'] ?? '').toString().trim(),
              })
          .toList();
    } catch (e, st) {
      AppLogger.i.error('Vincular filial: erro ao carregar parceiros: $e', st);
      _mostrarMensagem('Erro ao carregar parceiros');
      return;
    }
    if (!mounted) return;

    final selecionados = await showMultiSelectDialog(
      context,
      title: 'Vincular filiais',
      options: opcoes,
      valueField: 'id',
      displayField: 'label',
      subtitleField: 'cnpj',
    );
    if (selecionados == null || selecionados.isEmpty) return;

    var falhas = 0;
    for (final id in selecionados) {
      try {
        if (!await _vincularUm(id.toString())) falhas++;
      } catch (e, st) {
        falhas++;
        AppLogger.i.error('Vincular filial: erro ao vincular $id: $e', st);
      }
    }
    if (!mounted) return;
    setState(() => _gridKey = UniqueKey());
    if (falhas > 0) {
      _mostrarMensagem(
          'Erro ao vincular $falhas de ${selecionados.length} filial(is).');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen(
      key: _gridKey,
      telaNome: 'parceiro',
      hasPermission: widget.hasPermission,
      extraParams: {'matrizId': widget.matrizId, if (widget.empresaId != null) 'empresaId': widget.empresaId},
      fromJson: (json) => json,
toJson: (item) => item,
      headerActions: [
        ElevatedButton.icon(
          onPressed: _vincularFilial,
          icon: const Icon(Icons.add_link),
          label: const Text('Vincular Filial Existente'),
        ),
      ],
      showAppBar: false,
    );
  }
}
