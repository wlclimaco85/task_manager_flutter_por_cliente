import 'dart:convert';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_windows_screen.dart';
import '../../services/nfse_caller.dart';
import '../../utils/api_links.dart';
import '../../utils/app_logger.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';
import '../../widgets/generic_grid_windows_screen.dart'
    show CustomAction, BulkAction;
import '../../widgets/searchable_dropdown.dart';
import 'details/nfse_detail_screen.dart';

/// Tela de NFSe — espelha o layout da NF-e Saída:
/// header vermelho + painel de filtro lateral + botões + grid dinâmica.
class NfseScreen extends StatefulWidget {
  const NfseScreen({super.key});
  @override
  State<NfseScreen> createState() => _NfseScreenState();
}

class _NfseScreenState extends State<NfseScreen> {
  final NfseCaller _caller = NfseCaller();

  // Filtros
  final _numeroCtrl = TextEditingController();
  final _tomadorCtrl = TextEditingController();
  String? _statusFiltro;
  DateTime? _dtEmiIni, _dtEmiFim;
  Map<String, dynamic> _filtros = {};
  int _gridKey = 0;
  bool _filtrosVisiveis = true;
  final GlobalKey<DynamicGridWindowsScreenState> _dynamicGridKey = GlobalKey();

  // Emissão (dialog)
  final _municipioCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _aliquotaCtrl = TextEditingController();
  final _cnaeCtrl = TextEditingController();
  final _codigoTribCtrl = TextEditingController();
  bool _emitindo = false;
  String? _resultadoEmissao;

  // Consulta (dialog)
  final _consultaCtrl = TextEditingController();
  bool _consultando = false;
  Map<String, dynamic>? _resultadoConsulta;
  String? _erroConsulta;

  // Cancelamento (dialog)
  final _cancelNumeroCtrl = TextEditingController();
  final _cancelMotivoCtrl = TextEditingController();
  bool _cancelando = false;
  String? _resultadoCancelamento;

  // Auditoria (dialog)
  List<Map<String, dynamic>> _logs = [];
  bool _carregandoLogs = false;

  @override
  void initState() {
    super.initState();
    _aplicarFiltros();
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _tomadorCtrl.dispose();
    _municipioCtrl.dispose();
    _cnpjCtrl.dispose();
    _nomeCtrl.dispose();
    _descricaoCtrl.dispose();
    _valorCtrl.dispose();
    _aliquotaCtrl.dispose();
    _cnaeCtrl.dispose();
    _codigoTribCtrl.dispose();
    _consultaCtrl.dispose();
    _cancelNumeroCtrl.dispose();
    _cancelMotivoCtrl.dispose();
    super.dispose();
  }

  // ── Filtros ───────────────────────────────────────────────────────────────

  void _aplicarFiltros() {
    final f = <String, dynamic>{};
    if (_numeroCtrl.text.isNotEmpty) f['numero'] = _numeroCtrl.text;
    if (_tomadorCtrl.text.isNotEmpty) f['tomador'] = _tomadorCtrl.text;
    if (_statusFiltro != null) f['status'] = _statusFiltro!;
    if (_dtEmiIni != null) {
      f['dataEmissaoInicio'] = _dtEmiIni!.toIso8601String().substring(0, 10);
    }
    if (_dtEmiFim != null) {
      f['dataEmissaoFim'] = _dtEmiFim!.toIso8601String().substring(0, 10);
    }
    setState(() {
      _filtros = f;
      _gridKey++;
    });
  }

  void _limpar() {
    _numeroCtrl.clear();
    _tomadorCtrl.clear();
    _statusFiltro = null;
    _dtEmiIni = null;
    _dtEmiFim = null;
    _aplicarFiltros();
  }

