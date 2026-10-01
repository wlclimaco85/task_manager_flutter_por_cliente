import 'dart:convert';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';

import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/nfce_model.dart';
import '../../../services/nfce_service.dart';
import '../../../services/print_service_nfce.dart';
import '../../../utils/api_links.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/app_snackbar.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/grid_texts.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show CustomAction, BulkAction, FieldConfigWindows, FieldType;
import '../../../widgets/searchable_dropdown.dart';
import 'nfce/pdv_screen.dart';

class WebNfceGridScreen extends StatefulWidget {
  final SecurityCheck? hasPermission;
  final bool? isMobile;
  const WebNfceGridScreen({super.key, this.hasPermission, this.isMobile});

  @override
  State<WebNfceGridScreen> createState() => _WebNfceGridScreenState();
}

class _WebNfceGridScreenState extends State<WebNfceGridScreen> {
  final _numeroCtrl = TextEditingController();
  final _chaveCtrl = TextEditingController();
  final _serieCtrl = TextEditingController();
  String? _statusFiltro;
  DateTime? _dtIni, _dtFim;
  Map<String, dynamic> _filtros = {};
  bool _filtrosVisiveis = true;
  final _dynamicGridKey = GlobalKey<DynamicGridWindowsScreenState>();

  @override
  void initState() {
    super.initState();
    _aplicarFiltros();
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _chaveCtrl.dispose();
    _serieCtrl.dispose();
    super.dispose();
  }

  void _aplicarFiltros() {
    final extraParams = <String, dynamic>{};
    if (TenantContext.hasEmpresa) {
      extraParams['empresa'] = TenantContext.empresaId.toString();
      extraParams['empId'] = TenantContext.empresaId.toString();
      extraParams['empresaId'] = TenantContext.empresaId.toString();
    }
    if (TenantContext.hasParceiro) {
      extraParams['parceiro'] = TenantContext.parceiroId.toString();
      extraParams['parceiroId'] = TenantContext.parceiroId.toString();
      extraParams['parcId'] = TenantContext.parceiroId.toString();
    }
    if (_numeroCtrl.text.isNotEmpty) extraParams['numero'] = _numeroCtrl.text;
    if (_chaveCtrl.text.isNotEmpty) extraParams['chaveAcesso'] = _chaveCtrl.text;
    if (_serieCtrl.text.isNotEmpty) extraParams['serie'] = _serieCtrl.text;
    if (_statusFiltro != null) extraParams['statusSefaz'] = _statusFiltro!;
    if (_dtIni != null) {
      extraParams['dataInicio'] = _dtIni!.toIso8601String().substring(0, 10);
    }
    if (_dtFim != null) {
      extraParams['dataFim'] = _dtFim!.toIso8601String().substring(0, 10);
    }

    setState(() {
      _filtros = extraParams;
    });
    _dynamicGridKey.currentState?.reload();
  }

  void _limpar() {
    _numeroCtrl.clear();
    _chaveCtrl.clear();
    _serieCtrl.clear();
    _statusFiltro = null;
    _dtIni = null;
    _dtFim = null;
    _aplicarFiltros();
  }

