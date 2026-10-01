import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import '../../../utils/grid_colors.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/auth_utility.dart';
import '../../../models/nfe_pagamento_model.dart';
import '../../../models/nfe_fatura_model.dart';
import '../../../models/nfe_duplicata_model.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/searchable_dropdown.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../utils/fiscal_error_message.dart';
import '../../../utils/grid_texts.dart';
import '../../../utils/nfe_tax_aliases.dart';
import '../produto_grid_screen.dart';

const _red = GridColors.primary;
const _green = GridColors.secondary;
const _bord = Color(0xFFDDDDDD);
const _grey = Color(0xFF757575);
const _dark = Color(0xFF212121);
const _bg = Color(0xFFF5F5F5);

class NfeSankhyaDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const NfeSankhyaDetailScreen({super.key, required this.item});
  @override
  State<NfeSankhyaDetailScreen> createState() => _State();
}

class _State extends State<NfeSankhyaDetailScreen> {
  int _tab = 0;
  bool _itensGrid = true;
  bool _finGrid = true;
  int _selItem = 0;
  int _selFin = 0;

  // Divisórias redimensionáveis
  double _cabWidth = 320;
  double _rodapeHeight = 260;

  List<Map<String, dynamic>> _itens = [];
  List<Map<String, dynamic>> _contas = [];

  // NF07 — Pagamentos
  List<NfePagamento> _pagamentos = [];
  NfeFatura? _fatura;
  List<NfeDuplicata> _duplicatas = [];
  bool _pagamentosLoading = false;
  // Campos de novo pagamento em edição inline
  String _novoPagTpag = '01';
  final TextEditingController _novoPagVpag = TextEditingController();
  // Campos fatura
  final TextEditingController _fatNFat = TextEditingController();
  final TextEditingController _fatVOrig = TextEditingController();
  final TextEditingController _fatVLiq = TextEditingController();
  // Campos de nova duplicata em edição inline
  final TextEditingController _dupNDup = TextEditingController();
  final TextEditingController _dupDVenc = TextEditingController();
  final TextEditingController _dupVDup = TextEditingController();

  // Dropdowns
  final List<Map<String, dynamic>> _empresas = [];
  List<Map<String, dynamic>> _parceiros = [];
  List<Map<String, dynamic>> _destinatarios =
      []; // parceiros do parceiro logado
  List<Map<String, dynamic>> _formasPagamento = [];
  List<Map<String, dynamic>> _finalidades = [];
  List<Map<String, dynamic>> _produtos = [];
  List<Map<String, dynamic>> _series = [];
  List<Map<String, dynamic>> _unidades = [];
  List<Map<String, dynamic>> _tiposOperacao = [];
  String? _tipoOperacaoId;
  Map<String, dynamic> _topSelected = {};

  // Controllers cabeçalho
  final _chaveCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _serieCtrl = TextEditingController();
  String? _statusVal;
  String? _ambienteVal;
  String? _empresaId;
  String? _parceiroId;
  String? _destinatarioId;
  String? _formaPagId;
  String? _finalidadeId;
  String? _serieId; // ID da série selecionada (separado do texto _serieCtrl)

  // Dados do usuário logado (para campos disabled)
  String? _empresaNome;
  String? _parceiroNome;
  bool get _isNovo => widget.item['id'] == null;

  String get _nfeId => widget.item['id']?.toString() ?? '';
  bool get _isEntrada =>
      widget.item['tipoOperacao']?.toString().toUpperCase() == 'ENTRADA';

  @override
  void initState() {
    super.initState();
    _initCabecalho();
    _loadDropdowns();
    if (!_isNovo) {
      _loadItens();
      _loadContas();
      _loadPagamentos();
    }
  }

  void _initCabecalho() {
    final i = widget.item;
    final login = AuthUtility.userInfo?.login;

    _chaveCtrl.text = i['chave']?.toString() ?? '';
    _numeroCtrl.text = i['numero']?.toString() ?? '';
    _serieCtrl.text = i['serie']?.toString() ?? '';

    // Status: PENDENTE para novo, mantém o existente para edição
    _statusVal = _isNovo ? 'PENDENTE' : (i['status']?.toString() ?? 'PENDENTE');
    _ambienteVal = i['ambiente']?.toString() ?? 'HOMOLOGACAO';

    // Empresa: prioriza localstore, fallback para o item
    final sessEmpId = login?.empresa?.id?.toString();
    _empresaId = sessEmpId ??
        (i['empresa'] is Map ? i['empresa']['id'] : i['empresa'])?.toString();
    _empresaNome = login?.empresa?.nome ??
        (i['empresa'] is Map ? i['empresa']['nome'] : null)?.toString();

    // Parceiro: prioriza localstore, fallback para o item
    final sessParcId = login?.parceiro?.id?.toString();
    _parceiroId = sessParcId ??
        (i['parceiro'] is Map ? i['parceiro']['id'] : i['parceiro'])
            ?.toString();
    _parceiroNome = login?.parceiro?.nome ??
        (i['parceiro'] is Map ? i['parceiro']['nome'] : null)?.toString();

    _destinatarioId =
        (i['destinatario'] is Map ? i['destinatario']['id'] : i['destinatario'])
            ?.toString();
    _formaPagId =
        (i['formaPagamento'] is Map ? i['formaPagamento']['id'] : null)
            ?.toString();
    _finalidadeId =
        (i['nfeFinalidade'] is Map ? i['nfeFinalidade']['id'] : null)
            ?.toString();

    final topData = i['nfeTipoOperacao'];
    _tipoOperacaoId = (topData is Map ? topData['id'] : topData)?.toString();
  }

  Future<void> _loadDropdowns() async {
    final login = AuthUtility.userInfo?.login;
    final parcId = login?.parceiro?.id?.toString() ?? _parceiroId;
    final empId = login?.empresa?.id?.toString() ?? _empresaId;

    await Future.wait([
      _loadList('${ApiLinks.baseUrl}/api/forma_pagamento?tamanho=100',
          (d) => setState(() => _formasPagamento = d)),
      _loadList('${ApiLinks.baseUrl}/api/nfe-finalidade?tamanho=50',
          (d) => setState(() => _finalidades = d)),
      _loadList(
          '${ApiLinks.baseUrl}/api/produto-contabil?tamanho=500${empId != null ? '&empId=$empId' : ''}${parcId != null ? '&parceiroId=$parcId' : ''}&isServico=false',
          (d) => setState(() => _produtos = d)),
      _loadList(
          '${ApiLinks.baseUrl}/api/nfe-serie?tamanho=100${empId != null ? '&empId=$empId' : ''}',
          (d) => setState(() {
                _series = d;
                // Resolve _serieId pelo texto já carregado no _serieCtrl (edição de NF-e existente)
                if (_serieCtrl.text.isNotEmpty && _serieId == null) {
                  final match = d
                      .where((s) => s['serie']?.toString() == _serieCtrl.text)
                      .firstOrNull;
                  if (match != null) _serieId = match['id']?.toString();
                }
              })),
      _loadList('${ApiLinks.baseUrl}/api/unidade_medida?tamanho=200',
          (d) => setState(() => _unidades = d)),
      _loadList(
          '${ApiLinks.baseUrl}/api/parceiro?tamanho=500${empId != null ? '&empId=$empId' : ''}',
          (d) => setState(() => _parceiros = d)),
      _loadList('${ApiLinks.baseUrl}/api/nfe-tipo-operacao?tamanho=200',
          (d) => setState(() => _tiposOperacao = d)),
      // Destinatários: parceiros vinculados ao parceiro logado (mesma empresa)
      _loadDestinatarios(empId, parcId),
    ]);

    if (_tipoOperacaoId != null) {
      final found = _tiposOperacao.firstWhere(
          (e) => e['id']?.toString() == _tipoOperacaoId,
          orElse: () => {});
      if (found.isNotEmpty) setState(() => _topSelected = found);
    }
  }

  Future<void> _loadDestinatarios(String? empId, String? parcId) async {
    // Busca parceiros da mesma empresa — são os possíveis destinatários
    final url = '${ApiLinks.baseUrl}/api/parceiro?tamanho=500'
        '${empId != null ? '&empId=$empId' : ''}'
        '${parcId != null ? '&parceiroId=$parcId' : ''}';
    await _loadList(url, (d) => setState(() => _destinatarios = d));
    // Se não retornou nada, busca sem filtro de parceiro (só empresa)
    if (_destinatarios.isEmpty && empId != null) {
      await _loadList(
          '${ApiLinks.baseUrl}/api/parceiro?tamanho=500&empId=$empId',
          (d) => setState(() => _destinatarios = d));
    }
  }