  void _abrirNovo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NfseDetailScreen(item: {})),
    ).then((_) => _aplicarFiltros());
  }

  // ── Ações (mesmas do painel anterior, mantidas como dialogs) ─────────────

  Future<void> _emitir() async {
    setState(() {
      _emitindo = true;
      _resultadoEmissao = null;
    });
    try {
      final result = await _caller.emitir(
        municipio: _municipioCtrl.text,
        cnpjTomador: _cnpjCtrl.text,
        nomeTomador: _nomeCtrl.text,
        descricaoServico: _descricaoCtrl.text,
        valor: double.parse(_valorCtrl.text),
        aliquotaIss: double.parse(_aliquotaCtrl.text),
        cnae: _cnaeCtrl.text,
        codigoTributacao: _codigoTribCtrl.text,
      );
      if (mounted) {
        setState(() {
          _resultadoEmissao = 'NFSe emitida!\n'
              'Número: ${result['numero'] ?? result['nfseNumber'] ?? '-'}\n'
              'Protocolo: ${result['protocolo'] ?? result['protocol'] ?? '-'}\n'
              'Status: ${result['status'] ?? result['situacao'] ?? '-'}\n'
              'Chave: ${result['chave'] ?? '-'}';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _resultadoEmissao = 'Erro: $e');
    } finally {
      if (mounted) setState(() => _emitindo = false);
    }
  }

  Future<void> _consultar() async {
    setState(() {
      _consultando = true;
      _resultadoConsulta = null;
      _erroConsulta = null;
    });
    try {
      final result = await _caller.consultar(_consultaCtrl.text);
      if (mounted) setState(() => _resultadoConsulta = result);
    } catch (e) {
      if (mounted) setState(() => _erroConsulta = e.toString());
    } finally {
      if (mounted) setState(() => _consultando = false);
    }
  }

  Future<void> _cancelar() async {
    setState(() {
      _cancelando = true;
      _resultadoCancelamento = null;
    });
    try {
      final result = await _caller.cancelar(
        numero: _cancelNumeroCtrl.text,
        motivo: _cancelMotivoCtrl.text,
      );
      if (mounted) {
        setState(() {
          _resultadoCancelamento =
              'Cancelamento: ${result['status'] ?? result['mensagem'] ?? 'OK'}';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _resultadoCancelamento = 'Erro: $e');
    } finally {
      if (mounted) setState(() => _cancelando = false);
    }
  }

  Future<void> _carregarAuditoria() async {
    setState(() => _carregandoLogs = true);
    try {
      final logs = await _caller.auditoria();
      if (mounted) setState(() => _logs = logs);
    } catch (_) {
      if (mounted) setState(() => _logs = []);
    } finally {
      if (mounted) setState(() => _carregandoLogs = false);
    }
  }

  void _showEmissaoDialog() {
    showDialog(
      context: context,
      builder: (_) => _EmissaoDialog(
        municipioCtrl: _municipioCtrl,
        cnpjCtrl: _cnpjCtrl,
        nomeCtrl: _nomeCtrl,
        descricaoCtrl: _descricaoCtrl,
        valorCtrl: _valorCtrl,
        aliquotaCtrl: _aliquotaCtrl,
        cnaeCtrl: _cnaeCtrl,
        codigoTribCtrl: _codigoTribCtrl,
        emitindo: _emitindo,
        resultado: _resultadoEmissao,
        onEmitir: _emitir,
      ),
    ).then((_) => setState(() => _resultadoEmissao = null));
  }

  void _showConsultaDialog() {
    showDialog(
      context: context,
      builder: (_) => _ConsultaDialog(
        ctrl: _consultaCtrl,
        consultando: _consultando,
        resultado: _resultadoConsulta,
        erro: _erroConsulta,
        onConsultar: _consultar,
      ),
    ).then((_) => setState(() {
          _resultadoConsulta = null;
          _erroConsulta = null;
        }));
  }

  void _showCancelamentoDialog() {
    showDialog(
      context: context,
      builder: (_) => _CancelamentoDialog(
        numeroCtrl: _cancelNumeroCtrl,
        motivoCtrl: _cancelMotivoCtrl,
        cancelando: _cancelando,
        resultado: _resultadoCancelamento,
        onCancelar: _cancelar,
      ),
    ).then((_) => setState(() => _resultadoCancelamento = null));
  }

  void _showAuditoriaDialog() {
    _carregarAuditoria();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _AuditoriaDialog(
        logs: _logs,
        carregando: _carregandoLogs,
        onRefresh: _carregarAuditoria,
      ),
    );
  }

  void _consultarLinha(Map<String, dynamic> item) {
    _consultaCtrl.text = _nfseNumero(item);
    _showConsultaDialog();
  }

  void _cancelarLinha(Map<String, dynamic> item) {
    _cancelNumeroCtrl.text = _nfseNumero(item);
    _showCancelamentoDialog();
  }

  List<CustomAction<Map<String, dynamic>>> _buildCustomActions() => [
        CustomAction<Map<String, dynamic>>(
          icon: Icons.manage_search,
          label: 'Consultar status',
          onPressed: (context, item) => _consultarLinha(item),
        ),
        CustomAction<Map<String, dynamic>>(
          icon: Icons.cancel_outlined,
          label: 'Cancelar',
          onPressed: (context, item) {
            final st = (item['status']?.toString().toUpperCase() ?? '');
            if (st != 'AUTORIZADA') {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'Ação não permitida: Apenas NFS-e AUTORIZADA pode ser cancelada. Status atual: ${st.isEmpty ? "N/A" : st}'),
                backgroundColor: GridColors.error,
              ));
              return;
            }
            _cancelarLinha(item);
          },
        ),
        CustomAction<Map<String, dynamic>>(
          icon: Icons.history,
          label: 'Auditoria',
          onPressed: (context, item) => _showAuditoriaDialog(),
        ),
      ];

  String _nfseNumero(Map<String, dynamic> item) => (item['numero'] ??
          item['nfseNumber'] ??
          item['numeroNfse'] ??
          item['id'] ??
          '')
      .toString();

  // ── Ações em massa (dropdown "Ações" ao lado de Excluir selecionados) ────
  // Validação obrigatória: só habilita ações se TODOS os itens selecionados
  // cumprirem as regras de estado permitidas pela legislação/documentação.

  List<BulkAction<Map<String, dynamic>>> _buildBulkActions() => [
        BulkAction<Map<String, dynamic>>(
          icon: Icons.picture_as_pdf,
          label: 'Gerar PDF',
          isEnabled: (items) =>
              items.isNotEmpty &&
              items.every((i) {
                final st = i['status']?.toString().toUpperCase() ?? '';
                final num = _nfseNumero(i);
                return st == 'AUTORIZADA' || num.isNotEmpty;
              }),
          onPressed: _bulkGerarPdf,
        ),
        BulkAction<Map<String, dynamic>>(
          icon: Icons.send,
          label: 'Enviar',
          isEnabled: (items) =>
              items.isNotEmpty &&
              items.every((i) {
                final st = i['status']?.toString().toUpperCase() ?? '';
                return st != 'AUTORIZADA' && st != 'CANCELADA';
              }),
          onPressed: _bulkEnviar,
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
      ];

  /// Baixa o DANFSe (`GET /api/nfse/{id}/danfse`) item a item — não existe
  /// endpoint de PDF em lote no backend. Mesmo padrão de
  /// `nfse_detail_screen.dart._baixarPdf`.
  Future<void> _bulkGerarPdf(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) async {
    final invalidos = items.where((i) {
      final st = (i['status']?.toString().toUpperCase() ?? '');
      final num = _nfseNumero(i);
      return st != 'AUTORIZADA' && num.isEmpty;
    }).toList();
    if (invalidos.isNotEmpty) {
      final listaStr = invalidos
          .map((i) => '#${i['id'] ?? 'sem id'} (${i['status'] ?? 'sem status'})')
          .join(', ');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Ação não permitida: Apenas NFS-e autorizadas ou com número gerado podem ter PDF emitido. Itens inválidos: $listaStr'),
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
            content: Text('Gerando PDF ${i + 1} de ${items.length}...'),
            duration: const Duration(seconds: 2),
          ));
      }
      try {
        final r = await TenantContext.get(ApiLinks.danfseNfse(id));
        if (r.statusCode == 200) {
          await FileSaver.instance.saveFile(
            name: 'danfse_$id',
            bytes: r.bodyBytes,
            fileExtension: 'pdf',
            mimeType: MimeType.pdf,
          );
          ok++;
        } else {
          falhas.add('#$id (status ${r.statusCode})');
          AppLogger.i.warn(
              'Ação em massa "Gerar PDF" NFS-e #$id falhou: status ${r.statusCode}');
        }
      } catch (e, st) {
        falhas.add('#$id ($e)');
        AppLogger.i.error('Ação em massa "Gerar PDF" NFS-e #$id: $e', st);
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

  /// Emite via Sistema Nacional NFS-e (`POST /api/nfse/{id}/emitir-nacional`)
  /// item a item — mesmo endpoint usado por `nfse_detail_screen.dart._enviarNfse`.
  Future<void> _bulkEnviar(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) async {
    final invalidos = items.where((i) {
      final st = (i['status']?.toString().toUpperCase() ?? '');
      return st == 'AUTORIZADA' || st == 'CANCELADA';
    }).toList();
    if (invalidos.isNotEmpty) {
      final listaStr = invalidos
          .map((i) => '#${i['id'] ?? 'sem id'} (${i['status'] ?? 'sem status'})')
          .join(', ');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Ação não permitida: Notas já autorizadas ou canceladas não podem ser enviadas: $listaStr'),
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
            content: Text('Enviando ${i + 1} de ${items.length}...'),
            duration: const Duration(seconds: 2),
          ));
      }
      try {
        final r = await TenantContext.post(ApiLinks.emitirNfseNacional(id), {});
        if (r.statusCode == 200 || r.statusCode == 201) {
          final b = jsonDecode(r.body);
          final data = b is Map ? (b['data'] ?? b) : null;
          final status = data is Map ? data['status']?.toString() : null;
          if (status == 'AUTORIZADA') {
            ok++;
          } else {
            final erro = data is Map ? data['mensagemErroEmissao'] : null;
            falhas.add('#$id (${erro ?? 'rejeitada'})');
          }
        } else {
          falhas.add('#$id (status ${r.statusCode})');
          AppLogger.i.warn(
              'Ação em massa "Enviar" NFS-e #$id falhou: status ${r.statusCode}');
        }
      } catch (e, st) {
        falhas.add('#$id ($e)');
        AppLogger.i.error('Ação em massa "Enviar" NFS-e #$id: $e', st);
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(falhas.isEmpty
            ? '$ok NFS-e(s) enviada(s) com sucesso'
            : '$ok enviada(s), ${falhas.length} falharam: ${falhas.join(', ')}'),
        backgroundColor:
            falhas.isEmpty ? GridColors.success : GridColors.error,
      ));
  }

  /// Cancela (`POST /api/fiscal/nfse/cancelar`) item a item, pedindo o motivo
  /// UMA ÚNICA VEZ (aplicado a todas as selecionadas) — mesmo endpoint/corpo
  /// usado por `nfse_detail_screen.dart._cancelarNfse`.
  Future<void> _bulkCancelar(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) async {
    final invalidos = items.where((i) {
      final st = (i['status']?.toString().toUpperCase() ?? '');
      return st != 'AUTORIZADA';
    }).toList();
    if (invalidos.isNotEmpty) {
      final listaStr = invalidos
          .map((i) => '#${i['id'] ?? 'sem id'} (${i['status'] ?? 'sem status'})')
          .join(', ');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Ação não permitida: Apenas NFS-e no estado AUTORIZADA podem ser canceladas. Itens inválidos: $listaStr'),
        backgroundColor: GridColors.error,
      ));
      return;
    }

    final motivoCtrl = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancelar ${items.length} NFS-e(s)'),
        content: TextField(
          controller: motivoCtrl,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Motivo do cancelamento',
            hintText: 'Aplicado a todas as NFS-e selecionadas',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, motivoCtrl.text.trim()),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    motivoCtrl.dispose();
    if (motivo == null || motivo.isEmpty || !context.mounted) return;

    var ok = 0;
    final falhas = <String>[];
    for (final item in items) {
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) {
        falhas.add('item sem id');
        continue;
      }
      try {
        final r = await TenantContext.post(ApiLinks.nfseCancelar, {
          'empresaId': item['empresaId'],
          'municipio': item['municipioPrestacao'] ?? item['municipio'],
          'nfseNumber': item['numero'],
          'motivo': motivo,
          'nfseId': int.tryParse(id),
        });
        if (r.statusCode == 200 || r.statusCode == 201) {
          ok++;
        } else {
          falhas.add('#$id (status ${r.statusCode})');
          AppLogger.i.warn(
              'Ação em massa "Cancelar" NFS-e #$id falhou: status ${r.statusCode} - ${r.body}');
        }
      } catch (e, st) {
        falhas.add('#$id ($e)');
        AppLogger.i.error('Ação em massa "Cancelar" NFS-e #$id: $e', st);
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(falhas.isEmpty
          ? '$ok NFS-e(s) cancelada(s) com sucesso'
          : '$ok cancelada(s), ${falhas.length} falharam: ${falhas.join(', ')}'),
      backgroundColor: falhas.isEmpty ? GridColors.success : GridColors.error,
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      height: 56,
      color: GridColors.error,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          const Text(
            'NFSe - Nota Fiscal de Serviços',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _filtrosVisiveis ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: Colors.white,
            ),
            tooltip: _filtrosVisiveis ? 'Ocultar filtros' : 'Exibir filtros',
            onPressed: () => setState(() => _filtrosVisiveis = !_filtrosVisiveis),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            tooltip: 'Ajuda da tela',
            onPressed: () => _dynamicGridKey.currentState?.showHelp(),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Configurar grade',
            onPressed: () => _dynamicGridKey.currentState?.showColumnSettings(),
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: 'Exportar CSV',
            onPressed: () => _dynamicGridKey.currentState?.exportCsv(),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    bool isOutlined = false,
    double height = 38,
  }) {
    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16),
          label: Text(label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: foregroundColor,
            side: BorderSide(color: backgroundColor),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_filtrosVisiveis)
                SizedBox(
                  width: 220,
                  child: _buildFiltros(),
                ),
              Expanded(
                child: DynamicGridWindowsScreen<Map<String, dynamic>>(
                  key: _dynamicGridKey,
                  telaNome: 'nfse',
                  tituloOverride: 'NFSe - Nota Fiscal de Serviços',
                  hasPermission: (p) => p == 'create' ? false : true,
                  fromJson: (json) => json,
                  toJson: (a) => a,
                  extraParams: _filtros,
                  detailScreenBuilder: (item) => NfseDetailScreen(item: item),
                  customActions: _buildCustomActions,
                  bulkActions: _buildBulkActions(),
                  showAppBar: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFiltros() {
    return Container(
      decoration: const BoxDecoration(
        color: GridColors.filterBackground,
        border: Border(right: BorderSide(color: GridColors.divider)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              const Icon(Icons.tune, size: 16, color: GridColors.primary),
              const SizedBox(width: 6),
              const Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: GridColors.textSecondary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 18),
                tooltip: 'Ocultar filtros',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _filtrosVisiveis = false),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _lbl('Data de Emissão'),
          _dateRange(
              _dtEmiIni,
              _dtEmiFim,
              (s, e) => setState(() {
                    _dtEmiIni = s;
                    _dtEmiFim = e;
                  })),
          const SizedBox(height: 8),
          _lbl('Número da NFSe'),
          _inp(_numeroCtrl, 'Nro. NFSe'),
          const SizedBox(height: 8),
          _lbl('Tomador / Parceiro'),
          _inp(_tomadorCtrl, 'Nome do tomador'),
          const SizedBox(height: 8),
          _lbl('Status'),
          _drop(
              _statusFiltro,
              ['PENDENTE', 'AUTORIZADA', 'CANCELADA', 'REJEITADA'],
              (v) => setState(() => _statusFiltro = v)),
          const SizedBox(height: 14),
          _actionBtn(
            onPressed: () => _abrirNovo(context),
            icon: Icons.add,
            label: 'Nova NFS-e',
            backgroundColor: GridColors.success,
            foregroundColor: Colors.white,
            height: 38,
          ),
          const SizedBox(height: 8),
          _actionBtn(
            onPressed: _aplicarFiltros,
            icon: Icons.search,
            label: 'Filtrar',
            backgroundColor: GridColors.primary,
            foregroundColor: Colors.white,
            height: 38,
          ),
          const SizedBox(height: 8),
          _actionBtn(
            onPressed: _limpar,
            icon: Icons.clear,
            label: 'Limpar',
            backgroundColor: GridColors.divider,
            foregroundColor: GridColors.textSecondary,
            isOutlined: true,
            height: 38,
          ),
          const Divider(height: 24),
          _lbl('Ações rápidas'),
          const SizedBox(height: 8),
          _actionBtn(
            onPressed: _showEmissaoDialog,
            icon: Icons.send,
            label: 'Emitir NFSe',
            backgroundColor: GridColors.primary,
            foregroundColor: Colors.white,
            height: 36,
          ),
          const SizedBox(height: 8),
          _actionBtn(
            onPressed: _showConsultaDialog,
            icon: Icons.search,
            label: 'Consultar',
            backgroundColor: GridColors.secondary,
            foregroundColor: Colors.white,
            height: 36,
          ),
          const SizedBox(height: 8),
          _actionBtn(
            onPressed: _showCancelamentoDialog,
            icon: Icons.cancel_outlined,
            label: 'Cancelar NFSe',
            backgroundColor: GridColors.error,
            foregroundColor: Colors.white,
            height: 36,
          ),
          const SizedBox(height: 8),
          _actionBtn(
            onPressed: _showAuditoriaDialog,
            icon: Icons.history,
            label: 'Auditoria',
            backgroundColor: Colors.grey.shade700,
            foregroundColor: Colors.white,
            height: 36,
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

  Widget _inp(TextEditingController c, String h) => TextField(
      controller: c,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialogs internos (mantidos do painel anterior)
// ─────────────────────────────────────────────────────────────────────────────

class _EmissaoDialog extends StatelessWidget {
  final TextEditingController municipioCtrl,
      cnpjCtrl,
      nomeCtrl,
      descricaoCtrl,
      valorCtrl,
      aliquotaCtrl,
      cnaeCtrl,
      codigoTribCtrl;
  final bool emitindo;
  final String? resultado;
  final VoidCallback onEmitir;

  const _EmissaoDialog({
    required this.municipioCtrl,
    required this.cnpjCtrl,
    required this.nomeCtrl,
    required this.descricaoCtrl,
    required this.valorCtrl,
    required this.aliquotaCtrl,
    required this.cnaeCtrl,
    required this.codigoTribCtrl,
    required this.emitindo,
    required this.resultado,
    required this.onEmitir,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Emitir NFSe',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _campo('Município', municipioCtrl),
              _campo('CNPJ Tomador', cnpjCtrl),
              _campo('Nome Tomador', nomeCtrl),
              _campo('Descrição do Serviço', descricaoCtrl),
              Row(children: [
                Expanded(
                    child: _campo('Valor', valorCtrl,
                        teclado: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(
                    child: _campo('Alíquota ISS', aliquotaCtrl,
                        teclado: TextInputType.number)),
              ]),
              Row(children: [
                Expanded(child: _campo('CNAE', cnaeCtrl)),
                const SizedBox(width: 12),
                Expanded(child: _campo('Cód. Tributação', codigoTribCtrl)),
              ]),
              if (resultado != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: resultado!.startsWith('Erro')
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: resultado!.startsWith('Erro')
                          ? Colors.red.shade200
                          : Colors.green.shade200,
                    ),
                  ),
                  child: Text(resultado!, style: const TextStyle(fontSize: 13)),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: emitindo ? null : onEmitir,
                    icon: emitindo
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, size: 18),
                    label: Text(emitindo ? 'Emitindo...' : 'Emitir'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: GridColors.primary,
                        foregroundColor: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(String label, TextEditingController ctrl,
      {TextInputType? teclado}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: teclado,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}

class _ConsultaDialog extends StatelessWidget {
  final TextEditingController ctrl;
  final bool consultando;
  final Map<String, dynamic>? resultado;
  final String? erro;
  final VoidCallback onConsultar;

  const _ConsultaDialog({
    required this.ctrl,
    required this.consultando,
    required this.resultado,
    required this.erro,
    required this.onConsultar,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Consultar NFSe',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      decoration: const InputDecoration(
                        labelText: 'Número NFSe',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: consultando ? null : onConsultar,
                    icon: consultando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.search, size: 18),
                    label: Text(consultando ? 'Consultando...' : 'Consultar'),
                  ),
                ],
              ),
              if (erro != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(erro!, style: const TextStyle(color: Colors.red)),
                ),
              ],
              if (resultado != null) ...[
                const SizedBox(height: 12),
                ...resultado!.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text('${e.key}: ',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('${e.value}',
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    )),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CancelamentoDialog extends StatelessWidget {
  final TextEditingController numeroCtrl, motivoCtrl;
  final bool cancelando;
  final String? resultado;
  final VoidCallback onCancelar;

  const _CancelamentoDialog({
    required this.numeroCtrl,
    required this.motivoCtrl,
    required this.cancelando,
    required this.resultado,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 440,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cancelar NFSe',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red)),
              const SizedBox(height: 20),
              TextField(
                controller: numeroCtrl,
                decoration: const InputDecoration(
                  labelText: 'Número NFSe',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: motivoCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Motivo do Cancelamento',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              if (resultado != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: resultado!.startsWith('Erro')
                        ? Colors.red.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(resultado!, style: const TextStyle(fontSize: 13)),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: cancelando ? null : onCancelar,
                    icon: cancelando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.cancel, size: 18),
                    label: Text(cancelando ? 'Cancelando...' : 'Cancelar NFSe'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuditoriaDialog extends StatelessWidget {
  final List<Map<String, dynamic>> logs;
  final bool carregando;
  final Future<void> Function() onRefresh;

  const _AuditoriaDialog({
    required this.logs,
    required this.carregando,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 600,
        height: 480,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4))),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Auditoria NFSe',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: onRefresh,
                    tooltip: 'Atualizar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: carregando
                  ? const Center(child: CircularProgressIndicator())
                  : logs.isEmpty
                      ? const Center(
                          child: Text('Nenhum log de auditoria encontrado.'))
                      : ListView.separated(
                          itemCount: logs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final log = logs[i];
                            final data = log['data'] ??
                                log['createdAt'] ??
                                log['timestamp'] ??
                                '';
                            final acao = log['acao'] ??
                                log['operacao'] ??
                                log['tipo'] ??
                                log['evento'] ??
                                '';
                            final desc = log['descricao'] ??
                                log['detalhe'] ??
                                log['mensagem'] ??
                                '';
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.history, size: 18),
                              title: Text('$acao',
                                  style: const TextStyle(fontSize: 13)),
                              subtitle: Text('$data — $desc',
                                  style: const TextStyle(fontSize: 12)),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