  void _abrirPdv(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PdvScreen()),
    ).then((_) => _aplicarFiltros());
  }

  int _contarFiltrosAtivos() {
    var count = 0;
    if (_numeroCtrl.text.isNotEmpty) count++;
    if (_chaveCtrl.text.isNotEmpty) count++;
    if (_serieCtrl.text.isNotEmpty) count++;
    if (_statusFiltro != null && _statusFiltro!.isNotEmpty) count++;
    if (_dtIni != null || _dtFim != null) count++;
    return count;
  }

  Widget _buildHeader() {
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
          const Icon(
            Icons.receipt,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'NFC-e / Cupons Fiscais',
              style: TextStyle(
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
    final isMobileMode =
        widget.isMobile == true || MediaQuery.of(context).size.width < 900;
    final effectiveHasPerm = widget.hasPermission ?? (p) => true;

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: isMobileMode
              ? Column(
                  children: [
                    if (_filtrosVisiveis) _buildFiltrosMobile(context),
                    Expanded(
                      child: DynamicGridWindowsScreen<NfceModel>(
                        key: _dynamicGridKey,
                        telaNome: 'nfce',
                        tituloOverride: 'NFC-e / Cupons',
                        fetchEndpointOverride: '${ApiLinks.baseUrl}/api/v1/nfce',
                        createEndpointOverride: '${ApiLinks.baseUrl}/api/v1/nfce',
                        hasPermission: effectiveHasPerm,
                        extraParams: _filtros,
                        fieldOverrides: const [
                          FieldConfigWindows(
                            label: 'Empresa',
                            fieldName: 'empresa',
                            fieldType: FieldType.dropdown,
                            isFilterable: true,
                            isInGrid: false,
                            isInForm: false,
                          ),
                          FieldConfigWindows(
                            label: 'Parceiro',
                            fieldName: 'parceiro',
                            fieldType: FieldType.dropdown,
                            isFilterable: true,
                            isInGrid: false,
                            isInForm: false,
                          ),
                        ],
                        fromJson: (json) => NfceModel.fromJson(json),
                        toJson: (a) => a.toJson(),
                        showAppBar: false,
                        bulkActions: _buildBulkActions(context),
                        customActions: () => _buildCustomActions(context),
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
                      child: DynamicGridWindowsScreen<NfceModel>(
                        key: _dynamicGridKey,
                        telaNome: 'nfce',
                        tituloOverride: 'NFC-e / Cupons',
                        fetchEndpointOverride: '${ApiLinks.baseUrl}/api/v1/nfce',
                        createEndpointOverride: '${ApiLinks.baseUrl}/api/v1/nfce',
                        hasPermission: effectiveHasPerm,
                        extraParams: _filtros,
                        fieldOverrides: const [
                          FieldConfigWindows(
                            label: 'Empresa',
                            fieldName: 'empresa',
                            fieldType: FieldType.dropdown,
                            isFilterable: true,
                            isInGrid: false,
                            isInForm: false,
                          ),
                          FieldConfigWindows(
                            label: 'Parceiro',
                            fieldName: 'parceiro',
                            fieldType: FieldType.dropdown,
                            isFilterable: true,
                            isInGrid: false,
                            isInForm: false,
                          ),
                        ],
                        fromJson: (json) => NfceModel.fromJson(json),
                        toJson: (a) => a.toJson(),
                        showAppBar: false,
                        bulkActions: _buildBulkActions(context),
                        customActions: () => _buildCustomActions(context),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ── Ações em Lote (BulkActions) com validação estrita de status ──────────

  List<BulkAction<NfceModel>> _buildBulkActions(BuildContext context) {
    return [
      BulkAction<NfceModel>(
        icon: Icons.print,
        label: 'Imprimir Cupom / DANFE',
        isEnabled: (items) =>
            items.isNotEmpty &&
            items.every((i) {
              final s = i.statusSefaz.toUpperCase();
              return ['AUTORIZADA', 'CONTINGENCIA'].contains(s) ||
                  (i.numero != null && i.numero! > 0);
            }),
        onPressed: _bulkImprimirDanfe,
      ),
      BulkAction<NfceModel>(
        icon: Icons.send,
        label: 'Transmitir NFC-e',
        isEnabled: (items) =>
            items.isNotEmpty &&
            items.every((i) {
              final s = i.statusSefaz.toUpperCase();
              return ['PENDENTE', 'CRIADA', 'REJEITADA', 'DIGITACAO']
                  .contains(s);
            }),
        onPressed: _bulkEmitir,
      ),
      BulkAction<NfceModel>(
        icon: Icons.cancel_outlined,
        label: 'Cancelar',
        isEnabled: (items) =>
            items.isNotEmpty &&
            items.every((i) => i.statusSefaz.toUpperCase() == 'AUTORIZADA'),
        onPressed: _bulkCancelar,
      ),
      BulkAction<NfceModel>(
        icon: Icons.podcasts,
        label: 'Reenviar Contingência',
        isEnabled: (items) =>
            items.isNotEmpty &&
            items.every((i) => i.statusSefaz.toUpperCase() == 'CONTINGENCIA'),
        onPressed: _bulkReenviarContingencia,
      ),
      BulkAction<NfceModel>(
        icon: Icons.code,
        label: 'Baixar XML',
        isEnabled: (items) =>
            items.isNotEmpty &&
            items.every((i) {
              final s = i.statusSefaz.toUpperCase();
              return ['AUTORIZADA', 'CANCELADA', 'CONTINGENCIA'].contains(s);
            }),
        onPressed: _bulkBaixarXml,
      ),
    ];
  }

  Future<void> _bulkImprimirDanfe(
    BuildContext context,
    List<NfceModel> items,
  ) async {
    final invalidos = items.where((i) {
      final s = i.statusSefaz.toUpperCase();
      return !['AUTORIZADA', 'CONTINGENCIA'].contains(s) &&
          (i.numero == null || i.numero! <= 0);
    }).toList();
    if (invalidos.isNotEmpty) {
      AppSnackbar.error(
        context,
        'Não é permitido imprimir cupom de NFC-e selecionadas sem status AUTORIZADA/CONTINGÊNCIA (${invalidos.length} nota(s) incompatível(is)).',
      );
      return;
    }

    var ok = 0;
    final falhas = <String>[];
    for (var i = 0; i < items.length; i++) {
      final nfce = items[i];
      if (nfce.id <= 0) {
        falhas.add('item sem ID');
        continue;
      }
      try {
        await PrintServiceNfce().imprimirDanfe(context, nfce.id);
        ok++;
      } catch (e, st) {
        falhas.add('#${nfce.id} ($e)');
        AppLogger.i.error('Falha ao imprimir DANFE NFC-e #${nfce.id}: $e', st);
      }
    }
    if (!context.mounted) return;
    if (falhas.isEmpty) {
      AppSnackbar.success(context, '$ok Cupom/DANFE(s) impresso(s) ou baixado(s) com sucesso.');
    } else {
      AppSnackbar.error(context, '$ok impresso(s), ${falhas.length} falharam: ${falhas.join(', ')}');
    }
  }

  Future<void> _bulkEmitir(
    BuildContext context,
    List<NfceModel> items,
  ) async {
    final invalidos = items.where((i) {
      final s = i.statusSefaz.toUpperCase();
      return !['PENDENTE', 'CRIADA', 'REJEITADA', 'DIGITACAO'].contains(s);
    }).toList();
    if (invalidos.isNotEmpty) {
      AppSnackbar.error(
        context,
        'Não é permitido transmitir NFC-e selecionadas com status incompatível (${invalidos.length} nota(s) já autorizadas ou canceladas).',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Transmitir ${items.length} NFC-e(s)?',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: const Text(
          'Confirma a transmissão para a SEFAZ das notas selecionadas?',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.success,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Transmitir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    var ok = 0;
    final falhas = <String>[];
    for (final nfce in items) {
      if (nfce.vendaId == null || nfce.vendaId! <= 0) {
        falhas.add('#${nfce.id} (sem vendaId)');
        continue;
      }
      try {
        await NfceService().emitirNfce(nfce.vendaId!);
        ok++;
      } catch (e, st) {
        falhas.add('#${nfce.id} ($e)');
        AppLogger.i.error('Falha ao emitir NFC-e #${nfce.id}: $e', st);
      }
    }
    if (!context.mounted) return;
    if (falhas.isEmpty) {
      AppSnackbar.success(context, '$ok NFC-e(s) transmitida(s) com sucesso.');
    } else {
      AppSnackbar.error(context, '$ok transmitida(s), ${falhas.length} falharam: ${falhas.join(', ')}');
    }
    if (ok > 0) _aplicarFiltros();
  }

  Future<void> _bulkCancelar(
    BuildContext context,
    List<NfceModel> items,
  ) async {
    final invalidos = items.where((i) =>
        i.statusSefaz.toUpperCase() != 'AUTORIZADA').toList();
    if (invalidos.isNotEmpty) {
      AppSnackbar.error(
        context,
        'Apenas NFC-e com status AUTORIZADA podem ser canceladas (${invalidos.length} nota(s) incompatível(is)).',
      );
      return;
    }

    final justificativa = await _promptText(
      context,
      title: 'Cancelar ${items.length} NFC-e(s)',
      label: 'Justificativa do cancelamento',
      hint: 'Mínimo 15 caracteres — aplicado a todas selecionadas',
      initialValue: 'Cancelamento solicitado em lote pela listagem',
      minLength: 15,
    );
    if (justificativa == null || !context.mounted) return;

    var ok = 0;
    final falhas = <String>[];
    for (final nfce in items) {
      if (nfce.id <= 0) {
        falhas.add('item sem ID');
        continue;
      }
      try {
        await NfceService().cancelarNfce(
          nfce.id,
          justificativa,
          empresaId: TenantContext.empresaId ?? 0,
        );
        ok++;
      } catch (e, st) {
        falhas.add('#${nfce.id} ($e)');
        AppLogger.i.error('Falha ao cancelar NFC-e #${nfce.id}: $e', st);
      }
    }
    if (!context.mounted) return;
    if (falhas.isEmpty) {
      AppSnackbar.success(context, '$ok NFC-e(s) cancelada(s) com sucesso.');
    } else {
      AppSnackbar.error(context, '$ok cancelada(s), ${falhas.length} falharam: ${falhas.join(', ')}');
    }
    if (ok > 0) _aplicarFiltros();
  }

  Future<void> _bulkReenviarContingencia(
    BuildContext context,
    List<NfceModel> items,
  ) async {
    final invalidos = items.where((i) =>
        i.statusSefaz.toUpperCase() != 'CONTINGENCIA').toList();
    if (invalidos.isNotEmpty) {
      AppSnackbar.error(
        context,
        'Apenas notas com status CONTINGENCIA podem ser reenviadas (${invalidos.length} nota(s) incompatível(is)).',
      );
      return;
    }

    var ok = 0;
    final falhas = <String>[];
    for (final nfce in items) {
      if (nfce.id <= 0) {
        falhas.add('item sem ID');
        continue;
      }
      try {
        await NfceService().reenviarContingencia(nfce.id);
        ok++;
      } catch (e, st) {
        falhas.add('#${nfce.id} ($e)');
        AppLogger.i.error('Falha ao reenviar contingência #${nfce.id}: $e', st);
      }
    }
    if (!context.mounted) return;
    if (falhas.isEmpty) {
      AppSnackbar.success(context, '$ok NFC-e(s) reenviada(s) da contingência.');
    } else {
      AppSnackbar.error(context, '$ok reenviada(s), ${falhas.length} falharam: ${falhas.join(', ')}');
    }
    if (ok > 0) _aplicarFiltros();
  }

  Future<void> _bulkBaixarXml(
    BuildContext context,
    List<NfceModel> items,
  ) async {
    final invalidos = items.where((i) {
      final s = i.statusSefaz.toUpperCase();
      return !['AUTORIZADA', 'CANCELADA', 'CONTINGENCIA'].contains(s);
    }).toList();
    if (invalidos.isNotEmpty) {
      AppSnackbar.error(
        context,
        'Não é permitido baixar XML de notas pendentes ou não emitidas (${invalidos.length} nota(s) incompatível(is)).',
      );
      return;
    }

    var ok = 0;
    final falhas = <String>[];
    for (final nfce in items) {
      if (nfce.id <= 0) {
        falhas.add('item sem ID');
        continue;
      }
      try {
        final xml = await NfceService().baixarXml(nfce.id);
        await FileSaver.instance.saveFile(
          name: 'nfce_${nfce.id}',
          bytes: xml,
          fileExtension: 'xml',
        );
        ok++;
      } catch (e, st) {
        falhas.add('#${nfce.id} ($e)');
        AppLogger.i.error('Falha ao baixar XML NFC-e #${nfce.id}: $e', st);
      }
    }
    if (!context.mounted) return;
    if (falhas.isEmpty) {
      AppSnackbar.success(context, '$ok XML(s) baixado(s) com sucesso.');
    } else {
      AppSnackbar.error(context, '$ok baixado(s), ${falhas.length} falharam: ${falhas.join(', ')}');
    }
  }

  // ── Ações Individuais (CustomAction) com validações de status ────────────

  List<CustomAction<NfceModel>> _buildCustomActions(BuildContext context) {
    return [
      CustomAction<NfceModel>(
        label: 'Consultar status',
        icon: Icons.manage_search,
        onPressed: _consultarStatus,
      ),
      CustomAction<NfceModel>(
        label: 'Cancelar',
        icon: Icons.cancel,
        onPressed: (ctx, item) {
          final s = item.statusSefaz.toUpperCase();
          if (s != 'AUTORIZADA') {
            AppSnackbar.error(
              ctx,
              'Apenas NFC-e com status AUTORIZADA pode ser cancelada (status atual: $s).',
            );
            return;
          }
          _cancelar(ctx, item);
        },
      ),
      CustomAction<NfceModel>(
        label: 'Cancelar por substituição',
        icon: Icons.change_circle,
        onPressed: (ctx, item) {
          final s = item.statusSefaz.toUpperCase();
          if (s != 'AUTORIZADA') {
            AppSnackbar.error(
              ctx,
              'Apenas NFC-e com status AUTORIZADA pode ser cancelada por substituição.',
            );
            return;
          }
          AppSnackbar.error(
            ctx,
            'Cancelamento por substituição ainda não possui endpoint ativo no backend.',
          );
        },
      ),
      CustomAction<NfceModel>(
        label: 'Contingência / EPEC',
        icon: Icons.podcasts,
        onPressed: (ctx, item) {
          final s = item.statusSefaz.toUpperCase();
          if (s != 'CONTINGENCIA') {
            AppSnackbar.error(
              ctx,
              'Esta NFC-e não está em contingência offline (status atual: $s).',
            );
            return;
          }
          _reenviarContingencia(ctx, item);
        },
      ),
      CustomAction<NfceModel>(
        label: 'Inutilizar numeração',
        icon: Icons.block,
        onPressed: _inutilizar,
      ),
      CustomAction<NfceModel>(
        label: 'Gerar PDF',
        icon: Icons.picture_as_pdf,
        onPressed: (ctx, item) {
          final s = item.statusSefaz.toUpperCase();
          if (!['AUTORIZADA', 'CONTINGENCIA'].contains(s) &&
              (item.numero == null || item.numero! <= 0)) {
            AppSnackbar.error(
              ctx,
              'Apenas NFC-e com status AUTORIZADA ou CONTINGÊNCIA possui Cupom/DANFE para emissão.',
            );
            return;
          }
          _gerarPdf(ctx, item);
        },
      ),
      CustomAction<NfceModel>(
        label: 'Baixar XML',
        icon: Icons.code,
        onPressed: (ctx, item) {
          final s = item.statusSefaz.toUpperCase();
          if (!['AUTORIZADA', 'CANCELADA', 'CONTINGENCIA'].contains(s) &&
              !item.xmlAutorizadoDisponivel) {
            AppSnackbar.error(
              ctx,
              'XML autorizado não está disponível para esta NFC-e (status atual: $s).',
            );
            return;
          }
          _baixarXml(ctx, item);
        },
      ),
      CustomAction<NfceModel>(
        label: 'Enviar e-mail',
        icon: Icons.email,
        onPressed: (ctx, item) {
          final s = item.statusSefaz.toUpperCase();
          if (s != 'AUTORIZADA') {
            AppSnackbar.error(
              ctx,
              'Apenas NFC-e com status AUTORIZADA pode ser enviada por e-mail (status atual: $s).',
            );
            return;
          }
          _enviarEmail(ctx, item);
        },
      ),
    ];
  }

  static Future<void> _consultarStatus(
    BuildContext context,
    NfceModel nfce,
  ) async {
    try {
      final status = await NfceService().consultarStatus(nfce.id);
      if (!context.mounted) return;
      _showDataDialog(context, 'Status NFC-e', {
        'id': status.id,
        'status': status.status,
        'mensagem': status.mensagem ?? '-',
        'protocolo': status.protocolo ?? '-',
        'codigoRetorno': status.codigoRetorno ?? '-',
        'motivoRejeicao': status.motivoRejeicao ?? '-',
      });
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Erro ao consultar status: $e');
      }
    }
  }

  Future<void> _cancelar(BuildContext context, NfceModel nfce) async {
    if (nfce.id == 0) {
      AppSnackbar.error(context, 'NFC-e sem ID.');
      return;
    }
    final justificativa = await _promptText(
      context,
      title: 'Cancelar NFC-e #${nfce.numero ?? nfce.id}',
      label: 'Justificativa',
      hint: 'Mínimo 15 caracteres',
      initialValue: 'Cancelamento solicitado pela listagem',
      minLength: 15,
    );
    if (justificativa == null) return;
    try {
      await NfceService().cancelarNfce(
        nfce.id,
        justificativa,
        empresaId: TenantContext.empresaId ?? 0,
      );
      if (context.mounted) {
        AppSnackbar.success(context, 'NFC-e cancelada com sucesso.');
      }
      _aplicarFiltros();
    } catch (e) {
      if (context.mounted) AppSnackbar.error(context, 'Erro ao cancelar: $e');
    }
  }

  Future<void> _reenviarContingencia(
    BuildContext context,
    NfceModel nfce,
  ) async {
    if (nfce.id == 0) {
      AppSnackbar.error(context, 'NFC-e sem ID.');
      return;
    }
    try {
      await NfceService().reenviarContingencia(nfce.id);
      if (context.mounted) {
        AppSnackbar.success(context, 'NFC-e enviada em contingência.');
      }
      _aplicarFiltros();
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Erro ao enviar contingência: $e');
      }
    }
  }

  Future<void> _inutilizar(BuildContext context, NfceModel nfce) async {
    if (nfce.numero == null || nfce.serie == null) {
      AppSnackbar.error(context, 'NFC-e sem número ou série.');
      return;
    }
    final justificativa = await _promptText(
      context,
      title: 'Inutilizar numeração',
      label: 'Justificativa',
      hint: 'Explique o motivo da inutilização (mínimo 15 caracteres)',
      minLength: 15,
    );
    if (justificativa == null) return;
    try {
      await NfceService().inutilizar(
        empresaId: TenantContext.empresaId ?? 0,
        uf: nfce.uf ?? 'MG',
        ambiente: nfce.ambiente ?? 'HOMOLOGACAO',
        serie: nfce.serie!,
        numeroInicio: nfce.numero!,
        numeroFim: nfce.numero!,
        justificativa: justificativa,
      );
      if (context.mounted) {
        AppSnackbar.success(context, 'Numeração inutilizada com sucesso.');
      }
      _aplicarFiltros();
    } catch (e) {
      if (context.mounted) AppSnackbar.error(context, 'Erro ao inutilizar: $e');
    }
  }

  static Future<void> _gerarPdf(BuildContext context, NfceModel nfce) async {
    if (nfce.id == 0) {
      AppSnackbar.error(context, 'NFC-e sem ID.');
      return;
    }
    try {
      await PrintServiceNfce().imprimirDanfe(context, nfce.id);
    } catch (e) {
      if (context.mounted) AppSnackbar.error(context, 'Erro ao gerar PDF: $e');
    }
  }

  static Future<void> _baixarXml(BuildContext context, NfceModel nfce) async {
    if (nfce.id == 0) {
      AppSnackbar.error(context, 'NFC-e sem ID.');
      return;
    }
    try {
      final xml = await NfceService().baixarXml(nfce.id);
      await FileSaver.instance.saveFile(
        name: 'nfce_${nfce.id}',
        bytes: xml,
        fileExtension: 'xml',
      );
      if (context.mounted) AppSnackbar.success(context, 'XML baixado.');
    } catch (e) {
      if (context.mounted) AppSnackbar.error(context, 'Erro ao baixar XML: $e');
    }
  }

  static Future<void> _enviarEmail(BuildContext context, NfceModel nfce) async {
    if (nfce.id == 0) {
      AppSnackbar.error(context, 'NFC-e sem ID.');
      return;
    }
    final email = await _promptText(
      context,
      title: 'Enviar NFC-e por e-mail',
      label: 'E-mail',
      hint: 'destinatario@empresa.com',
      minLength: 5,
    );
    if (email == null) return;
    try {
      await NfceService().enviarEmail(nfce.id, email);
      if (context.mounted) {
        AppSnackbar.success(context, 'E-mail enviado com sucesso.');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Erro ao enviar e-mail: $e');
      }
    }
  }

  // ── Ações de Barra Lateral de Filtros (Consultar SEFAZ e Inutilização) ────

  Future<void> _consultarSefazHealth(BuildContext context) async {
    final empresaId = TenantContext.empresaId ?? 0;
    if (empresaId <= 0) {
      AppSnackbar.error(
          context, 'Selecione uma empresa para consultar status da SEFAZ.');
      return;
    }
    try {
      AppSnackbar.info(context, 'Consultando saúde do webservice SEFAZ...');
      final res = await NfceService().verificarSaudeSefaz(
        empresaId: empresaId,
        uf: 'MG',
        ambiente: 'HOMOLOGACAO',
      );
      if (!context.mounted) return;
      _showDataDialog(context, 'Status SEFAZ NFC-e', {
        'Status': res.status,
        'Disponível': res.disponivel ? 'SIM (Em Operação)' : 'NÃO (Indisponível)',
        'UF': res.uf,
        'Ambiente': res.ambiente,
        'Mensagem': res.mensagem,
      });
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Erro ao verificar SEFAZ: $e');
      }
    }
  }

  Future<void> _inutilizarFaixaDialog(BuildContext context) async {
    final serieCtrl = TextEditingController(text: '1');
    final iniCtrl = TextEditingController();
    final fimCtrl = TextEditingController();
    final justificativaCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Inutilizar Numeração NFC-e',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informe a série e o intervalo de numeração a inutilizar na SEFAZ:',
                  style: TextStyle(fontSize: 12, color: GridColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: serieCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Série *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: iniCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Número Início *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: fimCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Número Fim *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: justificativaCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Justificativa * (mín. 15 caracteres)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(GridTexts.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Inutilizar'),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;
    final serie = int.tryParse(serieCtrl.text.trim()) ?? 1;
    final ini = int.tryParse(iniCtrl.text.trim());
    final fim = int.tryParse(fimCtrl.text.trim());
    final just = justificativaCtrl.text.trim();

    if (ini == null || fim == null || just.length < 15) {
      AppSnackbar.error(context, 'Preencha número inicial, final e justificativa (mín. 15 chars).');
      return;
    }

    try {
      await NfceService().inutilizar(
        empresaId: TenantContext.empresaId ?? 0,
        uf: 'MG',
        ambiente: 'HOMOLOGACAO',
        serie: serie,
        numeroInicio: ini,
        numeroFim: fim,
        justificativa: just,
      );
      if (context.mounted) {
        AppSnackbar.success(context, 'Numeração inutilizada com sucesso.');
      }
      _aplicarFiltros();
    } catch (e) {
      if (context.mounted) AppSnackbar.error(context, 'Erro ao inutilizar: $e');
    }
  }

  // ── Painel de Filtros e Botões Padronizados ──────────────────────────────

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
              _lbl('Período de Emissão'),
              _dateRange(
                _dtIni,
                _dtFim,
                (s, e) => setState(() {
                  _dtIni = s;
                  _dtFim = e;
                }),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _lbl('Número do Cupom'),
                        _inp(_numeroCtrl, 'Ex: 1024', keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _lbl('Série'),
                        _inp(_serieCtrl, 'Ex: 1', keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _lbl('Chave de Acesso'),
              _inp(_chaveCtrl, '44 dígitos da chave NFC-e', keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _lbl('Status SEFAZ'),
              _drop(
                _statusFiltro,
                [
                  'PENDENTE',
                  'AUTORIZADA',
                  'CANCELADA',
                  'REJEITADA',
                  'CONTINGENCIA',
                  'INUTILIZADA'
                ],
                (v) => setState(() => _statusFiltro = v),
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
                    icon: Icons.point_of_sale,
                    label: 'Nova NFC-e / PDV',
                    color: GridColors.success,
                    onPressed: () => _abrirPdv(context),
                  ),
                  _actionChip(
                    icon: Icons.cloud_sync,
                    label: 'Consultar SEFAZ',
                    color: const Color(0xFF1565C0),
                    onPressed: () => _consultarSefazHealth(context),
                  ),
                  _actionChip(
                    icon: Icons.block,
                    label: 'Inutilizar Numeração',
                    color: const Color(0xFFE65100),
                    onPressed: () => _inutilizarFaixaDialog(context),
                  ),
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
          _lbl('Período de Emissão'),
          _dateRange(
              _dtIni,
              _dtFim,
              (s, e) => setState(() {
                    _dtIni = s;
                    _dtFim = e;
                  })),
          const SizedBox(height: 8),
          _lbl('Número do Cupom'),
          _inp(_numeroCtrl, 'Ex: 1024'),
          const SizedBox(height: 8),
          _lbl('Série'),
          _inp(_serieCtrl, 'Ex: 1'),
          const SizedBox(height: 8),
          _lbl('Chave de Acesso'),
          _inp(_chaveCtrl, '44 dígitos'),
          const SizedBox(height: 8),
          _lbl('Status SEFAZ'),
          _drop(
              _statusFiltro,
              [
                'PENDENTE',
                'AUTORIZADA',
                'CANCELADA',
                'REJEITADA',
                'CONTINGENCIA',
                'INUTILIZADA'
              ],
              (v) => setState(() => _statusFiltro = v)),
          const SizedBox(height: 12),
          _actionBtn(
            onPressed: () => _abrirPdv(context),
            icon: Icons.point_of_sale,
            label: 'Nova NFC-e / PDV',
            color: GridColors.success,
          ),
          const SizedBox(height: 6),
          _actionBtn(
            onPressed: () => _consultarSefazHealth(context),
            icon: Icons.cloud_sync,
            label: 'Consultar SEFAZ',
            color: const Color(0xFF1565C0),
          ),
          const SizedBox(height: 6),
          _actionBtn(
            onPressed: () => _inutilizarFaixaDialog(context),
            icon: Icons.block,
            label: 'Inutilizar Numeração',
            color: const Color(0xFFE65100),
          ),
          const SizedBox(height: 6),
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

  static Future<String?> _promptText(
    BuildContext context, {
    required String title,
    required String label,
    String? hint,
    String? initialValue,
    int minLength = 15,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final value = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: label == 'E-mail' ? 1 : 3,
          keyboardType: label == 'E-mail'
              ? TextInputType.emailAddress
              : TextInputType.text,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (value == null) return null;
    if (value.length < minLength) {
      if (context.mounted) {
        AppSnackbar.error(
          context,
          '$label deve ter pelo menos $minLength caracteres.',
        );
      }
      return null;
    }
    return value;
  }

  static void _showDataDialog(
    BuildContext context,
    String title,
    Map<String, dynamic> data,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 420,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