  Future<void> _loadList(
      String url, void Function(List<Map<String, dynamic>>) cb) async {
    try {
      final r = await TenantContext.get(url);
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        List raw = [];
        if (b is List) {
          raw = b;
        } else if (b is Map) {
          final data = b['data'];
          if (data is List) {
            raw = data;
          } else if (data is Map) {
            raw = data['dados'] ?? data['content'] ?? data['items'] ?? [];
          } else {
            raw = b['dados'] ?? b['content'] ?? b['items'] ?? [];
          }
        }
        cb(raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList());
      }
    } catch (_) {}
  }

  Future<void> _loadItens() async {
    try {
      final r = await TenantContext.get(
          '${ApiLinks.baseUrl}/api/nfe_item?nfeId=$_nfeId&tamanho=100');
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        final d =
            b is Map ? (b['data'] is Map ? b['data']['dados'] : b['data']) : b;
        setState(() {
          _itens = (d as List? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _atualizarTotaisNfe();
        });
        await _aplicarImpostosNosItensCarregados();
      }
    } catch (_) {}
  }

  Future<void> _loadContas() async {
    try {
      final ep = _isEntrada ? 'conta_pagar' : 'conta_receber';
      final r = await TenantContext.get(
          '${ApiLinks.baseUrl}/api/$ep?nfeId=$_nfeId&tamanho=100');
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        final d =
            b is Map ? (b['data'] is Map ? b['data']['dados'] : b['data']) : b;
        setState(() => _contas = (d as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList());
      }
    } catch (_) {}
  }

  // ── NF07: Pagamentos, Fatura, Duplicatas ─────────────────────────────────

  Future<void> _loadPagamentos() async {
    if (_isNovo) return;
    setState(() => _pagamentosLoading = true);
    try {
      // Pagamentos
      final rp = await TenantContext.get(
          '${ApiLinks.baseUrl}/api/nfe/$_nfeId/pagamentos');
      if (rp.statusCode == 200) {
        final b = jsonDecode(rp.body);
        final List raw = b is List
            ? b
            : (b['data'] is List
                ? b['data']
                : (b['data']?['dados'] ?? b['dados'] ?? []));
        setState(() => _pagamentos = raw
            .whereType<Map>()
            .map((e) => NfePagamento.fromJson(Map<String, dynamic>.from(e)))
            .toList());
      }
      // Fatura
      final rf =
          await TenantContext.get('${ApiLinks.baseUrl}/api/nfe/$_nfeId/fatura');
      if (rf.statusCode == 200) {
        try {
          final bf = jsonDecode(rf.body);
          final data = bf is Map ? (bf['data'] ?? bf) : bf;
          if (data is Map) {
            final fatura = NfeFatura.fromJson(Map<String, dynamic>.from(data));
            setState(() {
              _fatura = fatura;
              _fatNFat.text = fatura.nFat ?? '';
              _fatVOrig.text = fatura.vOrig?.toString() ?? '';
              _fatVLiq.text = fatura.vLiq?.toString() ?? '';
            });
          }
        } catch (_) {}
      }
      // Duplicatas
      final rd = await TenantContext.get(
          '${ApiLinks.baseUrl}/api/nfe/$_nfeId/duplicatas');
      if (rd.statusCode == 200) {
        final bd = jsonDecode(rd.body);
        final List rawd = bd is List
            ? bd
            : (bd['data'] is List
                ? bd['data']
                : (bd['data']?['dados'] ?? bd['dados'] ?? []));
        setState(() => _duplicatas = rawd
            .whereType<Map>()
            .map((e) => NfeDuplicata.fromJson(Map<String, dynamic>.from(e)))
            .toList());
      }
    } catch (_) {}
    setState(() => _pagamentosLoading = false);
  }

  Future<void> _adicionarPagamento() async {
    final vPag = double.tryParse(_novoPagVpag.text.replaceAll(',', '.'));
    if (vPag == null || vPag <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Informe um valor válido'), backgroundColor: _red));
      return;
    }
    try {
      final r = await TenantContext.post(
          '${ApiLinks.baseUrl}/api/nfe/$_nfeId/pagamentos',
          {'tPag': _novoPagTpag, 'vPag': vPag});
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 201) {
        _novoPagVpag.clear();
        await _loadPagamentos();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Pagamento adicionado!'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ${r.statusCode}'), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao processar. Tente novamente.'),
            backgroundColor: _red));
    }
  }

  Future<void> _removerPagamento(NfePagamento pag) async {
    if (pag.id == null) return;
    try {
      final r = await TenantContext.delete(
          '${ApiLinks.baseUrl}/api/nfe/$_nfeId/pagamentos/${pag.id}');
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 204) {
        await _loadPagamentos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ${r.statusCode}'), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao processar. Tente novamente.'),
            backgroundColor: _red));
    }
  }

  Future<void> _salvarFatura() async {
    final body = {
      'nFat': _fatNFat.text.trim(),
      'vOrig': double.tryParse(_fatVOrig.text.replaceAll(',', '.')),
      'vLiq': double.tryParse(_fatVLiq.text.replaceAll(',', '.')),
    };
    try {
      final r = _fatura?.id != null
          ? await TenantContext.put(
              '${ApiLinks.baseUrl}/api/nfe/$_nfeId/fatura', body)
          : await TenantContext.post(
              '${ApiLinks.baseUrl}/api/nfe/$_nfeId/fatura', body);
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 201) {
        await _loadPagamentos();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Fatura salva!'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ${r.statusCode}'), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao processar. Tente novamente.'),
            backgroundColor: _red));
    }
  }

  Future<void> _adicionarDuplicata() async {
    final vDup = double.tryParse(_dupVDup.text.replaceAll(',', '.'));
    if (vDup == null || vDup <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Informe um valor válido'), backgroundColor: _red));
      return;
    }
    final body = {
      'nDup': _dupNDup.text.trim(),
      'dVenc': _dupDVenc.text.trim(),
      'vDup': vDup,
    };
    try {
      final r = await TenantContext.post(
          '${ApiLinks.baseUrl}/api/nfe/$_nfeId/duplicatas', body);
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 201) {
        _dupNDup.clear();
        _dupDVenc.clear();
        _dupVDup.clear();
        await _loadPagamentos();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Duplicata adicionada!'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ${r.statusCode}'), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao processar. Tente novamente.'),
            backgroundColor: _red));
    }
  }

  Future<void> _removerDuplicata(NfeDuplicata dup) async {
    if (dup.id == null) return;
    try {
      final r = await TenantContext.delete(
          '${ApiLinks.baseUrl}/api/nfe/$_nfeId/duplicatas/${dup.id}');
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 204) {
        await _loadPagamentos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ${r.statusCode}'), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao processar. Tente novamente.'),
            backgroundColor: _red));
    }
  }

  Future<void> _gerarContasPagar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Gerar Contas a Pagar',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text(
            'Confirma a geração de Contas a Pagar para a NF-e #$_nfeId?\n'
            'Serão criadas ${_duplicatas.length} conta(s) baseadas nas duplicatas.',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _green, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Gerar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final r = await TenantContext.post(
          '${ApiLinks.baseUrl}/api/nfe/$_nfeId/gerar-contas-pagar', {});
      if (!mounted) return;
      String msg = r.statusCode == 200
          ? 'Contas a Pagar geradas com sucesso!'
          : 'Erro ${r.statusCode}. Tente novamente.';
      if (r.statusCode != 200) {
        try {
          final data = jsonDecode(r.body);
          if (data is Map && data['message'] != null && data['message'].toString().isNotEmpty) {
            msg = data['message'].toString();
          }
        } catch (_) {}
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: r.statusCode == 200 ? _green : _red));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao processar. Tente novamente.'),
            backgroundColor: _red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
          backgroundColor: _red,
          foregroundColor: Colors.white,
          title: Text('NF-e #$_nfeId - ${widget.item['tipoOperacao'] ?? ''}',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          actions: _isEntrada ? _actionsEntrada() : _actionsSaida()),
      body: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 768) {
          return SingleChildScrollView(
              child: Column(children: [
            SizedBox(height: 400, child: _cabecalho()),
            const Divider(height: 1),
            SizedBox(height: 400, child: _itensPanel()),
            const Divider(height: 1),
            SizedBox(height: 300, child: _rodape()),
          ]));
        }
        return Column(children: [
          Expanded(
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: _cabWidth, child: _cabecalho()),
            GestureDetector(
              onHorizontalDragUpdate: (d) => setState(
                  () => _cabWidth = (_cabWidth + d.delta.dx).clamp(200, 600)),
              child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: Container(
                      width: 6,
                      color: _bord,
                      child: const Center(
                          child: Icon(Icons.drag_indicator,
                              size: 14, color: _grey)))),
            ),
            Expanded(child: _itensPanel()),
          ])),
          GestureDetector(
            onVerticalDragUpdate: (d) => setState(() =>
                _rodapeHeight = (_rodapeHeight - d.delta.dy).clamp(120, 400)),
            child: MouseRegion(
                cursor: SystemMouseCursors.resizeRow,
                child: Container(
                    height: 6,
                    color: _bord,
                    child: const Center(
                        child:
                            Icon(Icons.drag_handle, size: 14, color: _grey)))),
          ),
          SizedBox(height: _rodapeHeight, child: _rodape()),
        ]);
      }),
    );
  }

  // ── AppBar Actions ────────────────────────────────────────────────────────

  List<Widget> _actionsSaida() => [
        _appBarBtn(Icons.send, 'Emitir', () => _emitir()),
        _appBarBtn(Icons.cancel_outlined, 'Cancelar', () => _cancelar()),
        _appBarBtn(Icons.print, 'DANFE', () => _imprimirDanfe()),
        _appBarBtn(Icons.code, 'XML', () => _baixarXml()),
        const SizedBox(width: 8),
      ];

  List<Widget> _actionsEntrada() => [
        _appBarBtn(Icons.upload_file, 'Importar XML', () => _importarXml()),
        _appBarBtn(Icons.check_circle_outline, 'Aceitar', () => _aceitar()),
        _appBarBtn(Icons.cancel_outlined, 'Recusar', () => _recusar()),
        const SizedBox(width: 8),
      ];

  Widget _appBarBtn(IconData icon, String label, VoidCallback onTap) =>
      TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: Colors.white),
        label: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 11)),
        style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8)),
      );

  // ── Ações NF-e SAÍDA ──────────────────────────────────────────────────────

  // NF08: usa POST /api/nfe/{id}/emitir (geração de XML real)
  Future<void> _emitir() async {
    if (_isNovo) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Salve a NF-e antes de emitir'),
          backgroundColor: _red));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Emitir NF-e',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Confirma a emissão da NF-e #$_nfeId?',
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              const Text('O XML será gerado e assinado digitalmente.',
                  style: TextStyle(fontSize: 11, color: _grey)),
            ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _green, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Emitir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      // NF08: novo endpoint que gera XML real e assina digitalmente
      final r = await TenantContext.post(ApiLinks.emitirNfe(_nfeId), {});
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 201) {
        try {
          final decoded = jsonDecode(r.body);
          if (decoded is Map<String, dynamic>) {
            _aplicarCabecalhoAtualizado(decoded);
          }
        } catch (_) {}
        await _recarregarCabecalhoNfe();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('NF-e emitida com sucesso! XML gerado e assinado.'),
            backgroundColor: _green));
      } else {
        final msg = fiscalErrorMessage(r.statusCode, r.body);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao processar. Tente novamente.'),
            backgroundColor: _red));
    }
  }

  Future<void> _recarregarCabecalhoNfe() async {
    if (_nfeId.isEmpty) return;
    try {
      final r = await TenantContext.get(ApiLinks.nfeById(_nfeId));
      if (r.statusCode != 200) return;
      final decoded = jsonDecode(r.body);
      if (decoded is Map<String, dynamic>) {
        _aplicarCabecalhoAtualizado(decoded);
      }
    } catch (_) {}
  }

  void _aplicarCabecalhoAtualizado(Map<String, dynamic> dados) {
    final data = dados['data'];
    final atualizado = data is Map<String, dynamic> ? data : dados;
    widget.item.addAll(atualizado);
    if (!mounted) return;
    setState(_initCabecalho);
  }

  Future<void> _cancelar() async {
    final motivoCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar NF-e',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('NF-e #$_nfeId',
                  style: const TextStyle(fontSize: 12, color: _grey)),
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
                backgroundColor: _red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar NF-e'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (motivoCtrl.text.trim().length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Motivo deve ter pelo menos 15 caracteres'),
          backgroundColor: _red));
      return;
    }
    try {
      final r = await TenantContext.post(ApiLinks.cancelarNfe(_nfeId),
          {'justificativa': motivoCtrl.text.trim()});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r.statusCode == 200
              ? 'NF-e cancelada!'
              : 'Erro ${r.statusCode}. Tente novamente.'),
          backgroundColor: r.statusCode == 200 ? _green : _red));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao processar. Tente novamente.'),
            backgroundColor: _red));
    }
  }

  Future<void> _imprimirDanfe() async {
    try {
      final r = await TenantContext.get(ApiLinks.danfeNfe(_nfeId));
      if (!mounted) return;
      if (r.statusCode == 200) {
        await FileSaver.instance.saveFile(
          name: 'danfe_$_nfeId',
          bytes: r.bodyBytes,
          fileExtension: 'pdf',
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('DANFE baixado!'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(fiscalErrorMessage(r.statusCode, r.body)),
            backgroundColor: _red));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao processar. Tente novamente.'),
            backgroundColor: _red));
    }
  }

  Future<void> _baixarXml() async {
    try {
      final r = await TenantContext.get(ApiLinks.xmlNfe(_nfeId));
      if (!mounted) return;
      if (r.statusCode == 200) {
        await FileSaver.instance.saveFile(
          name: 'nfe_$_nfeId',
          bytes: Uint8List.fromList(r.body.codeUnits),
          fileExtension: 'xml',
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('XML baixado!'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(fiscalErrorMessage(r.statusCode, r.body)),
            backgroundColor: _red));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao processar. Tente novamente.'),
            backgroundColor: _red));
    }
  }

  // ── Ações NF-e ENTRADA ────────────────────────────────────────────────────

  Future<void> _importarXml() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xml'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    try {
      final r = await TenantContext.postMultipart(
        '${ApiLinks.baseUrl}/api/nfe/entrada/import',
        fileBytes: file.bytes!,
        fileName: file.name,
        fileField: 'xml',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r.statusCode == 200
              ? 'XML importado com sucesso!'
              : 'Erro ${r.statusCode}. Tente novamente.'),
          backgroundColor: r.statusCode == 200 ? _green : _red));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao processar. Tente novamente.'),
            backgroundColor: _red));
    }
  }

  Future<void> _aceitar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aceitar NF-e',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Confirma o aceite da NF-e #$_nfeId?',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _green, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aceitar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final r = await TenantContext.post(ApiLinks.aceitarNfe(_nfeId), {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              r.statusCode == 200 ? 'NF-e aceita!' : 'Erro ${r.statusCode}'),
          backgroundColor: r.statusCode == 200 ? _green : _red));
      if (r.statusCode == 200) setState(() => _statusVal = 'AUTORIZADA');
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao processar. Tente novamente.'),
            backgroundColor: _red));
    }
  }

  Future<void> _recusar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Recusar NF-e',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Confirma a recusa da NF-e #$_nfeId?',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Recusar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final r = await TenantContext.post(ApiLinks.recusarNfe(_nfeId), {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              r.statusCode == 200 ? 'NF-e recusada!' : 'Erro ${r.statusCode}'),
          backgroundColor: r.statusCode == 200 ? _green : _red));
      if (r.statusCode == 200) setState(() => _statusVal = 'CANCELADA');
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao processar. Tente novamente.'),
            backgroundColor: _red));
    }
  }

  // ── CABEÇALHO com dropdowns ──
  Widget _cabecalho() {
    final hasSession = AuthUtility.userInfo?.login != null;

    return Container(
        color: Colors.white,
        child: Column(children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: _green,
              child: Row(children: [
                const Expanded(
                    child: Text('Cabeçalho',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12))),
                SizedBox(
                    height: 24,
                    child: ElevatedButton.icon(
                        onPressed: _salvarCabecalho,
                        icon: const Icon(Icons.save, size: 12),
                        label: const Text('Salvar',
                            style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _green,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8)))),
              ])),
          Expanded(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(10),
                  child: Column(children: [
                    // Chave: sempre disabled (gerada na transmissão)
                    _inpDisabled('Chave', _chaveCtrl),
                    // Número: disabled (preenchido automaticamente pela série)
                    _inpDisabled('Número', _numeroCtrl),
                    // Série: dropdown para SAÍDA (auto-preenche número), input para ENTRADA
                    _isEntrada
                        ? _inp('Série', _serieCtrl)
                        : _ddObjSerie('Série', _serieId, _series),
                    // Tipo de Operação: usado para pré-preencher CFOP/CST/Alíquota ICMS no Novo Item
                    _ddTipoOperacao(),
                    // Status: disabled (PENDENTE no insert, muda só ao transmitir)
                    _inpDisabledText('Status', _statusVal ?? 'PENDENTE'),
                    _dd('Ambiente', _ambienteVal, ['HOMOLOGACAO', 'PRODUCAO'],
                        (v) => setState(() => _ambienteVal = v)),
                    // Empresa: disabled, vem do localstore
                    hasSession && _empresaNome != null
                        ? _inpDisabledText('Empresa', _empresaNome!)
                        : _ddObj('Empresa', _empresaId, _empresas, 'nome',
                            (v) => setState(() => _empresaId = v)),
                    // Parceiro: disabled, vem do localstore
                    hasSession && _parceiroNome != null
                        ? _inpDisabledText('Parceiro', _parceiroNome!)
                        : _ddObj('Parceiro', _parceiroId, _parceiros, 'nome',
                            (v) => setState(() => _parceiroId = v)),
                    // Destinatário: dropdown filtrado pelos parceiros do parceiro logado
                    _ddObjSearch(
                        'Destinatário',
                        _destinatarioId,
                        _destinatarios,
                        'nome',
                        (v) => setState(() => _destinatarioId = v)),
                    _ddObj('Forma de Pagamento', _formaPagId, _formasPagamento,
                        'descricao', (v) => setState(() => _formaPagId = v)),
                    _ddObj('Finalidade', _finalidadeId, _finalidades,
                        'descricao', (v) => setState(() => _finalidadeId = v)),
                  ]))),
        ]));
  }

  /// Dropdown de Tipo de Operação — define CFOP/CST/Alíquota ICMS herdados pelos itens
  Widget _ddTipoOperacao() {
    final opts = _tiposOperacao
        .map((e) => <String, dynamic>{
              'id': e['id']?.toString() ?? '',
              'nome': '${e['codigo'] ?? ''} - ${e['descricao'] ?? ''}',
            })
        .toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SearchableDropdownField(
        label: 'Tipo de Operação',
        value: opts.any((o) => o['id'] == _tipoOperacaoId)
            ? _tipoOperacaoId
            : null,
        items: opts,
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        nullLabel: '— Selecione —',
        onChanged: (v) {
          setState(() {
            _tipoOperacaoId = v;
            _topSelected = _tiposOperacao
                .firstWhere((e) => e['id']?.toString() == v, orElse: () => {});
          });
        },
      ),
    );
  }

  /// Campo de texto desabilitado (readonly visual)
  Widget _inpDisabled(String label, TextEditingController ctrl) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextFormField(
          controller: ctrl,
          enabled: false,
          style: const TextStyle(fontSize: 12, color: _grey),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 11, color: _grey),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: _bord)),
            disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: _bord)),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
        ),
      );

  /// Campo de texto desabilitado com valor fixo (sem controller)
  Widget _inpDisabledText(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 11, color: _grey),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: _bord)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: _bord)),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          child:
              Text(value, style: const TextStyle(fontSize: 12, color: _grey)),
        ),
      );

  Widget _ddObjSearch(
      String label,
      String? val,
      List<Map<String, dynamic>> opts,
      String displayField,
      void Function(String?) cb) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SearchableDropdownField(
        label: label,
        value: opts.any((o) => o['id']?.toString() == val) ? val : null,
        items: opts
            .map((o) => <String, dynamic>{
                  'id': o['id']?.toString() ?? '',
                  'nome': o[displayField]?.toString() ?? '',
                })
            .toList(),
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        nullLabel: '— Selecione —',
        onChanged: cb,
      ),
    );
  }

  Widget _inp(String label, TextEditingController ctrl) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
          controller: ctrl,
          style: const TextStyle(fontSize: 12, color: _dark),
          decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(fontSize: 11, color: _grey),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: _bord)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: _green, width: 1.5)),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8))));

  Widget _dd(String label, String? val, List<String> opts,
          void Function(String?) cb) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SearchableDropdownField(
            label: label,
            value: val,
            items:
                opts.map((o) => <String, dynamic>{'id': o, 'nome': o}).toList(),
            valueField: 'id',
            displayField: 'nome',
            nullable: true,
            nullLabel: '— Selecione —',
            onChanged: cb,
          ));

  Widget _ddObj(String label, String? val, List<Map<String, dynamic>> opts,
      String displayField, void Function(String?) cb) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SearchableDropdownField(
        label: label,
        value: opts.any((o) => o['id']?.toString() == val) ? val : null,
        items: opts
            .map((o) => <String, dynamic>{
                  'id': o['id']?.toString() ?? '',
                  'nome': o[displayField]?.toString() ?? '',
                })
            .toList(),
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        nullLabel: '— Selecione —',
        onChanged: cb,
      ),
    );
  }

  Future<void> _salvarItem(Map<String, dynamic> item) async {
    final isNew = item['id'] == null;
    _prepararItemFiscal(item);
    final body = <String, dynamic>{
      if (!isNew) 'id': item['id'],
      'nfeId': item['nfe_id'] ?? int.tryParse(_nfeId),
      'nfe_id': item['nfe_id'] ?? int.tryParse(_nfeId),
      if (item['produto'] != null) 'produto': item['produto'],
      'xProd': item['x_prod'] ?? item['xProd'] ?? '',
      'x_prod': item['x_prod'] ?? item['xProd'] ?? '',
      'ncm': item['ncm'] ?? '',
      'cfop': item['cfop'] ?? '',
      'uCom': item['u_com'] ?? item['uCom'] ?? '',
      'u_com': item['u_com'] ?? item['uCom'] ?? '',
      'qCom': _asDouble(item['q_com'] ?? item['qCom']) ?? 1,
      'q_com': _asDouble(item['q_com'] ?? item['qCom']) ?? 1,
      'vUnCom': _asDouble(item['v_un_com'] ?? item['vUnCom']) ?? 0,
      'v_un_com': _asDouble(item['v_un_com'] ?? item['vUnCom']) ?? 0,
      'vProd': _asDouble(item['v_prod'] ?? item['vProd']) ?? 0,
      'v_prod': _asDouble(item['v_prod'] ?? item['vProd']) ?? 0,
      'cstIcms': item['cst_icms'] ?? item['cstIcms'] ?? '',
      'cst_icms': item['cst_icms'] ?? item['cstIcms'] ?? '',
      'aliqIcms': _asDouble(item['aliq_icms'] ?? item['aliqIcms']),
      'aliq_icms': _asDouble(item['aliq_icms'] ?? item['aliqIcms']),
      'vBcIcms': _asDouble(item['v_bc_icms'] ?? item['vBcIcms']),
      'v_bc_icms': _asDouble(item['v_bc_icms'] ?? item['vBcIcms']),
      'vIcms': _asDouble(item['v_icms'] ?? item['vIcms']),
      'v_icms': _asDouble(item['v_icms'] ?? item['vIcms']),
      'cstPis': item['cst_pis'] ?? item['cstPis'],
      'cst_pis': item['cst_pis'] ?? item['cstPis'],
      'pPis': _asDouble(item['p_pis'] ?? item['pPis']),
      'p_pis': _asDouble(item['p_pis'] ?? item['pPis']),
      'vBcPis': _asDouble(item['v_bc_pis'] ?? item['vBcPis']),
      'v_bc_pis': _asDouble(item['v_bc_pis'] ?? item['vBcPis']),
      'vPis': _asDouble(item['v_pis'] ?? item['vPis']),
      'v_pis': _asDouble(item['v_pis'] ?? item['vPis']),
      'cstCofins': item['cst_cofins'] ?? item['cstCofins'],
      'cst_cofins': item['cst_cofins'] ?? item['cstCofins'],
      'pCofins': _asDouble(item['p_cofins'] ?? item['pCofins']),
      'p_cofins': _asDouble(item['p_cofins'] ?? item['pCofins']),
      'vBcCofins': _asDouble(item['v_bc_cofins'] ?? item['vBcCofins']),
      'v_bc_cofins': _asDouble(item['v_bc_cofins'] ?? item['vBcCofins']),
      'vCofins': _asDouble(item['v_cofins'] ?? item['vCofins']),
      'v_cofins': _asDouble(item['v_cofins'] ?? item['vCofins']),
      'cstIpi': item['cst_ipi'] ?? item['cstIpi'],
      'cst_ipi': item['cst_ipi'] ?? item['cstIpi'],
      'aliqIpi': _asDouble(item['aliq_ipi'] ?? item['aliqIpi']),
      'aliq_ipi': _asDouble(item['aliq_ipi'] ?? item['aliqIpi']),
      'vBcIpi': _asDouble(item['v_bc_ipi'] ?? item['vBcIpi']),
      'v_bc_ipi': _asDouble(item['v_bc_ipi'] ?? item['vBcIpi']),
      'vIpi': _asDouble(item['v_ipi'] ?? item['vIpi']),
      'v_ipi': _asDouble(item['v_ipi'] ?? item['vIpi']),
      'cstIbsCbs': item['cst_ibs_cbs'] ?? item['cstIbsCbs'],
      'cst_ibs_cbs': item['cst_ibs_cbs'] ?? item['cstIbsCbs'],
      'pCbs': _asDouble(item['p_cbs'] ?? item['pCbs']),
      'p_cbs': _asDouble(item['p_cbs'] ?? item['pCbs']),
      'pIbsUf': _asDouble(item['p_ibs_uf'] ?? item['pIbsUf']),
      'p_ibs_uf': _asDouble(item['p_ibs_uf'] ?? item['pIbsUf']),
      'pIbsMun': _asDouble(item['p_ibs_mun'] ?? item['pIbsMun']),
      'p_ibs_mun': _asDouble(item['p_ibs_mun'] ?? item['pIbsMun']),
      'vBcIbsCbs': _asDouble(item['v_bc_ibs_cbs'] ?? item['vBcIbsCbs']),
      'v_bc_ibs_cbs': _asDouble(item['v_bc_ibs_cbs'] ?? item['vBcIbsCbs']),
      'vCbs': _asDouble(item['v_cbs'] ?? item['vCbs']),
      'v_cbs': _asDouble(item['v_cbs'] ?? item['vCbs']),
      'vIbs': _asDouble(item['v_ibs'] ?? item['vIbs']),
      'v_ibs': _asDouble(item['v_ibs'] ?? item['vIbs']),
      'vTotTrib': _asDouble(item['v_tot_trib'] ?? item['vTotTrib']),
      'v_tot_trib': _asDouble(item['v_tot_trib'] ?? item['vTotTrib']),
    };
    try {
      final r = isNew
          ? await TenantContext.post('${ApiLinks.baseUrl}/api/nfe_item', body)
          : await TenantContext.put(
              '${ApiLinks.baseUrl}/api/nfe_item/${item['id']}', body);
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 201) {
        if (isNew) {
          try {
            final b = jsonDecode(r.body);
            final newId = b is Map
                ? (b['data'] is Map ? b['data']['id'] : (b['data'] ?? b['id']))
                : null;
            if (newId != null) setState(() => item['id'] = newId);
          } catch (_) {}
        }
        setState(() {
          _atualizarTotaisNfe();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Item salvo!'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ${r.statusCode}'), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao processar. Tente novamente.'),
            backgroundColor: _red));
      }
    }
  }

  Future<void> _salvarCabecalho() async {
    final body = <String, dynamic>{
      if (!_isNovo) 'id': widget.item['id'],
      'chave': _chaveCtrl.text,
      'numero': _numeroCtrl.text,
      'serie': _serieCtrl.text,
      if (_serieId != null) 'serieId': int.tryParse(_serieId!) ?? _serieId,
      if (_statusVal != null) 'status': _statusVal,
      if (_ambienteVal != null) 'ambiente': _ambienteVal,
      'tipoOperacao': widget.item['tipoOperacao'] ?? 'SAIDA',
      if (_empresaId != null)
        'empresa': {'id': int.tryParse(_empresaId!) ?? _empresaId},
      if (_parceiroId != null)
        'parceiro': {'id': int.tryParse(_parceiroId!) ?? _parceiroId},
      if (_destinatarioId != null)
        'destinatario': {
          'id': int.tryParse(_destinatarioId!) ?? _destinatarioId
        },
      if (_formaPagId != null)
        'formaPagamento': {'id': int.tryParse(_formaPagId!) ?? _formaPagId},
      if (_finalidadeId != null)
        'nfeFinalidade': {'id': int.tryParse(_finalidadeId!) ?? _finalidadeId},
      if (_tipoOperacaoId != null)
        'nfeTipoOperacao': {
          'id': int.tryParse(_tipoOperacaoId!) ?? _tipoOperacaoId
        },
      if (_empresaId != null)
        'empresaId': int.tryParse(_empresaId!) ?? _empresaId,
      if (_parceiroId != null)
        'parceiroId': int.tryParse(_parceiroId!) ?? _parceiroId,
      if (_destinatarioId != null)
        'destinatarioId': int.tryParse(_destinatarioId!) ?? _destinatarioId,
      if (_formaPagId != null)
        'formaPagamentoId': int.tryParse(_formaPagId!) ?? _formaPagId,
      if (_finalidadeId != null)
        'nfeFinalidadeId': int.tryParse(_finalidadeId!) ?? _finalidadeId,
      if (_tipoOperacaoId != null)
        'nfeTipoOperacaoId': int.tryParse(_tipoOperacaoId!) ?? _tipoOperacaoId,
    };
    try {
      final r = _isNovo
          ? await TenantContext.post('${ApiLinks.baseUrl}/api/nfe', body)
          : await TenantContext.put(
              '${ApiLinks.baseUrl}/api/nfe/${widget.item['id']}', body);
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 201) {
        try {
          final b = jsonDecode(r.body);
          if (b is Map<String, dynamic>) {
            _aplicarCabecalhoAtualizado(b);
          }
        } catch (_) {}
        // Para nova NF-e: captura o ID retornado e carrega os itens/contas
        if (_isNovo) {
          try {
            final b = jsonDecode(r.body);
            final newId = b is Map
                ? (b['data'] is Map ? b['data']['id'] : (b['data'] ?? b['id']))
                : null;
            if (newId != null) {
              setState(() => widget.item['id'] = newId);
              _loadItens();
              _loadContas();
            }
          } catch (_) {}
        }
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Salvo!'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ${r.statusCode}'), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao processar. Tente novamente.'),
            backgroundColor: _red));
    }
  }

  // ── ITENS: DynamicGridWindowsScreen sem botão Novo + toggle para form ──
  Widget _itensPanel() {
    return Container(
        color: Colors.white,
        child: Column(children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: const Color(0xFFF8F8F8),
              child: Row(children: [
                const Text('Itens',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 8),
                _togBtn(Icons.view_list, _itensGrid,
                    () => setState(() => _itensGrid = true)),
                const SizedBox(width: 4),
                _togBtn(Icons.edit_note, !_itensGrid,
                    () => setState(() => _itensGrid = false)),
                const SizedBox(width: 8),
                // Botão Novo abre o form customizado
                SizedBox(
                    height: 24,
                    child: ElevatedButton.icon(
                        onPressed: _novoItem,
                        icon: const Icon(Icons.add, size: 12),
                        label:
                            const Text('Novo', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10)))),
                if (!_itensGrid && _itens.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  SizedBox(
                      height: 24,
                      child: ElevatedButton.icon(
                          onPressed: () => _salvarItem(_itens[_selItem]),
                          icon: const Icon(Icons.save, size: 12),
                          label: const Text('Salvar',
                              style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: _green,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8)))),
                ],
                const Spacer(),
                if (!_itensGrid && _itens.isNotEmpty) ...[
                  _nb(Icons.first_page, () => setState(() => _selItem = 0)),
                  _nb(
                      Icons.chevron_left,
                      () => setState(() {
                            if (_selItem > 0) _selItem--;
                          })),
                  Text(' ${_selItem + 1}/${_itens.length} ',
                      style: const TextStyle(fontSize: 11)),
                  _nb(
                      Icons.chevron_right,
                      () => setState(() {
                            if (_selItem < _itens.length - 1) _selItem++;
                          })),
                  _nb(Icons.last_page,
                      () => setState(() => _selItem = _itens.length - 1)),
                ],
              ])),
          Container(height: 1, color: _bord),
          // Grid: usa DynamicGridWindowsScreen sem botão Novo (hasPermission create=false)
          // Form: usa o form customizado com dropdowns
          Expanded(
              child: _itensGrid
                  ? ((_nfeId.isEmpty ||
                          _nfeId == '0' ||
                          int.tryParse(_nfeId) == null ||
                          int.tryParse(_nfeId)! <= 0)
                      ? const Center(
                          child: Text('Nenhum item cadastrado',
                              style: TextStyle(color: _grey)))
                      : _gridSemHeader(
                          telaNome: 'nfe_item',
                          extraParams: {'nfeId': _nfeId, 'nfe_id': _nfeId},
                        ))
                  : (_itens.isEmpty
                      ? const Center(
                          child: Text('Nenhum item',
                              style: TextStyle(color: _grey)))
                      : _iForm())),
        ]));
  }

  Widget _iForm() {
    if (_selItem >= _itens.length) return const SizedBox();
    final item = _itens[_selItem];
    final prodId =
        (item['produto'] is Map ? item['produto']['id'] : item['produto_id'])
            ?.toString();
    return SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          // Produto SearchableDropdownField — busca paginada no backend filtrada por tenant (empresa e parceiro)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Builder(builder: (context) {
              final login = AuthUtility.userInfo?.login;
              final parcId = login?.parceiro?.id?.toString() ?? _parceiroId;
              final empId = login?.empresa?.id?.toString() ?? _empresaId;
              return SearchableDropdownField(
                label: 'Produto',
                value: prodId,
                items: _produtos,
                valueField: 'id',
                displayField: 'nome',
                nullable: true,
                nullLabel: '— Selecione —',
                loadPage: ({String? busca, required int pagina}) =>
                    DropdownHelpers.produtosContabeisBusca(
                  busca: busca,
                  pagina: pagina,
                  tamanho: 20,
                  empresaId: empId,
                  parceiroId: parcId,
                ),
                labelResolver: DropdownHelpers.produtoContabilLabelPorId,
                onChanged: (v) {
                  setState(() {
                    item['produto'] = {'id': int.tryParse(v ?? '') ?? v};
                  });
                },
                onItemSelected: (selected) {
                  if (selected == null) return;
                  final v = selected['id']?.toString();
                  setState(() {
                    item['produto'] = {'id': int.tryParse(v ?? '') ?? v};
                    item['x_prod'] = selected['nome']?.toString() ?? '';
                    item['xProd'] = item['x_prod'];
                    item['ncm'] = selected['ncm']?.toString() ?? '';
                    item['cfop'] = selected['cfop']?.toString() ?? '';
                    final u = (selected['unidadeComercial'] ??
                            selected['unidade_comercial'] ??
                            selected['unidade'])
                        ?.toString()
                        .trim();
                    item['u_com'] =
                        u != null && u.isNotEmpty ? u.toUpperCase() : '';
                    item['uCom'] = item['u_com'];
                    item['v_un_com'] = selected['preco']?.toString() ?? '0.00';
                    item['vUnCom'] = item['v_un_com'];
                    item['q_com'] = item['q_com'] ?? item['qCom'] ?? '1.00';
                    item['qCom'] = item['q_com'];

                    // Tributos diretos do produto
                    if (selected['cst_csosn'] != null ||
                        selected['cstCsosn'] != null) {
                      item['cst_icms'] =
                          (selected['cst_csosn'] ?? selected['cstCsosn'])
                              .toString();
                      item['cstIcms'] = item['cst_icms'];
                    }
                    if (selected['aliquota_icms'] != null ||
                        selected['aliquotaIcms'] != null) {
                      item['aliq_icms'] = (selected['aliquota_icms'] ??
                              selected['aliquotaIcms'])
                          .toString();
                      item['aliqIcms'] = item['aliq_icms'];
                    }
                    if (selected['cst_ibs_cbs'] != null ||
                        selected['cstIbsCbs'] != null) {
                      item['cst_ibs_cbs'] =
                          (selected['cst_ibs_cbs'] ?? selected['cstIbsCbs'])
                              .toString();
                      item['cstIbsCbs'] = item['cst_ibs_cbs'];
                    }
                    if (selected['aliquota_cbs'] != null ||
                        selected['aliquotaCbs'] != null) {
                      item['p_cbs'] =
                          (selected['aliquota_cbs'] ?? selected['aliquotaCbs'])
                              .toString();
                      item['pCbs'] = item['p_cbs'];
                    }
                    if (selected['aliquota_ibs_uf'] != null ||
                        selected['aliquotaIbsUf'] != null) {
                      item['p_ibs_uf'] = (selected['aliquota_ibs_uf'] ??
                              selected['aliquotaIbsUf'])
                          .toString();
                      item['pIbsUf'] = item['p_ibs_uf'];
                    }
                    if (selected['aliquota_ibs_mun'] != null ||
                        selected['aliquotaIbsMun'] != null) {
                      item['p_ibs_mun'] = (selected['aliquota_ibs_mun'] ??
                              selected['aliquotaIbsMun'])
                          .toString();
                      item['pIbsMun'] = item['p_ibs_mun'];
                    }
                    NfeTaxAliases.applyProdutoSelecionado(item, selected);

                    _recalcularTotalItem(item);

                    // Busca impostos detalhados por UF (PIS, COFINS, IPI, etc.) se houver
                    if (v != null && v.toString().isNotEmpty) {
                      TenantContext.get(
                              '${ApiLinks.baseUrl}/api/produto-imposto-uf?produtoId=$v')
                          .then((r) {
                        if (r.statusCode == 200) {
                          try {
                            final list = jsonDecode(r.body);
                            if (list is List && list.isNotEmpty) {
                              final imp = list.first as Map<String, dynamic>;
                              setState(() {
                                if (imp['cstCsosn'] != null) {
                                  item['cst_icms'] = imp['cstCsosn'].toString();
                                  item['cstIcms'] = item['cst_icms'];
                                }
                                if (imp['aliquotaIcms'] != null) {
                                  item['aliq_icms'] =
                                      imp['aliquotaIcms'].toString();
                                  item['aliqIcms'] = item['aliq_icms'];
                                }
                                if (imp['cstPis'] != null) {
                                  item['cst_pis'] = imp['cstPis'].toString();
                                  item['cstPis'] = item['cst_pis'];
                                }
                                if (imp['pPis'] != null) {
                                  item['p_pis'] = imp['pPis'].toString();
                                  item['pPis'] = item['p_pis'];
                                }
                                if (imp['cstCofins'] != null) {
                                  item['cst_cofins'] =
                                      imp['cstCofins'].toString();
                                  item['cstCofins'] = item['cst_cofins'];
                                }
                                if (imp['pCofins'] != null) {
                                  item['p_cofins'] = imp['pCofins'].toString();
                                  item['pCofins'] = item['p_cofins'];
                                }
                                if (imp['cstIpi'] != null) {
                                  item['cst_ipi'] = imp['cstIpi'].toString();
                                  item['cstIpi'] = item['cst_ipi'];
                                }
                                if (imp['aliqIpi'] != null) {
                                  item['aliq_ipi'] = imp['aliqIpi'].toString();
                                  item['aliqIpi'] = item['aliq_ipi'];
                                }
                                if (imp['cstIbsCbs'] != null) {
                                  item['cst_ibs_cbs'] =
                                      imp['cstIbsCbs'].toString();
                                  item['cstIbsCbs'] = item['cst_ibs_cbs'];
                                }
                                if (imp['pCbs'] != null) {
                                  item['p_cbs'] = imp['pCbs'].toString();
                                  item['pCbs'] = item['p_cbs'];
                                }
                                if (imp['pIbsUf'] != null) {
                                  item['p_ibs_uf'] = imp['pIbsUf'].toString();
                                  item['pIbsUf'] = item['p_ibs_uf'];
                                }
                                if (imp['pIbsMun'] != null) {
                                  item['p_ibs_mun'] = imp['pIbsMun'].toString();
                                  item['pIbsMun'] = item['p_ibs_mun'];
                                }
                                NfeTaxAliases.applyProdutoImpostoUf(item, imp);
                                _recalcularTotalItem(item);
                              });
                            }
                          } catch (_) {}
                        }
                      });
                    }
                  });
                },
              );
            }),
          ),
          // Estado vazio do lookup de Produto: oferece cadastro de novo produto
          if (_produtos.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _abrirCadastroProduto,
                    icon: const Icon(Icons.add_business, size: 14),
                    label: const Text('Cadastrar novo produto',
                        style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: _green,
                        side: const BorderSide(color: _green),
                        padding: const EdgeInsets.symmetric(vertical: 6)),
                  )),
            ),
          _iInp('Descrição (xProd)', item, 'x_prod', 'xProd'),
          _iInp('NCM', item, 'ncm', 'ncm'),
          _iInp('CFOP', item, 'cfop', 'cfop'),
          // Unidade como dropdown
          _ddObjItem(
              'Unidade',
              item['u_com']?.toString() ?? item['uCom']?.toString(),
              _unidades.isNotEmpty
                  ? _unidades.map((u) {
                      final sigla = (u['nome'] ?? u['sigla'] ?? u['id'])
                              ?.toString()
                              .trim() ??
                          '';
                      final desc = u['descricao']?.toString().trim();
                      return <String, dynamic>{
                        'id': sigla,
                        'nome':
                            (desc != null && desc.isNotEmpty && desc != sigla)
                                ? '$sigla - $desc'
                                : sigla,
                      };
                    }).toList()
                  : _unidadesFallback(),
              'nome', (v) {
            setState(() {
              item['u_com'] = v;
              item['uCom'] = v;
            });
          }),
          _iInp('Quantidade', item, 'q_com', 'qCom'),
          _iInp('Vl. Unitário', item, 'v_un_com', 'vUnCom'),
          _iInp('Vl. Total', item, 'v_prod', 'vProd'),
          // ICMS
          _iInp('CST ICMS', item, 'cst_icms', 'cstIcms'),
          _iInp('Alíq. ICMS (%)', item, 'aliq_icms', 'aliqIcms'),
          _iInp('BC ICMS', item, 'v_bc_icms', 'vBcIcms'),
          _iInp('Vl. ICMS', item, 'v_icms', 'vIcms'),

          // PIS
          _iInp('CST PIS', item, 'cst_pis', 'cstPis'),
          _iInp('Alíq. PIS (%)', item, 'p_pis', 'pPis'),
          _iInp('BC PIS', item, 'v_bc_pis', 'vBcPis'),
          _iInp('Vl. PIS', item, 'v_pis', 'vPis'),

          // COFINS
          _iInp('CST COFINS', item, 'cst_cofins', 'cstCofins'),
          _iInp('Alíq. COFINS (%)', item, 'p_cofins', 'pCofins'),
          _iInp('BC COFINS', item, 'v_bc_cofins', 'vBcCofins'),
          _iInp('Vl. COFINS', item, 'v_cofins', 'vCofins'),

          // IPI
          _iInp('CST IPI', item, 'cst_ipi', 'cstIpi'),
          _iInp('Alíq. IPI (%)', item, 'aliq_ipi', 'aliqIpi'),
          _iInp('BC IPI', item, 'v_bc_ipi', 'vBcIpi'),
          _iInp('Vl. IPI', item, 'v_ipi', 'vIpi'),

          // IBS / CBS
          _iInp('CST IBS/CBS', item, 'cst_ibs_cbs', 'cstIbsCbs'),
          _iInp('Alíq. CBS (%)', item, 'p_cbs', 'pCbs'),
          _iInp('Alíq. IBS UF (%)', item, 'p_ibs_uf', 'pIbsUf'),
          _iInp('Alíq. IBS Mun (%)', item, 'p_ibs_mun', 'pIbsMun'),
          _iInp('BC IBS/CBS', item, 'v_bc_ibs_cbs', 'vBcIbsCbs'),
          _iInp('Vl. CBS', item, 'v_cbs', 'vCbs'),
          _iInp('Vl. IBS', item, 'v_ibs', 'vIbs'),

          // Total Tributos
          _iInp('Tot. Tributos', item, 'v_tot_trib', 'vTotTrib'),
          // NF03: Botão Calcular Impostos
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _calcularIcms(item),
                  icon: const Icon(Icons.calculate_outlined, size: 14),
                  label: const Text('Calcular Impostos',
                      style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: _green,
                      side: const BorderSide(color: _green),
                      padding: const EdgeInsets.symmetric(vertical: 6)),
                )),
          ),
          const SizedBox(height: 12),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                  onPressed: () => _salvarItem(item),
                  icon: const Icon(Icons.save, size: 14),
                  label: const Text('Salvar Item',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10)))),
        ]));
  }

  // NF03: Calculadora ICMS
  Future<void> _calcularIcms(Map<String, dynamic> item) async {
    try {
      _prepararItemFiscal(item);
      final body = <String, dynamic>{
        if (item['id'] != null) 'id': item['id'],
        'cstIcms': item['cst_icms'] ?? item['cstIcms'],
        'aliqIcms': _asDouble(item['aliq_icms'] ?? item['aliqIcms']),
        'cstPis': item['cst_pis'] ?? item['cstPis'],
        'pPis': _asDouble(item['p_pis'] ?? item['pPis']),
        'cstCofins': item['cst_cofins'] ?? item['cstCofins'],
        'pCofins': _asDouble(item['p_cofins'] ?? item['pCofins']),
        'cstIpi': item['cst_ipi'] ?? item['cstIpi'],
        'aliqIpi': _asDouble(item['aliq_ipi'] ?? item['aliqIpi']),
        'cstIbsCbs': item['cst_ibs_cbs'] ?? item['cstIbsCbs'],
        'pCbs': _asDouble(item['p_cbs'] ?? item['pCbs']),
        'pIbsUf': _asDouble(item['p_ibs_uf'] ?? item['pIbsUf']),
        'pIbsMun': _asDouble(item['p_ibs_mun'] ?? item['pIbsMun']),
        'vProd': _asDouble(item['v_prod'] ?? item['vProd']) ?? 0,
        'vBcIcms': _asDouble(item['v_bc_icms'] ?? item['vBcIcms']),
        'vBcPis': _asDouble(item['v_bc_pis'] ?? item['vBcPis']),
        'vBcCofins': _asDouble(item['v_bc_cofins'] ?? item['vBcCofins']),
        'vBcIpi': _asDouble(item['v_bc_ipi'] ?? item['vBcIpi']),
        'vBcIbsCbs': _asDouble(item['v_bc_ibs_cbs'] ?? item['vBcIbsCbs']),
        'qCom': _asDouble(item['q_com'] ?? item['qCom']) ?? 1,
        'vUnCom': _asDouble(item['v_un_com'] ?? item['vUnCom']) ?? 0,
        'produtoId': item['produto_id'] ?? item['produtoId'],
        'temIcms': item['tem_icms'] ?? item['temIcms'],
        'temIpi': item['tem_ipi'] ?? item['temIpi'],
        'temPis': item['tem_pis'] ?? item['temPis'],
        'temCofins': item['tem_cofins'] ?? item['temCofins'],
        'temIbsCbs': item['tem_ibs_cbs'] ?? item['temIbsCbs'],
      };

      final futures = [
        TenantContext.post(
            '${ApiLinks.baseUrl}/api/nfe_item/calcular-icms', body),
        TenantContext.post(
            '${ApiLinks.baseUrl}/api/nfe_item/calcular-pis-cofins', body),
        TenantContext.post(
            '${ApiLinks.baseUrl}/api/nfe_item/calcular-ipi', body),
        TenantContext.post(
            '${ApiLinks.baseUrl}/api/nfe_item/calcular-ibs-cbs', body),
      ];

      final results = await Future.wait(futures);
      if (!mounted) return;

      bool error = false;
      setState(() {
        for (final r in results) {
          if (r.statusCode == 200) {
            final calculated = jsonDecode(r.body);
            final data = calculated is Map
                ? (calculated['data'] ?? calculated)
                : calculated;

            final fields = [
              'vBcIcms',
              'vIcms',
              'vBcIcmsSt',
              'vIcmsSt',
              'vFcp',
              'vBcPis',
              'vPis',
              'vBcCofins',
              'vCofins',
              'vBcIpi',
              'vIpi',
              'vBcIbsCbs',
              'vIbs',
              'vCbs'
            ];

            for (final f in fields) {
              if (data[f] != null) {
                String snake = f.replaceAllMapped(
                    RegExp(r'[A-Z]'), (m) => '_' + m.group(0)!.toLowerCase());
                if (f == 'vBcIcms') snake = 'v_bc_icms';
                if (f == 'vBcIcmsSt') snake = 'v_bc_icms_st';
                if (f == 'vIcmsSt') snake = 'v_icms_st';
                if (f == 'vBcPis') snake = 'v_bc_pis';
                if (f == 'vBcCofins') snake = 'v_bc_cofins';
                if (f == 'vBcIpi') snake = 'v_bc_ipi';
                if (f == 'vBcIbsCbs') snake = 'v_bc_ibs_cbs';

                item[f] = data[f].toString();
                item[snake] = data[f].toString();
              }
            }
          } else {
            error = true;
          }
        }

        // Calcula total de tributos do item e atualiza totais da NF-e
        final vIcms = _asDouble(item['v_icms'] ?? item['vIcms']) ?? 0;
        final vPis = _asDouble(item['v_pis'] ?? item['vPis']) ?? 0;
        final vCofins = _asDouble(item['v_cofins'] ?? item['vCofins']) ?? 0;
        final vIpi = _asDouble(item['v_ipi'] ?? item['vIpi']) ?? 0;
        final vCbs = _asDouble(item['v_cbs'] ?? item['vCbs']) ?? 0;
        final vIbs = _asDouble(item['v_ibs'] ?? item['vIbs']) ?? 0;
        final totTrib = vIcms + vPis + vCofins + vIpi + vCbs + vIbs;
        item['v_tot_trib'] = _valorMonetario(totTrib);
        item['vTotTrib'] = item['v_tot_trib'];

        _atualizarTotaisNfe();
      });

      if (!error) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Impostos calculados!'),
            backgroundColor: Color(0xFF4CAF50)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Alguns impostos falharam no cálculo.'),
            backgroundColor: Color(0xFFF44336)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Erro ao processar. Tente novamente.'),
            backgroundColor: Color(0xFFF44336)));
      }
    }
  }

  Widget _iInp(String label, Map<String, dynamic> item, String k1, String k2) {
    return _ReactiveTextField(
      key: ValueKey('${_selItem}_$k1'),
      label: label,
      dataMap: item,
      key1: k1,
      key2: k2,
      onChanged: (v) {
        if (k1 == 'q_com' || k1 == 'v_un_com') {
          final quantidade = _asDouble(item['q_com'] ?? item['qCom']);
          final valorUnitario = _asDouble(item['v_un_com'] ?? item['vUnCom']);
          if (quantidade != null && valorUnitario != null) {
            item['v_prod'] = _valorMonetario(quantidade * valorUnitario);
            item['vProd'] = item['v_prod'];
          }
          _recalcularTotalItem(item);
          setState(() {
            _atualizarTotaisNfe();
          });
        }
      },
    );
  }

  // Dropdown de série para NF-e SAÍDA — ao selecionar, busca próximo número
  Widget _ddObjSerie(
      String label, String? serieId, List<Map<String, dynamic>> opts) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SearchableDropdownField(
        label: label,
        value: opts.any((o) => o['id']?.toString() == serieId) ? serieId : null,
        items: opts
            .map((o) => <String, dynamic>{
                  'id': o['id']?.toString() ?? '',
                  'nome':
                      '${o['serie'] ?? ''} (atual: ${o['numero_atual'] ?? o['numeroAtual'] ?? 1})',
                })
            .toList(),
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        nullLabel: '— Selecione —',
        onChanged: (v) async {
          if (v == null) return;
          final serie = opts.firstWhere((o) => o['id']?.toString() == v,
              orElse: () => {});
          final fallbackNum = serie['numero_atual']?.toString() ??
              serie['numeroAtual']?.toString() ??
              '';
          setState(() {
            _serieId = v;
            _serieCtrl.text = serie['serie']?.toString() ?? '';
            if (fallbackNum.isNotEmpty) {
              _numeroCtrl.text = fallbackNum;
            }
          });
          // Busca próximo número da série e preenche campo Número
          try {
            final r =
                await TenantContext.get('${ApiLinks.baseUrl}/api/nfe-serie/$v');
            if (r.statusCode == 200) {
              final b = jsonDecode(r.body);
              final num = b['data']?['numero_atual']?.toString() ??
                  b['data']?['numeroAtual']?.toString() ??
                  b['numero_atual']?.toString() ??
                  b['numeroAtual']?.toString() ??
                  '';
              if (num.isNotEmpty) setState(() => _numeroCtrl.text = num);
            }
          } catch (_) {}
        },
      ),
    );
  }

  Widget _ddObjItem(String label, String? val, List<Map<String, dynamic>> opts,
      String df, void Function(String?) cb) {
    final vStr = val?.trim();
    final match = opts.where((o) {
      final oid = o['id']?.toString().trim();
      final onome = o[df]?.toString().trim();
      return (oid != null &&
              oid.isNotEmpty &&
              oid.toUpperCase() == vStr?.toUpperCase()) ||
          (onome != null &&
              onome.isNotEmpty &&
              onome.toUpperCase() == vStr?.toUpperCase());
    }).firstOrNull;
    final selectedVal = match != null ? match['id']?.toString() : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SearchableDropdownField(
        label: label,
        value: selectedVal,
        items: opts
            .map((o) => <String, dynamic>{
                  'id': o['id']?.toString() ?? '',
                  'nome': o[df]?.toString() ?? '',
                })
            .toList(),
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        nullLabel: '— Selecione —',
        onChanged: cb,
      ),
    );
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    final normalized = text.contains(',')
        ? text.replaceAll('.', '').replaceAll(',', '.')
        : text;
    return double.tryParse(normalized);
  }

  String _valorDecimal(dynamic value) {
    if (value == null) return '';
    if (value is num) return value.toString();
    final text = value.toString().trim();
    return text.contains(',')
        ? text.replaceAll('.', '').replaceAll(',', '.')
        : text;
  }

  String _valorMonetario(double value) => value.toStringAsFixed(2);

  void _recalcularTotalItem(Map<String, dynamic> item) {
    NfeTaxAliases.recalcularItem(item);
  }

  void _prepararItemFiscal(Map<String, dynamic> item) {
    item['x_prod'] = (item['x_prod'] ?? item['xProd'] ?? '').toString();
    item['xProd'] = item['x_prod'];
    item['u_com'] = (item['u_com'] ?? item['uCom'] ?? '').toString();
    item['uCom'] = item['u_com'];
    _recalcularTotalItem(item);
  }

  Future<void> _aplicarImpostosNosItensCarregados() async {
    var alterou = false;
    for (final item in _itens) {
      final produtoId = _produtoIdDoItem(item);
      if (produtoId == null) continue;
      try {
        final r = await TenantContext.get(
            '${ApiLinks.baseUrl}/api/produto-imposto-uf?produtoId=$produtoId');
        if (r.statusCode != 200) continue;
        final list = jsonDecode(r.body);
        if (list is! List || list.isEmpty || list.first is! Map) continue;
        NfeTaxAliases.applyProdutoImpostoUf(
            item, Map<String, dynamic>.from(list.first as Map));
        _recalcularTotalItem(item);
        alterou = true;
      } catch (_) {}
    }
    if (alterou && mounted) {
      setState(_atualizarTotaisNfe);
    }
  }

  int? _produtoIdDoItem(Map<String, dynamic> item) {
    final direto = item['produto_id'] ?? item['produtoId'];
    if (direto != null) return int.tryParse(direto.toString());
    final produto = item['produto'];
    if (produto is Map && produto['id'] != null) {
      return int.tryParse(produto['id'].toString());
    }
    return null;
  }

  void _atualizarTotaisNfe() {
    double totalProd = 0.0;
    double bcIcms = 0.0;
    double vIcms = 0.0;
    double bcIcmsSt = 0.0;
    double vIcmsSt = 0.0;
    double vFcp = 0.0;
    double bcIpi = 0.0;
    double vIpi = 0.0;
    double bcPis = 0.0;
    double vPis = 0.0;
    double bcCofins = 0.0;
    double vCofins = 0.0;
    double bcIbsCbs = 0.0;
    double vIbs = 0.0;
    double vCbs = 0.0;
    double totTrib = 0.0;

    for (final it in _itens) {
      totalProd += _asDouble(it['v_prod'] ?? it['vProd']) ?? 0.0;
      bcIcms += _asDouble(it['v_bc_icms'] ?? it['vBcIcms']) ?? 0.0;
      vIcms += _asDouble(it['v_icms'] ?? it['vIcms']) ?? 0.0;
      bcIcmsSt += _asDouble(it['v_bc_icms_st'] ?? it['vBcIcmsSt']) ?? 0.0;
      vIcmsSt += _asDouble(it['v_icms_st'] ?? it['vIcmsSt']) ?? 0.0;
      vFcp += _asDouble(it['v_fcp'] ?? it['vFcp']) ?? 0.0;
      bcIpi += _asDouble(it['v_bc_ipi'] ?? it['vBcIpi']) ?? 0.0;
      vIpi += _asDouble(it['v_ipi'] ?? it['vIpi']) ?? 0.0;
      bcPis += _asDouble(it['v_bc_pis'] ?? it['vBcPis']) ?? 0.0;
      vPis += _asDouble(it['v_pis'] ?? it['vPis']) ?? 0.0;
      bcCofins += _asDouble(it['v_bc_cofins'] ?? it['vBcCofins']) ?? 0.0;
      vCofins += _asDouble(it['v_cofins'] ?? it['vCofins']) ?? 0.0;
      bcIbsCbs += _asDouble(it['v_bc_ibs_cbs'] ?? it['vBcIbsCbs']) ?? 0.0;
      vIbs += _asDouble(it['v_ibs'] ?? it['vIbs']) ?? 0.0;
      vCbs += _asDouble(it['v_cbs'] ?? it['vCbs']) ?? 0.0;
      totTrib += _asDouble(it['v_tot_trib'] ?? it['vTotTrib']) ?? 0.0;
    }

    final nfe = widget.item;
    nfe['valorTotal'] = totalProd.toStringAsFixed(2);
    nfe['valor_total'] = nfe['valorTotal'];
    nfe['vBcIcms'] = bcIcms.toStringAsFixed(2);
    nfe['v_bc_icms'] = nfe['vBcIcms'];
    nfe['vIcms'] = vIcms.toStringAsFixed(2);
    nfe['v_icms'] = nfe['vIcms'];
    nfe['vBcIcmsSt'] = bcIcmsSt.toStringAsFixed(2);
    nfe['v_bc_icms_st'] = nfe['vBcIcmsSt'];
    nfe['vIcmsSt'] = vIcmsSt.toStringAsFixed(2);
    nfe['v_icms_st'] = nfe['vIcmsSt'];
    nfe['vFcp'] = vFcp.toStringAsFixed(2);
    nfe['v_fcp'] = nfe['vFcp'];
    nfe['vBcIpi'] = bcIpi.toStringAsFixed(2);
    nfe['v_bc_ipi'] = nfe['vBcIpi'];
    nfe['vIpi'] = vIpi.toStringAsFixed(2);
    nfe['v_ipi'] = nfe['vIpi'];
    nfe['vBcPis'] = bcPis.toStringAsFixed(2);
    nfe['v_bc_pis'] = nfe['vBcPis'];
    nfe['vPis'] = vPis.toStringAsFixed(2);
    nfe['v_pis'] = nfe['vPis'];
    nfe['vBcCofins'] = bcCofins.toStringAsFixed(2);
    nfe['v_bc_cofins'] = nfe['vBcCofins'];
    nfe['vCofins'] = vCofins.toStringAsFixed(2);
    nfe['v_cofins'] = nfe['vCofins'];
    nfe['vBcIbsCbs'] = bcIbsCbs.toStringAsFixed(2);
    nfe['v_bc_ibs_cbs'] = nfe['vBcIbsCbs'];
    nfe['vIbs'] = vIbs.toStringAsFixed(2);
    nfe['v_ibs'] = nfe['vIbs'];
    nfe['vCbs'] = vCbs.toStringAsFixed(2);
    nfe['v_cbs'] = nfe['vCbs'];
    nfe['vTotTrib'] = totTrib.toStringAsFixed(2);
    nfe['v_tot_trib'] = nfe['vTotTrib'];
  }

  void _novoItem() => setState(() {
        final novoItem = <String, dynamic>{
          'nfe_id': int.tryParse(_nfeId) ?? 0,
          'q_com': '1.00',
          'qCom': '1.00',
          'v_un_com': '0.00',
          'vUnCom': '0.00',
          'v_prod': '0.00',
          'vProd': '0.00',
        };
        if (_topSelected.isNotEmpty) {
          novoItem['cfop'] = _topSelected['cfop']?.toString() ?? '';
          novoItem['cst_icms'] = _topSelected['cstIcms']?.toString() ?? '';
          novoItem['aliq_icms'] = _topSelected['aliqIcms']?.toString() ?? '';
        }
        _itens.add(novoItem);
        _selItem = _itens.length - 1;
        _itensGrid = false;
      });

  /// Abre a tela de cadastro de Produto a partir do lookup vazio.
  /// Preserva o contexto da NF-e: ao retornar, recarrega a lista de produtos
  /// para que o item recém-cadastrado fique disponível no dropdown.
  Future<void> _abrirCadastroProduto() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebProdutoGridScreen(hasPermission: (p) => true),
      ),
    );
    if (!mounted) return;
    await _recarregarProdutos();
  }

  /// Recarrega apenas a lista de produtos contábeis (mesma query do _loadDropdowns).
  Future<void> _recarregarProdutos() async {
    final login = AuthUtility.userInfo?.login;
    final parcId = login?.parceiro?.id?.toString() ?? _parceiroId;
    final empId = login?.empresa?.id?.toString() ?? _empresaId;
    await _loadList(
      '${ApiLinks.baseUrl}/api/produto-contabil?tamanho=500${empId != null ? '&empId=$empId' : ''}${parcId != null ? '&parceiroId=$parcId' : ''}&isServico=false',
      (d) => setState(() => _produtos = d),
    );
  }

  /// Grid sem AppBar — usa MediaQuery para dar padding zero ao topo
  /// evitando o header duplo dentro do detail
  Widget _gridSemHeader(
      {required String telaNome, Map<String, dynamic>? extraParams}) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      key: ValueKey('${telaNome}_$_nfeId'),
      telaNome: telaNome,
      hasPermission: (p) => p == 'create' ? false : true,
      fromJson: (json) => json,
      toJson: (a) => a,
      extraParams: extraParams,
      showAppBar: false,
    );
  }

  // Unidades padrão quando o endpoint não existe
  List<Map<String, dynamic>> _unidadesFallback() => [
        {'id': 'UN', 'nome': 'UN', 'descricao': 'Unidade'},
        {'id': 'KG', 'nome': 'KG', 'descricao': 'Quilograma'},
        {'id': 'G', 'nome': 'G', 'descricao': 'Grama'},
        {'id': 'L', 'nome': 'L', 'descricao': 'Litro'},
        {'id': 'ML', 'nome': 'ML', 'descricao': 'Mililitro'},
        {'id': 'M', 'nome': 'M', 'descricao': 'Metro'},
        {'id': 'M2', 'nome': 'M2', 'descricao': 'Metro Quadrado'},
        {'id': 'M3', 'nome': 'M3', 'descricao': 'Metro Cúbico'},
        {'id': 'CX', 'nome': 'CX', 'descricao': 'Caixa'},
        {'id': 'PC', 'nome': 'PC', 'descricao': 'Peça'},
        {'id': 'PAR', 'nome': 'PAR', 'descricao': 'Par'},
        {'id': 'DZ', 'nome': 'DZ', 'descricao': 'Dúzia'},
        {'id': 'SC', 'nome': 'SC', 'descricao': 'Saco'},
        {'id': 'T', 'nome': 'T', 'descricao': 'Tonelada'},
      ];

  Widget _togBtn(IconData ic, bool on, VoidCallback cb) => InkWell(
      onTap: cb,
      child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: on ? _green : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: on ? _green : _bord)),
          child: Icon(ic, size: 16, color: on ? Colors.white : _grey)));

  Widget _nb(IconData ic, VoidCallback cb) => InkWell(
      onTap: cb,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Icon(ic, size: 18, color: _dark)));

  // ── RODAPÉ ──
  Widget _rodape() {
    final tabs = ['Totais', 'Impostos', 'Financeiro', 'Pagamentos'];
    return Column(children: [
      Container(
          color: const Color(0xFFF0F0F0),
          child: Row(children: [
            const SizedBox(width: 8),
            ...tabs.asMap().entries.map((e) => _tabBtn(e.key, e.value)),
          ])),
      Container(height: 1, color: _bord),
      Expanded(child: _tabContent()),
    ]);
  }

  Widget _tabBtn(int idx, String label) {
    final on = _tab == idx;
    return GestureDetector(
        onTap: () => setState(() => _tab = idx),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: on ? Colors.white : Colors.transparent,
                border: Border(
                    bottom: BorderSide(
                        color: on ? _red : Colors.transparent, width: 2))),
            child: Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: on ? FontWeight.bold : FontWeight.normal,
                    color: on ? _red : _grey))));
  }

  Widget _tabContent() {
    switch (_tab) {
      case 0:
        return _totaisTab();
      case 1:
        return _impostosTab();
      case 2:
        return _financeiroTab();
      case 3:
        return _pagamentosTab();
      default:
        return const SizedBox();
    }
  }

  Widget _totaisTab() {
    final vt = widget.item['valorTotal']?.toString() ?? '0,00';
    return Padding(
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          _card('Vlr. Nota', vt),
          _card('Total Produtos', vt),
          _card('Total Serviços', '0,00'),
        ]));
  }

  Widget _impostosTab() {
    final i = widget.item;
    String f(String k1, String k2) {
      final val = _asDouble(i[k1] ?? i[k2]);
      return val != null ? val.toStringAsFixed(2) : '0.00';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _card('BC ICMS', f('vBcIcms', 'v_bc_icms')),
          _card('Vl. ICMS', f('vIcms', 'v_icms')),
          _card('BC ICMS ST', f('vBcIcmsSt', 'v_bc_icms_st')),
          _card('Vl. ICMS ST', f('vIcmsSt', 'v_icms_st')),
          _card('Vl. FCP', f('vFcp', 'v_fcp')),
          _card('BC IPI', f('vBcIpi', 'v_bc_ipi')),
          _card('Vl. IPI', f('vIpi', 'v_ipi')),
          _card('BC PIS', f('vBcPis', 'v_bc_pis')),
          _card('Vl. PIS', f('vPis', 'v_pis')),
          _card('BC COFINS', f('vBcCofins', 'v_bc_cofins')),
          _card('Vl. COFINS', f('vCofins', 'v_cofins')),
          _card('Vl. ISS', f('vIss', 'v_iss')),
          _card('Vl. II', f('vIi', 'v_ii')),
          _card('BC IBS/CBS', f('vBcIbsCbs', 'v_bc_ibs_cbs')),
          _card('Vl. IBS', f('vIbs', 'v_ibs')),
          _card('Vl. CBS', f('vCbs', 'v_cbs')),
          _card('Tot. Tributos', f('vTotTrib', 'v_tot_trib')),
        ],
      ),
    );
  }

  // Financeiro com DynamicGridWindowsScreen no modo grid + form customizado
  Widget _financeiroTab() {
    final label = _isEntrada ? 'Contas a Pagar' : 'Contas a Receber';
    final telaNome = _isEntrada ? 'conta_pagar' : 'conta_receber';
    return Column(children: [
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: const Color(0xFFF8F8F8),
          child: Row(children: [
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: 8),
            _togBtn(Icons.view_list, _finGrid,
                () => setState(() => _finGrid = true)),
            const SizedBox(width: 4),
            _togBtn(Icons.edit_note, !_finGrid,
                () => setState(() => _finGrid = false)),
            const SizedBox(width: 8),
            SizedBox(
                height: 24,
                child: ElevatedButton.icon(
                    onPressed: _novaConta,
                    icon: const Icon(Icons.add, size: 12),
                    label: const Text('Nova', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10)))),
            const Spacer(),
            if (!_finGrid && _contas.isNotEmpty) ...[
              _nb(Icons.first_page, () => setState(() => _selFin = 0)),
              _nb(
                  Icons.chevron_left,
                  () => setState(() {
                        if (_selFin > 0) _selFin--;
                      })),
              Text(' ${_selFin + 1}/${_contas.length} ',
                  style: const TextStyle(fontSize: 11)),
              _nb(
                  Icons.chevron_right,
                  () => setState(() {
                        if (_selFin < _contas.length - 1) _selFin++;
                      })),
              _nb(Icons.last_page,
                  () => setState(() => _selFin = _contas.length - 1)),
            ],
          ])),
      Container(height: 1, color: _bord),
      // Grid: DynamicGridWindowsScreen sem botão Novo
      // Form: form customizado com scroll
      Expanded(
          child: _finGrid
              ? _gridSemHeader(
                  telaNome: telaNome,
                  extraParams: {'nfeId': _nfeId},
                )
              : (_contas.isEmpty
                  ? const Center(
                      child: Text('Nenhuma conta vinculada',
                          style: TextStyle(color: _grey)))
                  : _fForm())),
    ]);
  }

  Widget _fForm() {
    if (_selFin >= _contas.length) return const SizedBox();
    final conta = _contas[_selFin];
    // Scroll para ver todos os campos
    return SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          _fInp('Descrição', conta, 'descricao'),
          _fInp('Valor', conta, 'valor'),
          _fInp('Dt. Vencimento', conta, 'data_vencimento'),
          _fInp('Status', conta, 'status'),
          _fInp('Observação', conta, 'observacao'),
          _fInp('Valor Baixa', conta, 'valor_baixa'),
          _fInp('Dt. Baixa', conta, 'data_baixa'),
        ]));
  }

  Widget _fInp(String label, Map<String, dynamic> conta, String key) {
    final ctrl = TextEditingController(text: conta[key]?.toString() ?? '');
    ctrl.addListener(() {
      conta[key] = ctrl.text;
    });
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextFormField(
            controller: ctrl,
            style: const TextStyle(fontSize: 12, color: _dark),
            decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(fontSize: 11, color: _grey),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: _bord)),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8))));
  }

  void _novaConta() => setState(() {
        _contas.add({'nfe_id': int.tryParse(_nfeId) ?? 0});
        _selFin = _contas.length - 1;
        _finGrid = false;
      });

  Widget _card(String label, String valor) => Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 9, color: _grey)),
        Text(valor,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ]));

  // ── TAREFA NF07: Aba de Pagamentos ────────────────────────────────────────
  Widget _pagamentosTab() {
    if (_isNovo) {
      return const Center(
          child: Text('Salve a NF-e antes de gerenciar pagamentos.',
              style: TextStyle(color: _grey, fontSize: 12)));
    }
    if (_pagamentosLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final valorTotal = (widget.item['valorTotal'] as num?)?.toDouble() ?? 0;
    final totalPago = _pagamentos.fold<double>(0, (s, p) => s + p.vPag);
    final diferenca = totalPago - valorTotal;
    final okPago = diferenca.abs() <= 0.01;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Seção 1: Formas de Pagamento ──────────────────────────────────
        _secTitle('Formas de Pagamento'),
        const SizedBox(height: 6),
        ..._pagamentos.map((pag) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _bord),
                  borderRadius: BorderRadius.circular(4)),
              child: Row(children: [
                Expanded(
                    child: Text(NfePagamento.labelTipo(pag.tPag),
                        style: const TextStyle(fontSize: 12))),
                const SizedBox(width: 8),
                Text('R\$ ${pag.vPag.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                IconButton(
                    icon:
                        const Icon(Icons.delete_outline, size: 16, color: _red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _removerPagamento(pag)),
              ]),
            )),

        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              border: Border.all(color: _bord),
              borderRadius: BorderRadius.circular(4)),
          child: Row(children: [
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<String>(
                value: _novoPagTpag,
                isDense: true,
                decoration: const InputDecoration(
                    labelText: 'Tipo',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder()),
                style: const TextStyle(fontSize: 12, color: _dark),
                items: NfePagamento.todosCodigos
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text('$c - ${NfePagamento.labelTipo(c)}',
                            style: const TextStyle(fontSize: 11))))
                    .toList(),
                onChanged: (v) => setState(() => _novoPagTpag = v ?? '01'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
                child: TextFormField(
              controller: _novoPagVpag,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  border: OutlineInputBorder()),
            )),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _adicionarPagamento,
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Adicionar', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            ),
          ]),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              color: okPago ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: okPago ? _green : _red)),
          child: Row(children: [
            const Icon(Icons.info_outline, size: 14),
            const SizedBox(width: 6),
            Text(
                'Total pago: R\$ ${totalPago.toStringAsFixed(2)}  |  Total NF-e: R\$ ${valorTotal.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 11,
                    color: okPago ? _green : _red,
                    fontWeight: FontWeight.bold)),
            if (!okPago) ...[
              const SizedBox(width: 6),
              Text('(dif: R\$ ${diferenca.toStringAsFixed(2)})',
                  style: const TextStyle(fontSize: 10, color: _red)),
            ],
          ]),
        ),

        const SizedBox(height: 16),
        const Divider(),

        // ── Seção 2: Fatura ───────────────────────────────────────────────
        _secTitle('Fatura'),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
              child: TextFormField(
                  controller: _fatNFat,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                      labelText: 'Número da Fatura',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder()))),
          const SizedBox(width: 8),
          Expanded(
              child: TextFormField(
                  controller: _fatVOrig,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                      labelText: 'Valor Original',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder()))),
          const SizedBox(width: 8),
          Expanded(
              child: TextFormField(
                  controller: _fatVLiq,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                      labelText: 'Valor Líquido',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder()))),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _salvarFatura,
            style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            child: const Text('Salvar Fatura', style: TextStyle(fontSize: 11)),
          ),
        ]),

        const SizedBox(height: 16),
        const Divider(),

        // ── Seção 3: Duplicatas ───────────────────────────────────────────
        _secTitle('Duplicatas'),
        const SizedBox(height: 6),
        ..._duplicatas.map((dup) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _bord),
                  borderRadius: BorderRadius.circular(4)),
              child: Row(children: [
                Expanded(
                    child: Text(dup.nDup ?? '-',
                        style: const TextStyle(fontSize: 12))),
                const SizedBox(width: 8),
                Text(dup.dVenc ?? '-',
                    style: const TextStyle(fontSize: 11, color: _grey)),
                const SizedBox(width: 8),
                Text('R\$ ${(dup.vDup ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                IconButton(
                    icon:
                        const Icon(Icons.delete_outline, size: 16, color: _red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _removerDuplicata(dup)),
              ]),
            )),

        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              border: Border.all(color: _bord),
              borderRadius: BorderRadius.circular(4)),
          child: Row(children: [
            Expanded(
                child: TextFormField(
                    controller: _dupNDup,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                        labelText: 'Nº Dup.',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            Expanded(
                child: TextFormField(
                    controller: _dupDVenc,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                        labelText: 'Dt. Venc. (AAAA-MM-DD)',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            Expanded(
                child: TextFormField(
                    controller: _dupVDup,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                        labelText: 'Valor',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _adicionarDuplicata,
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Adicionar', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            ),
          ]),
        ),

        const SizedBox(height: 16),
        const Divider(),

        // ── Botão: Gerar Contas a Pagar ───────────────────────────────────
        SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.receipt_long),
              label: const Text('Gerar Contas a Pagar',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              onPressed: _duplicatas.isEmpty ? null : _gerarContasPagar,
            )),
        if (_duplicatas.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Adicione duplicatas antes de gerar as contas.',
                style: TextStyle(fontSize: 11, color: _grey)),
          ),
      ]),
    );
  }

  Widget _secTitle(String title) => Text(title,
      style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.bold, color: _dark));
}

