import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../utils/api_links.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/fiscal_error_message.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show CustomAction, BulkAction;
import 'details/nfe_detail_screen.dart';
import 'nfe_saida_create_screen.dart';
import '../../../widgets/searchable_dropdown.dart';
import '../../utils/grid_texts.dart';

class WebNfeGridScreen extends StatefulWidget {
  final bool entrada;
  final bool Function(String permission)? hasPermission;
  final bool? isMobile;
  const WebNfeGridScreen({
    super.key,
    required this.entrada,
    this.hasPermission,
    this.isMobile,
  });
  @override
  State<WebNfeGridScreen> createState() => _WebNfeGridScreenState();
}

List<Map<String, dynamic>> nfeHistoricoEventos(Map<String, dynamic> data) {
  final eventos = <Map<String, dynamic>>[];
  for (final key in const ['cancelamentos', 'cartasCorrecao', 'eventos']) {
    final raw = data[key];
    if (raw is! List) continue;
    for (final item in raw) {
      if (item is! Map) continue;
      eventos.add({
        'tipo': key == 'cartasCorrecao' ? 'Carta de Correção' : 'Cancelamento',
        ...Map<String, dynamic>.from(item),
      });
    }
  }
  return eventos;
}

class _WebNfeGridScreenState extends State<WebNfeGridScreen> {
  final _numeroCtrl = TextEditingController();
  final _chaveCtrl = TextEditingController();
  final _parceiroCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  String? _statusFiltro;
  DateTime? _dtNegIni, _dtNegFim, _dtMovIni, _dtMovFim;
  Map<String, dynamic> _filtros = {};
  int _gridKey = 0;
  bool _filtrosVisiveis = true;
  final _dynamicGridKey = GlobalKey<DynamicGridWindowsScreenState>();

  @override
  void initState() {
    super.initState();
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    final f = <String, dynamic>{
      'tipoOperacao': widget.entrada ? 'ENTRADA' : 'SAIDA',
    };
    if (_numeroCtrl.text.isNotEmpty) f['numero'] = _numeroCtrl.text;
    if (_chaveCtrl.text.isNotEmpty) f['chave'] = _chaveCtrl.text;
    if (_statusFiltro != null) f['status'] = _statusFiltro!;
    if (_dtNegIni != null) {
      f['dhEmiInicio'] = _dtNegIni!.toIso8601String().substring(0, 10);
    }
    if (_dtNegFim != null) {
      f['dhEmiFim'] = _dtNegFim!.toIso8601String().substring(0, 10);
    }
    setState(() {
      _filtros = f;
      _gridKey++;
    });
    _dynamicGridKey.currentState?.reload();
  }

  void _limpar() {
    _numeroCtrl.clear();
    _chaveCtrl.clear();
    _parceiroCtrl.clear();
    _destCtrl.clear();
    _statusFiltro = null;
    _dtNegIni = null;
    _dtNegFim = null;
    _dtMovIni = null;
    _dtMovFim = null;
    _aplicarFiltros();
  }