class _ReactiveTextField extends StatefulWidget {
  final String label;
  final Map<String, dynamic> dataMap;
  final String key1;
  final String? key2;
  final Function(String)? onChanged;
  final bool readOnly;

  const _ReactiveTextField({
    super.key,
    required this.label,
    required this.dataMap,
    required this.key1,
    this.key2,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  State<_ReactiveTextField> createState() => _ReactiveTextFieldState();
}

class _ReactiveTextFieldState extends State<_ReactiveTextField> {
  late TextEditingController _ctrl;

  String _getVal() =>
      widget.dataMap[widget.key1]?.toString() ??
      (widget.key2 != null ? widget.dataMap[widget.key2!]?.toString() : null) ??
      '';

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _getVal());
  }

  @override
  void didUpdateWidget(covariant _ReactiveTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newVal = _getVal();
    if (_ctrl.text != newVal) {
      _ctrl.text = newVal;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: _ctrl,
        readOnly: widget.readOnly,
        onChanged: (v) {
          widget.dataMap[widget.key1] = v;
          if (widget.key2 != null) widget.dataMap[widget.key2!] = v;
          if (widget.onChanged != null) widget.onChanged!(v);
        },
        style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: const TextStyle(fontSize: 11, color: Colors.grey),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
    );
  }
}