  void _abrirNovo(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NfeSankhyaDetailScreen(item: {
            'tipoOperacao': widget.entrada ? 'ENTRADA' : 'SAIDA',
          }),
        )).then((_) => _aplicarFiltros());
  }

  void _abrirNovoComTop(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const NfeSaidaCreateScreen(),
        )).then((_) => _aplicarFiltros());
  }

  Widget _buildHeader(String titulo) {
    final activeCount = _contarFiltrosAtivos();
    return Container(
      height: 56,
      color: GridColors.error,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (Navigator.canPop(context))
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                tooltip: 'Voltar',
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          Icon(
            widget.entrada ? Icons.file_download : Icons.file_upload,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  _filtrosVisiveis ? Icons.filter_list_off : Icons.filter_list,
                  color: Colors.white,
                  size: 20,
                ),
                if (activeCount > 0 && !_filtrosVisiveis)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: GridColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: _filtrosVisiveis ? 'Ocultar Filtros' : 'Exibir Filtros',
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
            onPressed: () =>
                setState(() => _filtrosVisiveis = !_filtrosVisiveis),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white, size: 20),
            tooltip: 'Ajuda da grade',
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
            onPressed: () => _dynamicGridKey.currentState?.showHelp(),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 20),
            tooltip: 'Configurar colunas',
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
            onPressed: () => _dynamicGridKey.currentState?.showColumnSettings(),
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white, size: 20),
            tooltip: 'Exportar CSV',
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
            onPressed: () => _dynamicGridKey.currentState?.exportCsv(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.entrada ? 'NF-e Entrada' : 'NF-e Saída';
    final isMobileMode =
        widget.isMobile == true || MediaQuery.of(context).size.width < 900;
    final effectiveHasPerm =
        widget.hasPermission ?? (p) => p == 'create' ? false : true;

    return Column(
      children: [
        _buildHeader(titulo),
        Expanded(
          child: isMobileMode
              ? Column(
                  children: [
                    if (_filtrosVisiveis) _buildFiltrosMobile(context),
                    Expanded(
                      child: DynamicGridWindowsScreen<Map<String, dynamic>>(
                        key: _dynamicGridKey,
                        telaNome: 'nfe',
                        hasPermission: effectiveHasPerm,
                        fromJson: (json) => json,
                        toJson: (a) => a,
                        extraParams: _filtros,
                        detailScreenBuilder: (item) =>
                            NfeSankhyaDetailScreen(item: item),
                        customActions: () => _buildCustomActions(context),
                        bulkActions: widget.entrada
                            ? _buildBulkActionsEntrada(context)
                            : _buildBulkActionsSaida(context),
                        showAppBar: false,
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_filtrosVisiveis)
                      SizedBox(width: 220, child: _buildFiltros())
                    else
                      const SizedBox.shrink(),
                    Expanded(
                      child: DynamicGridWindowsScreen<Map<String, dynamic>>(
                        key: _dynamicGridKey,
                        telaNome: 'nfe',
                        hasPermission: effectiveHasPerm,
                        fromJson: (json) => json,
                        toJson: (a) => a,
                        extraParams: _filtros,
                        detailScreenBuilder: (item) =>
                            NfeSankhyaDetailScreen(item: item),
                        customActions: () => _buildCustomActions(context),
                        bulkActions: widget.entrada
                            ? _buildBulkActionsEntrada(context)
                            : _buildBulkActionsSaida(context),
                        showAppBar: false,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ── Ações em massa (dropdown "Ações" ao lado de Excluir selecionados,
  // NF-e SAÍDA apenas) ────────────────────────────────────────────────────
  //
  // Decisão: não existe endpoint de lote no backend para PDF/cancelar/emitir
  // NF-e — cada ação chama o endpoint por-id já existente (mesmo usado pelas
  // ações individuais _cancelar/_emitir/_imprimirDanfe acima), item a item
  // num loop, agregando sucesso/falha num único SnackBar de resumo.
  // "Excluir" foi OMITIDO deste dropdown de propósito: o botão padrão
  // "Excluir selecionados" já cobre exclusão em massa e não deve ser
  // duplicado aqui.

  List<BulkAction<Map<String, dynamic>>> _buildBulkActionsSaida(
      BuildContext context) {
    return [
      BulkAction<Map<String, dynamic>>(
        icon: Icons.print,
        label: 'Gerar PDF',
        isEnabled: (items) =>
            items.isNotEmpty &&
            items.every((i) {
              final s = (i['status']?.toString().toUpperCase() ?? '');
              final num = i['numero']?.toString() ?? '';
              return s == 'AUTORIZADA' || num.isNotEmpty;
            }),
        onPressed: _bulkGerarPdf,
      ),
      BulkAction<Map<String, dynamic>>(
        icon: Icons.send,
        label: 'Enviar',
        isEnabled: (items) =>
            items.isNotEmpty &&
            items.every((i) {
              final s = (i['status']?.toString().toUpperCase() ?? '');
              return ['CRIADA', 'PENDENTE', 'DIGITACAO', 'REJEITADA']
                  .contains(s);
            }),
        onPressed: _bulkEmitir,
      ),
      BulkAction<Map<String, dynamic>>(
        icon: Icons.cancel_outlined,
        label: 'Cancelar',
        isEnabled: (items) =>
            items.isNotEmpty &&
            items.every((i) =>
                (i['status']?.toString().toUpperCase() ?? '') == 'AUTORIZADA'),
        onPressed: _bulkCancelar,
      ),
      BulkAction<Map<String, dynamic>>(
        icon: Icons.code,
        label: 'Baixar XML',
        isEnabled: (items) =>
            items.isNotEmpty &&
            items.every((i) {
              final s = (i['status']?.toString().toUpperCase() ?? '');
              return ['AUTORIZADA', 'CANCELADA'].contains(s);
            }),
        onPressed: _bulkBaixarXml,
      ),
    ];
  }

  List<BulkAction<Map<String, dynamic>>> _buildBulkActionsEntrada(
      BuildContext context) {
    return [
      BulkAction<Map<String, dynamic>>(
        icon: Icons.check_circle_outline,
        label: 'Aceitar',
        isEnabled: (items) =>
            items.isNotEmpty &&
            items.every((i) {
              final s = (i['status']?.toString().toUpperCase() ?? '');
              return ['PENDENTE', 'CRIADA', 'IMPORTADA'].contains(s);
            }),
        onPressed: _bulkAceitarEntrada,
      ),
      BulkAction<Map<String, dynamic>>(
        icon: Icons.cancel_outlined,
        label: 'Recusar',
        isEnabled: (items) =>
            items.isNotEmpty &&
            items.every((i) {
              final s = (i['status']?.toString().toUpperCase() ?? '');
              return ['PENDENTE', 'CRIADA', 'IMPORTADA'].contains(s);
            }),
        onPressed: _bulkRecusarEntrada,
      ),
      BulkAction<Map<String, dynamic>>(
        icon: Icons.print,
        label: 'Gerar PDF',
        isEnabled: (items) => items.isNotEmpty,
        onPressed: _bulkGerarPdf,
      ),
      BulkAction<Map<String, dynamic>>(
        icon: Icons.code,
        label: 'Baixar XML',
        isEnabled: (items) => items.isNotEmpty,
        onPressed: _bulkBaixarXml,
      ),
    ];
  }

  /// Baixa o DANFE (`GET /api/nfe/{id}/danfe`) item a item — sem endpoint de
  /// lote no backend. Mesmo endpoint de `_imprimirDanfe`.
  Future<void> _bulkGerarPdf(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) async {
    var ok = 0;
    final falhas = <String>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) {
        falhas.add('item sem id');
        continue;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text('Gerando PDF ${i + 1} de ${items.length}...'),
            duration: const Duration(seconds: 2),
          ));
      }
      try {
        final r = await TenantContext.get(ApiLinks.danfeNfe(id));
        if (r.statusCode == 200) {
          await FileSaver.instance.saveFile(
            name: 'danfe_$id',
            bytes: r.bodyBytes,
            fileExtension: 'pdf',
          );
          ok++;
        } else {
          falhas.add('#$id (${fiscalErrorMessage(r.statusCode, r.body)})');
          AppLogger.i.warn(
              'Ação em massa "Gerar PDF" NF-e #$id falhou: status ${r.statusCode}');
        }
      } catch (e, st) {
        falhas.add('#$id ($e)');
        AppLogger.i.error('Ação em massa "Gerar PDF" NF-e #$id: $e', st);
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(falhas.isEmpty
            ? '$ok PDF(s) gerado(s) com sucesso'
            : '$ok gerado(s), ${falhas.length} falharam: ${falhas.join(', ')}'),
        backgroundColor:
            falhas.isEmpty ? GridColors.success : GridColors.error,
      ));
  }

  /// Emite (`POST /api/nfe/{id}/emitir`) item a item — mesmo endpoint de
  /// `_emitir`, geração/assinatura de XML real, sem endpoint de lote.
  Future<void> _bulkEmitir(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) async {
    final invalidos = items.where((i) {
      final s = (i['status']?.toString().toUpperCase() ?? '');
      return !['CRIADA', 'PENDENTE', 'DIGITACAO', 'REJEITADA'].contains(s);
    }).toList();
    if (invalidos.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Não é permitido emitir notas selecionadas com status incompatível (${invalidos.length} nota(s) já autorizadas ou canceladas).'),
        backgroundColor: GridColors.error,
      ));
      return;
    }

    var ok = 0;
    final falhas = <String>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) {
        falhas.add('item sem id');
        continue;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text('Emitindo ${i + 1} de ${items.length}...'),
            duration: const Duration(seconds: 2),
          ));
      }
      try {
        final r = await TenantContext.post(ApiLinks.emitirNfe(id), {});
        if (r.statusCode == 200 || r.statusCode == 201) {
          ok++;
        } else {
          String msg = 'status ${r.statusCode}';
          try {
            final body = jsonDecode(r.body);
            msg = body['message']?.toString() ??
                body['mensagem']?.toString() ??
                body['error']?.toString() ??
                msg;
          } catch (_) {}
          falhas.add('#$id ($msg)');
          AppLogger.i
              .warn('Ação em massa "Enviar" NF-e #$id falhou: $msg');
        }
      } catch (e, st) {
        falhas.add('#$id ($e)');
        AppLogger.i.error('Ação em massa "Enviar" NF-e #$id: $e', st);
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(falhas.isEmpty
            ? '$ok NF-e(s) emitida(s) com sucesso'
            : '$ok emitida(s), ${falhas.length} falharam: ${falhas.join(', ')}'),
        backgroundColor:
            falhas.isEmpty ? GridColors.success : GridColors.error,
      ));
  }

  /// Cancela (`POST /api/nfe/{id}/cancelar`) item a item, pedindo a
  /// justificativa (mín. 15 caracteres) UMA ÚNICA VEZ — mesma regra e
  /// endpoint de `_cancelar`.
  Future<void> _bulkCancelar(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) async {
    final invalidos = items.where((i) =>
        (i['status']?.toString().toUpperCase() ?? '') != 'AUTORIZADA').toList();
    if (invalidos.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Não é permitido cancelar notas selecionadas com status diferente de AUTORIZADA (${invalidos.length} nota(s) incompatível(is)).'),
        backgroundColor: GridColors.error,
      ));
      return;
    }

    final motivoCtrl = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancelar ${items.length} NF-e(s)',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: motivoCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Motivo do cancelamento *',
              labelStyle: TextStyle(fontSize: 12),
              border: OutlineInputBorder(),
              isDense: true,
              hintText: 'Mínimo 15 caracteres — aplicado a todas selecionadas',
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, motivoCtrl.text.trim()),
            child: const Text('Cancelar NF-e(s)'),
          ),
        ],
      ),
    );
    motivoCtrl.dispose();
    if (motivo == null || !context.mounted) return;
    if (motivo.length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Motivo deve ter pelo menos 15 caracteres'),
          backgroundColor: GridColors.error));
      return;
    }

    var ok = 0;
    final falhas = <String>[];
    for (final item in items) {
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) {
        falhas.add('item sem id');
        continue;
      }
      try {
        final r = await TenantContext.post(
            ApiLinks.cancelarNfe(id), {'justificativa': motivo});
        if (r.statusCode == 200) {
          ok++;
        } else {
          falhas.add('#$id (status ${r.statusCode})');
          AppLogger.i.warn(
              'Ação em massa "Cancelar" NF-e #$id falhou: status ${r.statusCode} - ${r.body}');
        }
      } catch (e, st) {
        falhas.add('#$id ($e)');
        AppLogger.i.error('Ação em massa "Cancelar" NF-e #$id: $e', st);
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(falhas.isEmpty
          ? '$ok NF-e(s) cancelada(s) com sucesso'
          : '$ok cancelada(s), ${falhas.length} falharam: ${falhas.join(', ')}'),
      backgroundColor: falhas.isEmpty ? GridColors.success : GridColors.error,
    ));
  }

  Future<void> _bulkBaixarXml(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) async {
    var ok = 0;
    final falhas = <String>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) {
        falhas.add('item sem id');
        continue;
      }
      try {
        final r = await TenantContext.get(ApiLinks.xmlNfe(id));
        if (r.statusCode == 200) {
          await FileSaver.instance.saveFile(
            name: 'nfe_$id',
            bytes: Uint8List.fromList(r.body.codeUnits),
            fileExtension: 'xml',
          );
          ok++;
        } else {
          falhas.add('#$id (status ${r.statusCode})');
        }
      } catch (e, st) {
        falhas.add('#$id ($e)');
        AppLogger.i.error('Ação em massa "Baixar XML" NF-e #$id: $e', st);
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(falhas.isEmpty
          ? '$ok XML(s) baixado(s) com sucesso'
          : '$ok baixado(s), ${falhas.length} falharam: ${falhas.join(', ')}'),
      backgroundColor: falhas.isEmpty ? GridColors.success : GridColors.error,
    ));
  }

  Future<void> _bulkAceitarEntrada(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) async {
    final invalidos = items.where((i) {
      final s = (i['status']?.toString().toUpperCase() ?? '');
      return !['PENDENTE', 'CRIADA', 'IMPORTADA'].contains(s);
    }).toList();
    if (invalidos.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Não é permitido aceitar notas selecionadas com status incompatível (${invalidos.length} nota(s) já aceitas ou canceladas).'),
        backgroundColor: GridColors.error,
      ));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Aceitar ${items.length} NF-e(s) de entrada?',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: const Text('Confirma o aceite das notas selecionadas?',
            style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.success,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aceitar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    var ok = 0;
    final falhas = <String>[];
    for (final item in items) {
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) {
        falhas.add('item sem id');
        continue;
      }
      try {
        final r = await TenantContext.post(ApiLinks.aceitarNfe(id), {});
        if (r.statusCode == 200) {
          ok++;
        } else {
          falhas.add('#$id (status ${r.statusCode})');
        }
      } catch (e, st) {
        falhas.add('#$id ($e)');
        AppLogger.i.error('Ação em massa "Aceitar" NF-e #$id: $e', st);
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(falhas.isEmpty
          ? '$ok NF-e(s) aceita(s) com sucesso'
          : '$ok aceita(s), ${falhas.length} falharam: ${falhas.join(', ')}'),
      backgroundColor: falhas.isEmpty ? GridColors.success : GridColors.error,
    ));
    if (ok > 0) setState(() => _gridKey++);
  }

  Future<void> _bulkRecusarEntrada(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) async {
    final invalidos = items.where((i) {
      final s = (i['status']?.toString().toUpperCase() ?? '');
      return !['PENDENTE', 'CRIADA', 'IMPORTADA'].contains(s);
    }).toList();
    if (invalidos.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Não é permitido recusar notas selecionadas com status incompatível (${invalidos.length} nota(s) incompatível(is)).'),
        backgroundColor: GridColors.error,
      ));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Recusar ${items.length} NF-e(s) de entrada?',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: const Text('Confirma a recusa das notas selecionadas?',
            style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Recusar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    var ok = 0;
    final falhas = <String>[];
    for (final item in items) {
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) {
        falhas.add('item sem id');
        continue;
      }
      try {
        final r = await TenantContext.post(ApiLinks.recusarNfe(id), {});
        if (r.statusCode == 200) {
          ok++;
        } else {
          falhas.add('#$id (status ${r.statusCode})');
        }
      } catch (e, st) {
        falhas.add('#$id ($e)');
        AppLogger.i.error('Ação em massa "Recusar" NF-e #$id: $e', st);
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(falhas.isEmpty
          ? '$ok NF-e(s) recusada(s) com sucesso'
          : '$ok recusada(s), ${falhas.length} falharam: ${falhas.join(', ')}'),
      backgroundColor: falhas.isEmpty ? GridColors.success : GridColors.error,
    ));
    if (ok > 0) setState(() => _gridKey++);
  }

  List<CustomAction<Map<String, dynamic>>> _buildCustomActions(
      BuildContext ctx) {
    if (widget.entrada) {
      return [
        CustomAction<Map<String, dynamic>>(
          icon: Icons.manage_search,
          label: "Consultar status",
          onPressed: (context, item) => _consultarStatus(context, item),
        ),
        CustomAction<Map<String, dynamic>>(
          icon: Icons.upload_file,
          label: "Importar XML",
          onPressed: (context, item) => _importarXml(context),
        ),
        CustomAction<Map<String, dynamic>>(
          icon: Icons.check_circle_outline,
          label: "Aceitar",
          onPressed: (context, item) => _aceitar(context, item),
        ),
        CustomAction<Map<String, dynamic>>(
          icon: Icons.cancel_outlined,
          label: "Recusar",
          onPressed: (context, item) => _recusar(context, item),
        ),
        CustomAction<Map<String, dynamic>>(
          icon: Icons.print,
          label: "DANFE",
          onPressed: (context, item) => _imprimirDanfe(context, item),
        ),
        CustomAction<Map<String, dynamic>>(
          icon: Icons.code,
          label: "XML",
          onPressed: (context, item) => _baixarXml(context, item),
        ),
      ];
    }
    return [
      CustomAction<Map<String, dynamic>>(
        icon: Icons.manage_search,
        label: "Consultar status",
        onPressed: (context, item) => _consultarStatus(context, item),
      ),
      CustomAction<Map<String, dynamic>>(
        icon: Icons.send,
        label: "Emitir",
        onPressed: (context, item) => _emitir(context, item),
      ),
      CustomAction<Map<String, dynamic>>(
        icon: Icons.cancel_outlined,
        label: "Cancelar",
        onPressed: (context, item) => _cancelar(context, item),
      ),
      CustomAction<Map<String, dynamic>>(
        icon: Icons.edit_note,
        label: "Carta de Correção",
        onPressed: (context, item) => _emitirCce(context, item),
      ),
      CustomAction<Map<String, dynamic>>(
        icon: Icons.history,
        label: "Histórico de eventos",
        onPressed: (context, item) => _historicoEventos(context, item),
      ),
      CustomAction<Map<String, dynamic>>(
        icon: Icons.print,
        label: "Imprimir DANFE",
        onPressed: (context, item) => _imprimirDanfe(context, item),
      ),
      CustomAction<Map<String, dynamic>>(
        icon: Icons.code,
        label: "Exportar XML",
        onPressed: (context, item) => _baixarXml(context, item),
      ),
    ];
  }
  // ── Ações NF-e SAÍDA ──────────────────────────────────────────────────────

  Future<void> _consultarStatus(
      BuildContext context, Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty) return;
    try {
      final r = await TenantContext.get(ApiLinks.nfeById(id));
      if (!context.mounted) return;
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        final data = body is Map<String, dynamic>
            ? (body['dados'] is Map<String, dynamic>
                ? body['dados'] as Map<String, dynamic>
                : body)
            : <String, dynamic>{'retorno': body.toString()};
        _showDataDialog(context, 'Status NF-e', {
          'id': data['id'] ?? id,
          'numero': data['numero'] ?? item['numero'] ?? '-',
          'serie': data['serie'] ?? item['serie'] ?? '-',
          'status': data['status'] ?? item['status'] ?? '-',
          'chave': data['chave'] ?? item['chave'] ?? '-',
          'protocolo': data['protocolo'] ?? item['protocolo'] ?? '-',
          'motivo': data['motivoRejeicao'] ?? data['motivo'] ?? '-',
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ${r.statusCode}: ${r.body}'),
            backgroundColor: GridColors.error));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: GridColors.error));
      }
    }
  }

  Future<void> _cancelar(
      BuildContext context, Map<String, dynamic> item) async {
    final status = item['status']?.toString().toUpperCase() ?? '';
    if (status != 'AUTORIZADA') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Apenas NF-e com status AUTORIZADA pode ser cancelada (status atual: ${status.isEmpty ? 'DESCONHECIDO' : status}).'),
        backgroundColor: GridColors.error,
      ));
      return;
    }
    final id = item['id']?.toString() ?? '';
    final motivoCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar NF-e',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('NF-e #$id — ${item['numero'] ?? ''}',
                  style:
                      const TextStyle(fontSize: 12, color: GridColors.divider)),
              const SizedBox(height: 12),
              TextField(
                controller: motivoCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Motivo do cancelamento *',
                  labelStyle: TextStyle(fontSize: 12),
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: 'Mínimo 15 caracteres',
                ),
              ),
            ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar NF-e'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    if (motivoCtrl.text.trim().length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Motivo deve ter pelo menos 15 caracteres'),
          backgroundColor: GridColors.error));
      return;
    }
    try {
      final r = await TenantContext.post(
          ApiLinks.cancelarNfe(id), {'justificativa': motivoCtrl.text.trim()});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r.statusCode == 200
              ? 'NF-e cancelada com sucesso!'
              : 'Erro ${r.statusCode}: ${r.body}'),
          backgroundColor:
              r.statusCode == 200 ? GridColors.success : GridColors.error));
      if (r.statusCode == 200) setState(() => _gridKey++);
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: GridColors.error));
    }
  }

  Future<void> _emitir(BuildContext context, Map<String, dynamic> item) async {
    final status = item['status']?.toString().toUpperCase() ?? '';
    if (status == 'AUTORIZADA' ||
        status == 'CANCELADA' ||
        status == 'DENEGADA') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Esta NF-e não pode ser transmitida pois seu status atual é $status.'),
        backgroundColor: GridColors.error,
      ));
      return;
    }
    final id = item['id']?.toString() ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Emitir NF-e',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Confirma a emissão da NF-e #$id?',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.success,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Emitir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      // NF08: usa POST /api/nfe/{id}/emitir (geração de XML real e assinatura digital)
      final r = await TenantContext.post(ApiLinks.emitirNfe(id), {});
      if (!context.mounted) return;
      if (r.statusCode == 200 || r.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('NF-e emitida com sucesso! XML gerado e assinado.'),
            backgroundColor: GridColors.success));
        setState(() => _gridKey++);
      } else {
        String msg = 'Erro ${r.statusCode}';
        try {
          final body = jsonDecode(r.body);
          msg = body['message']?.toString() ??
              body['mensagem']?.toString() ??
              body['error']?.toString() ??
              msg;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: GridColors.error));
      }
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: GridColors.error));
    }
  }

  Future<void> _imprimirDanfe(
      BuildContext context, Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    try {
      final r = await TenantContext.get(ApiLinks.danfeNfe(id));
      if (!context.mounted) return;
      if (r.statusCode == 200) {
        await FileSaver.instance.saveFile(
          name: 'danfe_$id',
          bytes: r.bodyBytes,
          fileExtension: 'pdf',
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('DANFE baixado!'),
            backgroundColor: GridColors.success));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(fiscalErrorMessage(r.statusCode, r.body)),
            backgroundColor: GridColors.error));
      }
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: GridColors.error));
    }
  }

  Future<void> _baixarXml(
      BuildContext context, Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    try {
      final r = await TenantContext.get(ApiLinks.xmlNfe(id));
      if (!context.mounted) return;
      if (r.statusCode == 200) {
        await FileSaver.instance.saveFile(
          name: 'nfe_$id',
          bytes: Uint8List.fromList(r.body.codeUnits),
          fileExtension: 'xml',
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('XML baixado!'),
            backgroundColor: GridColors.success));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(fiscalErrorMessage(r.statusCode, r.body)),
            backgroundColor: GridColors.error));
      }
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: GridColors.error));
    }
  }

  Future<void> _emitirCce(
      BuildContext context, Map<String, dynamic> item) async {
    final status = item['status']?.toString().toUpperCase() ?? '';
    if (status != 'AUTORIZADA') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Apenas NF-e com status AUTORIZADA pode receber Carta de Correção (status atual: ${status.isEmpty ? 'DESCONHECIDO' : status}).'),
        backgroundColor: GridColors.error,
      ));
      return;
    }
    final id = item['id']?.toString() ?? '';
    final correcaoCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Carta de Correção NF-e',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: correcaoCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Correção *',
              border: OutlineInputBorder(),
              isDense: true,
              hintText: 'Mínimo 15 caracteres',
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.success,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar CC-e'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    if (correcaoCtrl.text.trim().length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Correção deve ter pelo menos 15 caracteres'),
          backgroundColor: GridColors.error));
      return;
    }
    try {
      final r = await TenantContext.post(ApiLinks.cancelamentoNfeCce(id),
          {'correcao': correcaoCtrl.text.trim()});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r.statusCode == 200
              ? 'CC-e enviada com sucesso!'
              : 'Erro ${r.statusCode}: ${r.body}'),
          backgroundColor:
              r.statusCode == 200 ? GridColors.success : GridColors.error));
      if (r.statusCode == 200) setState(() => _gridKey++);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: GridColors.error));
      }
    }
  }

  Future<void> _historicoEventos(
      BuildContext context, Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty) return;
    try {
      final r = await TenantContext.get(ApiLinks.cancelamentoNfeHistorico(id));
      if (!context.mounted) return;
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        _showHistoricoEventosDialog(
          context,
          'Histórico de eventos NF-e',
          body is Map<String, dynamic> ? body : {'eventos': body.toString()},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ${r.statusCode}: ${r.body}'),
            backgroundColor: GridColors.error));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: GridColors.error));
      }
    }
  }

  // ── Ações NF-e ENTRADA ────────────────────────────────────────────────────

  Future<void> _importarXml(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xml'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !context.mounted) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    try {
      final r = await TenantContext.postMultipart(
        '${ApiLinks.baseUrl}/api/nfe/entrada/import',
        fileBytes: file.bytes!,
        fileName: file.name,
        fileField: 'xml',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r.statusCode == 200
              ? 'XML importado com sucesso!'
              : 'Erro ${r.statusCode}: ${r.body}'),
          backgroundColor:
              r.statusCode == 200 ? GridColors.success : GridColors.error));
      if (r.statusCode == 200) setState(() => _gridKey++);
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: GridColors.error));
    }
  }

  Future<void> _aceitar(BuildContext context, Map<String, dynamic> item) async {
    final status = item['status']?.toString().toUpperCase() ?? '';
    if (['ACEITA', 'CANCELADA', 'RECUSADA'].contains(status)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Esta NF-e não pode ser aceita pois seu status atual é $status.'),
        backgroundColor: GridColors.error,
      ));
      return;
    }
    final id = item['id']?.toString() ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aceitar NF-e',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Confirma o aceite da NF-e #$id?',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.success,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aceitar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final r = await TenantContext.post(ApiLinks.aceitarNfe(id), {});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              r.statusCode == 200 ? 'NF-e aceita!' : 'Erro ${r.statusCode}'),
          backgroundColor:
              r.statusCode == 200 ? GridColors.success : GridColors.error));
      if (r.statusCode == 200) setState(() => _gridKey++);
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: GridColors.error));
    }
  }

  Future<void> _recusar(BuildContext context, Map<String, dynamic> item) async {
    final status = item['status']?.toString().toUpperCase() ?? '';
    if (['ACEITA', 'CANCELADA', 'RECUSADA'].contains(status)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Esta NF-e não pode ser recusada pois seu status atual é $status.'),
        backgroundColor: GridColors.error,
      ));
      return;
    }
    final id = item['id']?.toString() ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Recusar NF-e',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Confirma a recusa da NF-e #$id?',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Recusar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final r = await TenantContext.post(ApiLinks.recusarNfe(id), {});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              r.statusCode == 200 ? 'NF-e recusada!' : 'Erro ${r.statusCode}'),
          backgroundColor:
              r.statusCode == 200 ? GridColors.success : GridColors.error));
      if (r.statusCode == 200) setState(() => _gridKey++);
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: GridColors.error));
    }
  }

  Future<void> _exportarXmlLote(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Para exportar o XML de uma nota, abra a nota e clique em "XML" no cabeçalho.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _importarReceita(BuildContext context) async {
    DateTime? dataIni = DateTime.now().subtract(const Duration(days: 30));
    DateTime? dataFim = DateTime.now();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Importar da Receita Federal',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          content: SizedBox(
              width: 340,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Selecione o período para importar NF-e:',
                    style: TextStyle(fontSize: 12, color: GridColors.divider)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _dpDialog(ctx, dataIni, 'Data Início',
                          (d) => setS(() => dataIni = d))),
                  const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('até', style: TextStyle(fontSize: 12))),
                  Expanded(
                      child: _dpDialog(ctx, dataFim, 'Data Fim',
                          (d) => setS(() => dataFim = d))),
                ]),
              ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(GridTexts.cancel)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.success,
                  foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Importar'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final ini = dataIni?.toIso8601String().substring(0, 10) ?? '';
      final fim = dataFim?.toIso8601String().substring(0, 10) ?? '';
      final r = await TenantContext.post(
          '${ApiLinks.baseUrl}/api/nfe/receita/importar?dataInicio=$ini&dataFim=$fim',
          {});
      if (!context.mounted) return;
      final body = jsonDecode(r.body);
      final total = body['response']?['total'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r.statusCode == 200
              ? 'Importação concluída: $total nota(s) importada(s)'
              : 'Erro ${r.statusCode}'),
          backgroundColor:
              r.statusCode == 200 ? GridColors.success : GridColors.error));
      if (r.statusCode == 200) setState(() => _gridKey++);
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: GridColors.error));
    }
  }

  Widget _dpDialog(BuildContext context, DateTime? val, String hint,
          void Function(DateTime?) cb) =>
      GestureDetector(
          onTap: () async {
            final d = await showDatePicker(
                context: context,
                initialDate: val ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030));
            cb(d);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: GridColors.divider)),
            child: Row(children: [
              const Icon(Icons.calendar_today,
                  size: 12, color: GridColors.divider),
              const SizedBox(width: 4),
              Text(
                  val != null
                      ? '${val.day.toString().padLeft(2, '0')}/${val.month.toString().padLeft(2, '0')}/${val.year}'
                      : hint,
                  style: TextStyle(
                      fontSize: 11,
                      color: val != null
                          ? GridColors.textSecondary
                          : GridColors.divider)),
            ]),
          ));

  Widget _actionBtn({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool outlined = false,
  }) {
    final style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: outlined ? color : Colors.white,
    );
    return SizedBox(
      width: double.infinity,
      height: 36,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 14, color: color),
              label: Text(label, style: style),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 14, color: Colors.white),
              label: Text(label, style: style),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
    );
  }

  int _contarFiltrosAtivos() {
    var count = 0;
    if (_numeroCtrl.text.isNotEmpty) count++;
    if (_chaveCtrl.text.isNotEmpty) count++;
    if (_parceiroCtrl.text.isNotEmpty) count++;
    if (_destCtrl.text.isNotEmpty) count++;
    if (_statusFiltro != null && _statusFiltro!.isNotEmpty) count++;
    if (_dtNegIni != null || _dtNegFim != null) count++;
    if (_dtMovIni != null || _dtMovFim != null) count++;
    return count;
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltrosMobile(BuildContext context) {
    final activeCount = _contarFiltrosAtivos();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: GridColors.divider, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.52,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tune, size: 18, color: GridColors.error),
                      const SizedBox(width: 8),
                      const Text(
                        'Filtros de Pesquisa',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: GridColors.textPrimary,
                        ),
                      ),
                      if (activeCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: GridColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$activeCount ativo${activeCount > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: GridColors.textSecondary),
                    tooltip: 'Ocultar Filtros',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => setState(() => _filtrosVisiveis = false),
                  ),
                ],
              ),
              const Divider(height: 16),
              _lbl('Data de Negociação'),
              _dateRange(
                _dtNegIni,
                _dtNegFim,
                (s, e) => setState(() {
                  _dtNegIni = s;
                  _dtNegFim = e;
                }),
              ),
              const SizedBox(height: 10),
              _lbl('Data do Movimento'),
              _dateRange(
                _dtMovIni,
                _dtMovFim,
                (s, e) => setState(() {
                  _dtMovIni = s;
                  _dtMovFim = e;
                }),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _lbl('Número da Nota'),
                        _inp(_numeroCtrl, 'Ex: 1234', keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _lbl('Status'),
                        _drop(
                          _statusFiltro,
                          ['PENDENTE', 'AUTORIZADA', 'CANCELADA', 'REJEITADA'],
                          (v) => setState(() => _statusFiltro = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _lbl('Chave de Acesso'),
              _inp(_chaveCtrl, '44 dígitos da chave NF-e', keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _lbl('Parceiro'),
                        _inp(_parceiroCtrl, 'Nome do parceiro'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _lbl('Destinatário'),
                        _inp(_destCtrl, 'Nome do destinatário'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _limpar,
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Limpar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GridColors.textSecondary,
                        side: const BorderSide(color: GridColors.divider),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _aplicarFiltros();
                        setState(() => _filtrosVisiveis = false);
                      },
                      icon: const Icon(Icons.search, size: 16),
                      label: const Text('Filtrar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GridColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _lbl('Ações Rápidas'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _actionChip(
                    icon: Icons.add,
                    label: 'Nova NF-e',
                    color: GridColors.success,
                    onPressed: () => _abrirNovo(context),
                  ),
                  if (!widget.entrada) ...[
                    _actionChip(
                      icon: Icons.add_circle_outline,
                      label: 'Nova c/ TOP',
                      color: const Color(0xFF1A237E),
                      onPressed: () => _abrirNovoComTop(context),
                    ),
                    _actionChip(
                      icon: Icons.code,
                      label: 'Exportar XML',
                      color: const Color(0xFF1565C0),
                      onPressed: () => _exportarXmlLote(context),
                    ),
                  ],
                  if (widget.entrada) ...[
                    _actionChip(
                      icon: Icons.upload_file,
                      label: 'Importar XML',
                      color: const Color(0xFF2E7D32),
                      onPressed: () => _importarXml(context),
                    ),
                    _actionChip(
                      icon: Icons.cloud_download,
                      label: 'Importar Receita',
                      color: const Color(0xFF1565C0),
                      onPressed: () => _importarReceita(context),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      color: GridColors.filterBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune, size: 16, color: GridColors.textPrimary),
                  SizedBox(width: 6),
                  Text('Filtros',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: GridColors.textPrimary)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left,
                    size: 18, color: GridColors.textSecondary),
                tooltip: 'Recolher filtros',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _filtrosVisiveis = false),
              ),
            ],
          ),
          const Divider(height: 16),
          _lbl('Data de Negociação'),
          _dateRange(
              _dtNegIni,
              _dtNegFim,
              (s, e) => setState(() {
                    _dtNegIni = s;
                    _dtNegFim = e;
                  })),
          const SizedBox(height: 8),
          _lbl('Data do Movimento'),
          _dateRange(
              _dtMovIni,
              _dtMovFim,
              (s, e) => setState(() {
                    _dtMovIni = s;
                    _dtMovFim = e;
                  })),
          const SizedBox(height: 8),
          _lbl('Número da Nota'),
          _inp(_numeroCtrl, 'Nro. Nota'),
          const SizedBox(height: 8),
          _lbl('Chave de Acesso'),
          _inp(_chaveCtrl, 'Chave NF-e'),
          const SizedBox(height: 8),
          _lbl('Parceiro'),
          _inp(_parceiroCtrl, 'Nome do parceiro'),
          const SizedBox(height: 8),
          _lbl('Destinatário'),
          _inp(_destCtrl, 'Nome do destinatário'),
          const SizedBox(height: 8),
          _lbl('Status'),
          _drop(
              _statusFiltro,
              ['PENDENTE', 'AUTORIZADA', 'CANCELADA', 'REJEITADA'],
              (v) => setState(() => _statusFiltro = v)),
          const SizedBox(height: 12),
          _actionBtn(
            onPressed: () => _abrirNovo(context),
            icon: Icons.add,
            label: 'Nova NF-e',
            color: GridColors.success,
          ),
          const SizedBox(height: 6),
          if (!widget.entrada) ...[
            _actionBtn(
              onPressed: () => _abrirNovoComTop(context),
              icon: Icons.add_circle_outline,
              label: 'Nova c/ TOP',
              color: const Color(0xFF1A237E),
            ),
            const SizedBox(height: 6),
            _actionBtn(
              onPressed: () => _exportarXmlLote(context),
              icon: Icons.code,
              label: 'Exportar XML',
              color: const Color(0xFF1565C0),
            ),
            const SizedBox(height: 6),
          ],
          if (widget.entrada) ...[
            _actionBtn(
              onPressed: () => _importarXml(context),
              icon: Icons.upload_file,
              label: 'Importar XML',
              color: const Color(0xFF2E7D32),
            ),
            const SizedBox(height: 6),
            _actionBtn(
              onPressed: () => _importarReceita(context),
              icon: Icons.cloud_download,
              label: 'Importar Receita',
              color: const Color(0xFF1565C0),
            ),
            const SizedBox(height: 6),
          ],
          _actionBtn(
            onPressed: _aplicarFiltros,
            icon: Icons.search,
            label: 'Filtrar',
            color: GridColors.error,
          ),
          const SizedBox(height: 6),
          _actionBtn(
            onPressed: _limpar,
            icon: Icons.clear,
            label: 'Limpar',
            color: GridColors.textSecondary,
            outlined: true,
          ),
        ]),
      ),
    );
  }

  Widget _lbl(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(t,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: GridColors.textSecondary)));

  Widget _inp(TextEditingController c, String h, {TextInputType? keyboardType}) => TextField(
      controller: c,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
          hintText: h,
          hintStyle: const TextStyle(fontSize: 11, color: GridColors.divider),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: GridColors.divider)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: GridColors.divider))));

  Widget _drop(String? val, List<String> opts, void Function(String?) cb) =>
      SearchableDropdownField(
        label: '',
        value: val,
        items: opts.map((o) => <String, dynamic>{'id': o, 'nome': o}).toList(),
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        nullLabel: 'Todos',
        hintText: 'Todos',
        onChanged: cb,
      );

  Widget _dateRange(DateTime? ini, DateTime? fim,
          void Function(DateTime?, DateTime?) cb) =>
      Row(children: [
        Expanded(child: _dp(ini, 'Início', (d) => cb(d, fim))),
        const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('a', style: TextStyle(fontSize: 11))),
        Expanded(child: _dp(fim, 'Fim', (d) => cb(ini, d))),
      ]);

  Widget _dp(DateTime? val, String hint, void Function(DateTime?) cb) =>
      GestureDetector(
        onTap: () async {
          final d = await showDatePicker(
              context: context,
              initialDate: val ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030));
          cb(d);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: GridColors.divider),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today,
                size: 10, color: GridColors.divider),
            const SizedBox(width: 3),
            Text(
              val != null
                  ? '${val.day.toString().padLeft(2, '0')}/${val.month.toString().padLeft(2, '0')}'
                  : hint,
              style: TextStyle(
                fontSize: 10,
                color:
                    val != null ? GridColors.textSecondary : GridColors.divider,
              ),
            ),
          ]),
        ),
      );

  void _showDataDialog(
    BuildContext context,
    String title,
    Map<String, dynamic> data,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text('${e.key}: ${e.value}'),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showHistoricoEventosDialog(
    BuildContext context,
    String title,
    Map<String, dynamic> data,
  ) {
    final eventos = nfeHistoricoEventos(data);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eventos.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAF8),
                      border: Border.all(color: GridColors.divider),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Nenhum evento registrado para esta NF-e.',
                      style: TextStyle(color: GridColors.textSecondary),
                    ),
                  )
                else
                  ...eventos.map(_eventTile),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _eventTile(Map<String, dynamic> evento) {
    String firstOf(List<String> keys) {
      for (final key in keys) {
        final value = evento[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
      return '-';
    }

    final tipo = firstOf(['tipo', 'evento', 'descricao']);
    final data = firstOf(['dataEvento', 'data', 'createdAt', 'dhEvento']);
    final protocolo = firstOf(['protocolo', 'protocoloEvento', 'nProt']);
    final motivo =
        firstOf(['motivo', 'justificativa', 'correcao', 'xCorrecao']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: GridColors.divider),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.history, size: 16, color: GridColors.secondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(tipo,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: GridColors.textPrimary)),
            ),
            Text(data,
                style: const TextStyle(
                    fontSize: 12, color: GridColors.textSecondary)),
          ]),
          const SizedBox(height: 6),
          Text('Protocolo: $protocolo',
              style: const TextStyle(
                  fontSize: 12, color: GridColors.textSecondary)),
          if (motivo != '-')
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(motivo, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
