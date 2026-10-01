import 'dart:convert';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/auth_utility.dart';
import '../../../models/empresa_acesso_model.dart';
import '../../../models/parceiro_model.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../../utils/nfse_tax_calculator.dart';
import '../../../utils/app_logger.dart';
import '../../../widgets/searchable_dropdown.dart';

const _red = GridColors.primary;
const _green = GridColors.secondary;
const _bord = Color(0xFFDDDDDD);
const _grey = Color(0xFF757575);
const _dark = Color(0xFF212121);
const _bg = Color(0xFFF5F5F5);

const _codigoServicoMunicipalNfseKeys = [
  'codigoServicoMunicipal',
  'codigo_servico_municipal',
  'codigoServico',
  'codigo_servico',
  'ibge',
];

String? resolveCodigoServicoMunicipalNfse(Map<String, dynamic>? cidade) {
  if (cidade == null) return null;
  for (final chave in _codigoServicoMunicipalNfseKeys) {
    final texto = cidade[chave]?.toString().trim();
    if (texto != null && texto.isNotEmpty) return texto;
  }
  return null;
}

/// Tela de inserção/detalhe de NFSe — espelha o layout do NfeSankhyaDetailScreen:
/// cabeçalho fiscal à esquerda + grid de itens (produtos de serviço) à direita
/// com aba de Impostos (ISS).
class NfseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const NfseDetailScreen({super.key, required this.item});
  @override
  State<NfseDetailScreen> createState() => _NfseDetailScreenState();
}

class _NfseDetailScreenState extends State<NfseDetailScreen> {
  late final Map<String, dynamic> _item;
  int _tab = 0;
  bool _itensGrid = true;
  int _selItem = 0;
  bool _enviando = false;

  List<Map<String, dynamic>> _itens = [];

  // Dropdowns
  final List<Map<String, dynamic>> _empresas = [];
  List<Map<String, dynamic>> _tomadores = []; // parceiros
  List<Map<String, dynamic>> _produtos = []; // somente isServico == true
  List<Map<String, dynamic>> _series = []; // nfse_serie
  List<Map<String, dynamic>> _cidades = []; // todas as cidades

  // Controllers cabeçalho
  final _numeroCtrl = TextEditingController();
  final _serieCtrl = TextEditingController();
  final _municipioCtrl = TextEditingController();
  final _codigoServicoCtrl = TextEditingController();
  final _observacaoCtrl = TextEditingController();
  String? _statusVal;
  String? _ambienteVal;
  String? _empresaId;
  String? _parceiroEmissorId;
  String? _parceiroEmissorNome;
  String? _tomadorId;
  String? _serieId;
  String? _cidadeId;
  DateTime? _dataEmissao;
  DateTime? _dataCompetencia;

  String? _empresaNome;
  String? _tomadorNome;

  bool get _isNovo => _item['id'] == null;
  String get _nfseId => _item['id']?.toString() ?? '';
  String get _statusAtual => (_statusVal ?? 'RASCUNHO').toUpperCase();
  bool get _podeExcluir =>
      !_isNovo &&
      const {'RASCUNHO', 'CONFIRMADA', 'PENDENTE'}.contains(_statusAtual);
  bool get _podeCancelar => _statusAtual == 'AUTORIZADA';
  dynamic get _login =>
      AuthUtility.userInfo?.login ?? AuthUtility.userInfo?.data?.login;

  @override
  void initState() {
    super.initState();
    _item = Map<String, dynamic>.from(widget.item);
    _initCabecalho();
    _loadDropdowns();
    if (!_isNovo) {
      _loadItens();
    }
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _serieCtrl.dispose();
    _municipioCtrl.dispose();
    _codigoServicoCtrl.dispose();
    _observacaoCtrl.dispose();
    super.dispose();
  }

  void _initCabecalho() {
    final i = _item;
    final login = _login;

    final status = _isNovo ? 'RASCUNHO' : (i['status']?.toString() ?? 'RASCUNHO');
    _statusVal = status;
    _numeroCtrl.text = status == 'AUTORIZADA' ? (i['numero']?.toString() ?? '') : '';
    _serieCtrl.text = i['serie']?.toString() ?? '';
    _municipioCtrl.text =
        i['municipioPrestacao']?.toString() ?? i['municipio']?.toString() ?? '';
    _codigoServicoCtrl.text = _codigoServicoMunicipalInicial(i);
    _observacaoCtrl.text = i['observacao']?.toString() ?? '';

    final sessEmpId = login?.empresa?.id?.toString();
    _empresaId = sessEmpId ??
        (i['empresa'] is Map ? i['empresa']['id'] : i['empresa'])?.toString();
    _empresaNome = login?.empresa?.nome ??
        (i['empresa'] is Map ? i['empresa']['nome'] : null)?.toString();
    _parceiroEmissorId = login?.parceiro?.id?.toString();
    _parceiroEmissorNome = login?.parceiro?.nome ??
        login?.parceiro?.razaoSocial ??
        (_parceiroEmissorId == null ? null : 'Parceiro $_parceiroEmissorId');
    final cidadeParceiro =
        login?.parceiro?.cidade ?? login?.parceiro?.endereco?.cidade?.nome;
    if (_isNovo && _municipioCtrl.text.isEmpty && cidadeParceiro != null) {
      _municipioCtrl.text = cidadeParceiro;
    }
    _ambienteVal = i['ambiente']?.toString() ??
        (TenantContext.hasParceiro
            ? _normalizarAmbienteTomador(login?.parceiro?.ambiente)
            : null);

    final tomadorRealId = (i['tomador'] is Map
            ? i['tomador']['id']
            : (i['parceiro'] is Map
                ? i['parceiro']['id']
                : i['tomador'] ?? i['parceiro']))
        ?.toString();
    final tomadorRealNome = (i['tomador'] is Map
            ? i['tomador']['nome']
            : (i['parceiro'] is Map ? i['parceiro']['nome'] : null))
        ?.toString();
    _tomadorId = tomadorRealId;
    _tomadorNome = tomadorRealNome;

    // Série: tentar extrair id da série (se vier como objeto) ou usar o valor textual
    if (i['serie'] is Map) {
      _serieId = i['serie']['id']?.toString();
      _serieCtrl.text = i['serie']['serie']?.toString() ?? '';
    } else {
      _serieCtrl.text = i['serie']?.toString() ?? '';
    }

    // Cidade: tentar extrair id (se vier como objeto) ou buscar pelo nome
    if (i['cidade'] is Map) {
      final cidade = Map<String, dynamic>.from(i['cidade'] as Map);
      _cidadeId = cidade['id']?.toString();
      final nomeCidade = cidade['nome']?.toString();
      if (nomeCidade != null && nomeCidade.isNotEmpty) {
        _municipioCtrl.text = nomeCidade;
      }
      final codigoMunicipal = resolveCodigoServicoMunicipalNfse(cidade);
      if (_codigoServicoCtrl.text.isEmpty && codigoMunicipal != null) {
        _codigoServicoCtrl.text = codigoMunicipal;
      }
    }
    if (i['municipioPrestacao'] != null) {
      _municipioCtrl.text = i['municipioPrestacao']?.toString() ?? '';
    }

    _dataEmissao = _parseData(i['dataEmissao'] ?? i['dhEmissao']) ??
        (_isNovo ? DateTime.now() : null);
    _dataCompetencia =
        _parseData(i['dataCompetencia']) ?? (_isNovo ? DateTime.now() : null);
  }

  DateTime? _parseData(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  String _codigoServicoMunicipalInicial(Map<String, dynamic> item) {
    final codigoDireto = resolveCodigoServicoMunicipalNfse(item);
    if (codigoDireto != null) return codigoDireto;

    final cidade = item['cidade'];
    if (cidade is Map) {
      return _codigoServicoMunicipalDaCidade(Map<String, dynamic>.from(cidade));
    }
    return '';
  }

  String _codigoServicoMunicipalDaCidade(Map<String, dynamic> cidade) {
    return resolveCodigoServicoMunicipalNfse(cidade) ?? '';
  }

  Map<String, dynamic> _cidadeDropdownItem(Map<String, dynamic> cidade) {
    final item = <String, dynamic>{
      'id': cidade['id']?.toString() ?? '',
      'nome': cidade['nome']?.toString() ?? '',
    };
    final codigo = _codigoServicoMunicipalDaCidade(cidade);
    if (codigo.isNotEmpty) item['codigoServicoMunicipal'] = codigo;
    return item;
  }

  String? _textoCidadeTomador(Map<String, dynamic> tomador) {
    final endereco = tomador['endereco'];
    final cidadeEndereco = endereco is Map ? endereco['cidade'] : null;
    final cidade = tomador['cidade'] ?? cidadeEndereco;
    final valor = cidade is Map ? cidade['nome'] : cidade;
    final texto = valor?.toString().trim();
    return texto == null || texto.isEmpty ? null : texto;
  }

  String? _idCidadeTomador(Map<String, dynamic> tomador) {
    final endereco = tomador['endereco'];
    final cidadeEndereco = endereco is Map ? endereco['cidade'] : null;
    final cidade = tomador['cidade'] ?? cidadeEndereco;
    final id = cidade is Map ? cidade['id'] : null;
    final texto = id?.toString().trim();
    return texto == null || texto.isEmpty ? null : texto;
  }

  String? _normalizarAmbienteTomador(dynamic value) {
    final texto = value?.toString().trim();
    if (texto == null || texto.isEmpty) return null;
    final normalizado = texto.toUpperCase();
    if (normalizado.contains('PRODU') || normalizado == '1') {
      return 'PRODUCAO';
    }
    if (normalizado.contains('HOMOLOG') || normalizado == '2') {
      return 'HOMOLOGACAO';
    }
    return null;
  }

  Future<void> _loadDropdowns() async {
    await _sincronizarContextoFiscalAtivo();
    final login = _login;
    final empId = login?.empresa?.id?.toString() ?? _empresaId;

    await Future.wait([
      _loadList(
          '${ApiLinks.baseUrl}/api/parceiro?tamanho=500${empId != null ? '&empId=$empId' : ''}',
          (d) => setState(() => _tomadores = d)),
      _loadProdutosServico(empId, _parceiroEmissorId),
      // Bug real (2026-09-17, ver bugs.md): esta tela buscava serie em
      // /api/nfse-serie (tabela nfse_serie, legada/nao usada -- so tem
      // registros "teste"), enquanto a tela onde o usuario de fato cadastra
      // serie de NFS-e ("NF-e Serie") grava em /api/nfe-serie (tabela
      // nfe_serie, com campo "tipo" distinguindo NF-e de NFS-e). A serie
      // cadastrada nunca aparecia aqui porque vinha da tabela errada.
      _loadList(
          '${ApiLinks.baseUrl}/api/nfe-serie?tamanho=100${empId != null ? '&empId=$empId' : ''}',
          (d) => setState(() => _series = d.where((s) {
                final tipo = s['tipo']?.toString().trim();
                final normalizado = tipo?.replaceAll('_', '-').toUpperCase();
                return normalizado == 'NFS-E' || normalizado == 'NFSE';
              }).toList())),
      // Carrega apenas um lote inicial (primeiras cidades em ordem alfabética)
      // para exibição rápida do dropdown. A base tem 5571 cidades (seed IBGE) —
      // carregar tudo e filtrar no cliente truncava a lista e a busca por
      // cidades fora desse corte (ex: "Uberaba") nunca encontrava resultado.
      // A busca de fato acontece no servidor via _buscarCidadesServidor.
      _loadList('${ApiLinks.baseUrl}/api/cidade?tamanho=100',
          (d) => setState(() => _cidades = d)),
    ]);
    await _carregarDadosParceiroEmissor();
    _garantirCidadeSelecionadaNaLista();
  }

  Future<void> _sincronizarContextoFiscalAtivo() async {
    final loginLocal = _login;
    final loginId = loginLocal?.id;
    if (!_isNovo || loginId == null) return;
    try {
      final response = await TenantContext.get(
        ApiLinks.loginEmpresasAcesso,
      );
      if (response.statusCode != 200) {
        AppLogger.i.warn(
          'Nao foi possivel sincronizar o contexto fiscal do login $loginId '
          '(HTTP ${response.statusCode}).',
        );
        return;
      }
      final raw = jsonDecode(response.body);
      final lista = raw is List
          ? raw
          : raw is Map && raw['data'] is List
              ? raw['data'] as List
              : raw is Map && raw['data'] is Map
                  ? (raw['data'] as Map)['dados'] as List?
                  : null;
      if (lista == null) return;
      Map<String, dynamic>? ativa;
      for (final item in lista.whereType<Map>()) {
        final candidato = Map<String, dynamic>.from(item);
        if (candidato['ativa'] == true) {
          ativa = candidato;
          break;
        }
      }
      if (ativa == null) return;
      final acesso = EmpresaAcesso.fromJson(ativa);
      if (acesso.empresaId <= 0) return;
      final empresaServidor = acesso.toEmpresa();
      final parceiroServidor = acesso.parceiroId == null
          ? null
          : Parceiro(
              id: acesso.parceiroId,
              nome: acesso.parceiroNome,
              empresa: empresaServidor,
            );

      final contextoMudou = loginLocal?.empresa?.id != empresaServidor.id ||
          loginLocal?.parceiro?.id != parceiroServidor?.id;
      if (!contextoMudou) return;

      await AuthUtility.atualizarContextoAtivo(
        empresaServidor,
        parceiroServidor,
      );
      if (!mounted) return;
      setState(_initCabecalho);
    } catch (e, stack) {
      AppLogger.i.error(
        'Erro ao sincronizar empresa/parceiro do login $loginId na NFS-e: $e',
        stack,
      );
    }
  }

  Future<void> _carregarDadosParceiroEmissor() async {
    final id = _parceiroEmissorId;
    if (!_isNovo || id == null || id.isEmpty) return;
    final data = <String, dynamic>{};
    void mesclar(Map<String, dynamic> origem) {
      for (final entry in origem.entries) {
        if (entry.value != null && entry.value.toString().trim().isNotEmpty) {
          data[entry.key] = entry.value;
        }
      }
    }

    final sessao = _login?.parceiro;
    if (sessao != null) mesclar(sessao.toJson());
    for (final parceiro in _tomadores) {
      if (parceiro['id']?.toString() == id) {
        mesclar(parceiro);
        break;
      }
    }
    try {
      final response =
          await TenantContext.get('${ApiLinks.baseUrl}/api/parceiro/$id');
      if (response.statusCode == 200) {
        final raw = jsonDecode(response.body);
        final payload = raw is Map && raw['data'] is Map
            ? Map<String, dynamic>.from(raw['data'] as Map)
            : raw is Map
                ? Map<String, dynamic>.from(raw)
                : <String, dynamic>{};
        mesclar(payload);
      } else {
        AppLogger.i.warn(
            'Usando sessao para parceiro emissor $id (HTTP ${response.statusCode}).');
      }
    } catch (e, stack) {
      AppLogger.i.error('Erro ao consultar parceiro emissor $id: $e', stack);
    }
    if (data.isEmpty || !mounted) return;
    final endereco = data['endereco'] is Map
        ? Map<String, dynamic>.from(data['endereco'] as Map)
        : <String, dynamic>{};
    final cidadeValue = endereco['cidade'] ?? data['cidade'];
    final cidade = cidadeValue is Map
        ? Map<String, dynamic>.from(cidadeValue as Map)
        : <String, dynamic>{};
    final municipio = (cidade['nome'] ?? cidadeValue)?.toString().trim();
    final ambiente = _normalizarAmbienteTomador(data['ambiente']);
    Map<String, dynamic>? encontrada;
    if ((cidade['id'] == null || cidade['id'].toString().isEmpty) &&
        municipio != null &&
        municipio.isNotEmpty) {
      final resultados = await _buscarCidadesServidor(municipio);
      for (final resultado in resultados) {
        if (resultado['nome']?.toString().trim().toUpperCase() ==
            municipio.toUpperCase()) {
          encontrada = resultado;
          break;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _parceiroEmissorNome =
          (data['nome'] ?? data['razaoSocial'])?.toString() ??
              _parceiroEmissorNome;
      if (_municipioCtrl.text.trim().isEmpty && municipio != null)
        _municipioCtrl.text = municipio;
      _cidadeId ??= cidade['id']?.toString() ?? encontrada?['id']?.toString();
      if (encontrada != null &&
          !_cidades.any((item) => item['id']?.toString() == _cidadeId)) {
        _cidades = [_cidadeDropdownItem(encontrada), ..._cidades];
      }
      if (_codigoServicoCtrl.text.trim().isEmpty) {
        _codigoServicoCtrl.text = _codigoServicoMunicipalDaCidade(
            cidade.isNotEmpty ? cidade : (encontrada ?? {}));
      }
      if ((_ambienteVal == null || _ambienteVal!.isEmpty) && ambiente != null)
        _ambienteVal = ambiente;
    });
  }

  /// Garante que a cidade já selecionada (ex: ao editar uma NFSe existente)
  /// apareça no dropdown mesmo que não esteja no lote inicial de 100 cidades
  /// — usa o nome já salvo no registro (_municipioCtrl) como rótulo.
  void _garantirCidadeSelecionadaNaLista() {
    if (_cidadeId == null || _cidadeId!.isEmpty) return;
    final jaPresente = _cidades.any((c) => c['id']?.toString() == _cidadeId);
    if (jaPresente) return;
    final nome = _municipioCtrl.text;
    if (nome.isEmpty) return;
    setState(() => _cidades = [
          {'id': _cidadeId, 'nome': nome},
          ..._cidades,
        ]);
  }

  /// Busca cidades no servidor pelo termo digitado (debounce feito pelo
  /// SearchableDropdownField). Usada pelo popup "Município de Prestação"
  /// para não depender de carregar as 5571 cidades no cliente.
  Future<List<Map<String, dynamic>>> _buscarCidadesServidor(
      String termo) async {
    List<Map<String, dynamic>> resultado = [];
    await _loadList(
      '${ApiLinks.baseUrl}/api/cidade?nome=${Uri.encodeQueryComponent(termo)}&tamanho=50',
      (d) => resultado = d,
    );
    return resultado;
  }

  /// Busca produtos de serviço via /api/produto_contabil (retorna entity completa com isServico)
  Future<void> _loadProdutosServico(String? empId, String? parceiroId) async {
    final base = '${ApiLinks.baseUrl}/api/produto-contabil?tamanho=500'
        '${empId != null ? '&empId=$empId' : ''}'
        '${parceiroId != null ? '&parceiroId=$parceiroId' : ''}&isServico=true';
    List<Map<String, dynamic>> produtos = [];
    await _loadList(base, (d) => produtos = d);
    if (mounted) setState(() => _produtos = produtos);
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
          '${ApiLinks.baseUrl}/api/nfse_item?nfseId=$_nfseId&tamanho=100');
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        final d =
            b is Map ? (b['data'] is Map ? b['data']['dados'] : b['data']) : b;
        final itens = (d as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        for (final item in itens) {
          _normalizarServicoItem(item);
        }
        setState(() => _itens = itens);
      }
    } catch (_) {}
  }

  // ── Salvar cabeçalho ──────────────────────────────────────────────────────

  Future<bool> _salvarCabecalho({bool showFeedback = true}) async {
    final body = <String, dynamic>{
      if (!_isNovo) 'id': _item['id'],
      if ((_statusAtual == 'AUTORIZADA' || _statusVal == 'AUTORIZADA') &&
          _numeroCtrl.text.isNotEmpty)
        'numero': _numeroCtrl.text,
      'serie': _serieCtrl.text,
      'municipioPrestacao': _municipioCtrl.text,
      'codigoServicoMunicipal': _codigoServicoCtrl.text,
      'observacao': _observacaoCtrl.text,
      if (_ambienteVal != null) 'ambiente': _ambienteVal,
      if (_empresaId != null)
        'empresa': {'id': int.tryParse(_empresaId!) ?? _empresaId},
      if (_tomadorId != null)
        'tomador': {'id': int.tryParse(_tomadorId!) ?? _tomadorId},
      if (_cidadeId != null)
        'cidade': {'id': int.tryParse(_cidadeId!) ?? _cidadeId},
      if (_dataEmissao != null)
        'dataEmissao': _dataEmissao!.toIso8601String().substring(0, 10),
      if (_dataCompetencia != null)
        'dataCompetencia': _dataCompetencia!.toIso8601String().substring(0, 10),
    };
    try {
      final r = _isNovo
          ? await TenantContext.post('${ApiLinks.baseUrl}/api/nfse', body)
          : await TenantContext.put(
              '${ApiLinks.baseUrl}/api/nfse/${_item['id']}', body);
      if (!mounted) return false;
      if (r.statusCode == 200 || r.statusCode == 201) {
        if (_isNovo) {
          try {
            final b = jsonDecode(r.body);
            final newId = b is Map
                ? (b['data'] is Map ? b['data']['id'] : (b['data'] ?? b['id']))
                : null;
            if (newId != null) {
              setState(() => _item['id'] = newId);
              _loadItens();
            }
          } catch (_) {}
        }
        if (showFeedback) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Salvo!'), backgroundColor: _green));
        }
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ${r.statusCode}: ${r.body}'),
            backgroundColor: _red));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
    return false;
  }

  Future<void> _confirmarNfse() async {
    if (_itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Adicione e salve ao menos um servico antes de confirmar.'),
          backgroundColor: _red));
      return;
    }
    final salvo = await _salvarCabecalho(showFeedback: false);
    if (!mounted || !salvo || _isNovo) {
      if (mounted && _isNovo) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Salve o cabecalho antes de confirmar.'),
            backgroundColor: _red));
      }
      return;
    }
    try {
      final r = await TenantContext.post(ApiLinks.confirmarNfse(_nfseId), {});
      if (!mounted) return;
      if (r.statusCode == 200) {
        setState(() {
          _statusVal = 'CONFIRMADA';
          _item['status'] = 'CONFIRMADA';
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('NFS-e confirmada.'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ${r.statusCode}: ${r.body}'),
            backgroundColor: _red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
      }
    }
  }

  /// Emite de verdade a NFSe via Sistema Nacional NFS-e (SefinNacional) --
  /// bug real (2026-09-17, ver bugs.md): antes disso o botao nem existia,
  /// e o backend so tinha um fluxo mockado que sempre "funcionava" sem
  /// transmitir nada de verdade.
  Future<void> _enviarNfse() async {
    if (_statusAtual != 'CONFIRMADA') return;
    setState(() => _enviando = true);
    try {
      final r =
          await TenantContext.post(ApiLinks.emitirNfseNacional(_nfseId), {});
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 201) {
        final b = jsonDecode(r.body);
        final data = b is Map ? (b['data'] ?? b) : null;
        final status = data is Map ? data['status']?.toString() : null;
        if (status == 'AUTORIZADA') {
          final numRetornado = data is Map
              ? (data['numero']?.toString() ??
                  data['nfseNumber']?.toString() ??
                  data['numeroDps']?.toString())
              : null;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'NFSe autorizada! Chave: ${data is Map ? data['chaveAcesso'] : ''}'),
              backgroundColor: _green));
          setState(() {
            _item['status'] = status;
            _statusVal = status;
            if (numRetornado != null && numRetornado.isNotEmpty) {
              _numeroCtrl.text = numRetornado;
              _item['numero'] = numRetornado;
            }
          });
        } else {
          final erro = data is Map ? data['mensagemErroEmissao'] : null;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('NFSe rejeitada: ${erro ?? r.body}'),
              backgroundColor: _red));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ${r.statusCode}: ${r.body}'),
            backgroundColor: _red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  /// Baixa o PDF (DANFSe simplificado) -- so' disponivel depois que a
  /// NFSe foi emitida/autorizada de verdade (usa o XML real persistido).
  Future<void> _baixarPdf() async {
    try {
      final r = await TenantContext.get(ApiLinks.danfseNfse(_nfseId));
      if (!mounted) return;
      if (r.statusCode == 200) {
        await FileSaver.instance.saveFile(
          name: 'danfse_$_nfseId',
          bytes: r.bodyBytes,
          fileExtension: 'pdf',
          mimeType: MimeType.pdf,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ${r.statusCode}: ${r.body}'),
            backgroundColor: _red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
      }
    }
  }

  Future<void> _cancelarNfse() async {
    final motivoCtrl = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar NFS-e'),
        content: TextField(
          controller: motivoCtrl,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          decoration:
              const InputDecoration(labelText: 'Motivo do cancelamento'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Voltar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, motivoCtrl.text.trim()),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    motivoCtrl.dispose();
    if (!mounted || motivo == null || motivo.isEmpty) return;

    try {
      final r = await TenantContext.post(ApiLinks.nfseCancelar, {
        'empresaId': int.tryParse(_empresaId ?? '') ?? 0,
        'municipio': _municipioCtrl.text,
        'nfseNumber': _numeroCtrl.text,
        'motivo': motivo,
        'nfseId': int.tryParse(_nfseId),
      });
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 201) {
        setState(() {
          _statusVal = 'CANCELADA';
          _item['status'] = 'CANCELADA';
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('NFS-e cancelada.'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ${r.statusCode}: ${r.body}'),
            backgroundColor: _red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
      }
    }
  }

  Future<void> _excluirNfse() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir NFS-e pendente?'),
        content:
            const Text('Esta ação remove a nota e seus itens definitivamente.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: _red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (!mounted || confirmar != true) return;

    try {
      final r = await TenantContext.delete(ApiLinks.nfse(_nfseId));
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 204) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ${r.statusCode}: ${r.body}'),
            backgroundColor: _red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
      }
    }
  }

  Future<void> _salvarItem(Map<String, dynamic> item) async {
    // Bug real (2026-09-17, ver bugs.md): salvar item numa NFSe nova (ainda
    // sem id) mandava nfseId=0 pro backend (int.tryParse('') ?? 0 em
    // _novoItem), que nao existe -- o backend rejeitava e o item nunca
    // aparecia salvo. O cabecalho precisa existir antes do item -- salva
    // o cabecalho primeiro se ainda for uma NFSe nova.
    if (_isNovo) {
      await _salvarCabecalho();
      if (_isNovo) {
        // _salvarCabecalho ja mostra o erro real (SnackBar) se falhar --
        // sem id novo, nao ha' como vincular o item, aborta aqui.
        return;
      }
    }
    final isNew = item['id'] == null;
    final body = <String, dynamic>{
      if (!isNew) 'id': item['id'],
      // Preferir sempre o id real do cabecalho (_nfseId) -- item['nfse_id']
      // pode estar com o placeholder 0 gravado por _novoItem() quando o
      // item foi criado antes do cabecalho existir (nunca confiar nesse
      // valor obsoleto depois que o cabecalho ja foi salvo de verdade).
      'nfseId': int.tryParse(_nfseId) ?? item['nfse_id'],
      if (item['produto'] != null) 'produto': item['produto'],
      'descricao': item['descricao'] ?? '',
      'quantidade': double.tryParse((item['quantidade'] ?? '').toString()),
      'valorUnitario': double.tryParse(
          (item['valorUnitario'] ?? item['valor_unitario'] ?? '').toString()),
      'valorTotal': double.tryParse(
          (item['valorTotal'] ?? item['valor_total'] ?? '').toString()),
      'aliquotaIss': double.tryParse(
          (item['aliquotaIss'] ?? item['aliquota_iss'] ?? '').toString()),
      'valorIss': double.tryParse(
          (item['valorIss'] ?? item['valor_iss'] ?? '').toString()),
      'codigoTributacaoMunicipal': item['codigoTributacaoMunicipal'] ??
          item['codigo_tributacao_municipal'] ??
          '',
      'issRetido': item['issRetido'] == true || item['iss_retido'] == true,
    };
    try {
      final r = isNew
          ? await TenantContext.post('${ApiLinks.baseUrl}/api/nfse_item', body)
          : await TenantContext.put(
              '${ApiLinks.baseUrl}/api/nfse_item/${item['id']}', body);
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Item salvo!'), backgroundColor: _green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ${r.statusCode}'), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  double _num(dynamic value) =>
      double.tryParse((value ?? '').toString().replaceAll(',', '.')) ?? 0.0;

  String _fmt(double value) => value.toStringAsFixed(2);

  void _normalizarServicoItem(Map<String, dynamic> item) {
    item['aliquotaIss'] ??= item['aliquota_iss'];
    item['valorIss'] ??= item['valor_iss'];
    item['valorTotal'] ??= item['valor_total'];
    item['codigoTributacaoMunicipal'] ??= item['codigo_tributacao_municipal'];
    item['issRetido'] ??= item['iss_retido'] ?? false;
    _recalcularServicoItem(item);
  }

  /// Recalcula valorTotal (quantidade x valor unitario) e valorIss (valorTotal
  /// x aliquotaIss / 100) em memoria -- bug real (2026-09-17, ver bugs.md):
  /// essa conta ja existia na versao Web, mas nunca foi replicada aqui.
  void _recalcularServicoItem(Map<String, dynamic> item) {
    final quantidade = _num(item['quantidade']);
    final unitario = _num(item['valorUnitario'] ?? item['valor_unitario']);
    final result = NfseTaxCalculator.calculate(
      quantidade: quantidade,
      valorUnitario: unitario,
      aliquotaIss: _num(item['aliquotaIss'] ?? item['aliquota_iss']),
    );
    final total = result.valorTotal;
    item['valorTotal'] = _fmt(total);
    item['valor_total'] = item['valorTotal'];

    item['valorIss'] = _fmt(result.valorIss);
    item['valor_iss'] = item['valorIss'];
  }

  Future<void> _carregarImpostosServico(
      Map<String, dynamic> item, String produtoId) async {
    try {
      final r = await TenantContext.get(
          '${ApiLinks.baseUrl}/api/produto-imposto-uf?produtoId=$produtoId');
      if (r.statusCode != 200) return;
      final raw = jsonDecode(r.body);
      if (raw is! List || raw.isEmpty) return;
      final imp = Map<String, dynamic>.from(raw.first as Map);
      if (!mounted) return;
      setState(() {
        item['aliquotaIss'] =
            (imp['aliqIss'] ?? imp['aliquotaIss'] ?? item['aliquotaIss'])
                ?.toString();
        item['codigoTributacaoMunicipal'] = (imp['codTribIss'] ??
                imp['codigoTributacaoMunicipal'] ??
                item['codigoTributacaoMunicipal'])
            ?.toString();
        _recalcularServicoItem(item);
      });
    } catch (_) {}
  }

  void _novoItem() => setState(() {
        _itens.add({'nfse_id': int.tryParse(_nfseId) ?? 0});
        _selItem = _itens.length - 1;
        _itensGrid = false;
      });

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        backgroundColor: _red,
        foregroundColor: Colors.white,
        title: Text('NFSe #$_nfseId',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        actions: [
          if (_statusAtual == 'RASCUNHO' || _statusAtual == 'PENDENTE')
            TextButton.icon(
              onPressed: !_enviando ? _confirmarNfse : null,
              icon:
                  const Icon(Icons.check_circle, size: 16, color: Colors.white),
              label: const Text('Confirmar NFS-e',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          if (_statusAtual == 'CONFIRMADA')
            TextButton.icon(
              onPressed: !_enviando ? _enviarNfse : null,
              icon: _enviando
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, size: 16, color: Colors.white),
              label: const Text('Emitir NFS-e',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          if (_podeCancelar)
            TextButton.icon(
              onPressed: _cancelarNfse,
              icon: const Icon(Icons.cancel, size: 16, color: Colors.white),
              label: const Text('Cancelar',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          if (_podeExcluir)
            TextButton.icon(
              onPressed: _excluirNfse,
              icon: const Icon(Icons.delete, size: 16, color: Colors.white),
              label: const Text('Excluir',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          if (_statusAtual == 'AUTORIZADA')
            TextButton.icon(
              onPressed: _baixarPdf,
              icon: const Icon(Icons.picture_as_pdf,
                  size: 16, color: Colors.white),
              label: const Text('Baixar PDF',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth =
              constraints.maxWidth >= 1180 ? 1120.0 : constraints.maxWidth;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _cabecalho(),
                    const SizedBox(height: 12),
                    _itensPanel(),
                    const SizedBox(height: 12),
                    _rodape(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // CABECALHO
  Widget _cabecalho() {
    return _sectionCard(
      title: 'Dados da NFSe',
      icon: Icons.receipt_long,
      action: ElevatedButton.icon(
        onPressed: _enviando ? null : () => _salvarCabecalho(),
        icon: const Icon(Icons.save, size: 14),
        label: const Text('Salvar', style: TextStyle(fontSize: 11)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF005A2B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      child: _formGrid([
        _empresaId != null
            ? _inpDisabledText('Empresa', _empresaNome ?? 'Empresa $_empresaId')
            : _ddObj('Empresa', _empresaId, _empresas, 'nome',
                (v) => setState(() => _empresaId = v)),
        if (_parceiroEmissorId != null)
          _inpDisabledText('Parceiro Emissor',
              _parceiroEmissorNome ?? 'Parceiro $_parceiroEmissorId'),
        _ddObj('Tomador', _tomadorId, _tomadores, 'nome', (v) {
          setState(() {
            _tomadorId = v;
            final tomadorMap = _tomadores
                .cast<Map<String, dynamic>?>()
                .firstWhere((p) => p?['id']?.toString() == v,
                    orElse: () => null);
            _tomadorNome = tomadorMap?['nome']?.toString();
            final cidTomador = tomadorMap?['cidade']?.toString();
            if (_municipioCtrl.text.trim().isEmpty &&
                cidTomador != null &&
                cidTomador.isNotEmpty) {
              _municipioCtrl.text = cidTomador;
            }
          });
        }),
        _ddSerie(),
        _inpDisabledText(
            'Numero',
            (_statusVal == 'AUTORIZADA' || _statusAtual == 'AUTORIZADA')
                ? _numeroCtrl.text
                : ''),
        _dateField('Data Emissao', _dataEmissao,
            (d) => setState(() => _dataEmissao = d)),
        _dateField('Data Competencia', _dataCompetencia,
            (d) => setState(() => _dataCompetencia = d)),
        _ddCidade(),
        _inp('Codigo de Servico Municipal', _codigoServicoCtrl),
        _textArea('Observacao', _observacaoCtrl),
        _inpDisabledText('Status', _statusVal ?? 'RASCUNHO'),
        _parceiroEmissorId != null
            ? _inpDisabledText('Ambiente', _ambienteVal ?? '')
            : _dd('Ambiente', _ambienteVal, ['HOMOLOGACAO', 'PRODUCAO'],
                (v) => setState(() => _ambienteVal = v)),
      ]),
    );
  }

  Widget _sectionCard(
      {required String title,
      required IconData icon,
      required Widget child,
      Widget? action}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: GridColors.borderSubtle),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Icon(icon, size: 18, color: _red),
            const SizedBox(width: 8),
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: GridColors.textSecondary))),
            if (action != null) action,
          ]),
        ),
        Container(height: 1, color: GridColors.borderSubtle),
        Padding(padding: const EdgeInsets.all(16), child: child),
      ]),
    );
  }

  Widget _formGrid(List<Widget> children) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth >= 900
          ? (constraints.maxWidth - 24) / 3
          : constraints.maxWidth >= 620
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;
      return Wrap(
          spacing: 12,
          runSpacing: 4,
          children:
              children.map((w) => SizedBox(width: width, child: w)).toList());
    });
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
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
        ),
      );

  Widget _textArea(String label, TextEditingController ctrl) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextFormField(
          controller: ctrl,
          minLines: 3,
          maxLines: 5,
          style: const TextStyle(fontSize: 12, color: _dark),
          decoration: InputDecoration(
            labelText: label,
            isDense: true,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
        ),
      );

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
        ),
      );

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
                  'nome': o[displayField]?.toString() ?? ''
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

  /// Dropdown de Série NFSe — carrega de /api/nfse-serie
  Widget _ddSerie() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SearchableDropdownField(
        label: 'Série',
        value: _series.any((o) => o['id']?.toString() == _serieId)
            ? _serieId
            : null,
        items: _series
            .map((s) => <String, dynamic>{
                  'id': s['id']?.toString() ?? '',
                  'nome':
                      '${s['serie'] ?? ''} (atual: ${_numeroAtualSerie(s) ?? 1})',
                })
            .toList(),
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        nullLabel: '— Selecione —',
        onChanged: (v) {
          setState(() => _serieId = v);
          final s = _series.firstWhere((o) => o['id']?.toString() == v,
              orElse: () => {});
          if (s.isNotEmpty) {
            _serieCtrl.text = s['serie']?.toString() ?? '';
          }
        },
      ),
    );
  }

  dynamic _numeroAtualSerie(Map<String, dynamic> serie) =>
      serie['numeroAtual'] ?? serie['numero_atual'];

  /// Dropdown de Município (Cidade) — carrega de /api/cidade
  /// Ao selecionar, preenche o código de serviço municipal se a cidade tiver
  Widget _ddCidade() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SearchableDropdownField(
        label: 'Município de Prestação',
        value: _cidades.any((o) => o['id']?.toString() == _cidadeId)
            ? _cidadeId
            : null,
        items: _cidades.map(_cidadeDropdownItem).toList(),
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        nullLabel: '— Selecione —',
        onSearch: _buscarCidadesServidor,
        onChanged: (v) => setState(() => _cidadeId = v),
        // Usa o item completo devolvido pelo widget (local ou vindo da busca
        // server-side) em vez de procurá-lo em _cidades — a busca remota pode
        // retornar cidades que ainda não estão no lote local (ex: "Uberaba").
        onItemSelected: (item) {
          if (item == null) return;
          final id = item['id']?.toString();
          final nome = item['nome']?.toString();
          if (nome != null && nome.isNotEmpty) {
            _municipioCtrl.text = nome;
          }
          if (id != null && !_cidades.any((o) => o['id']?.toString() == id)) {
            setState(() => _cidades = [item, ..._cidades]);
          }
          // Auto-preencher código de serviço municipal se a cidade tiver
          final codServico = _codigoServicoMunicipalDaCidade(item);
          if (codServico.isNotEmpty) {
            _codigoServicoCtrl.text = codServico;
          }
        },
      ),
    );
  }

  Widget _dateField(String label, DateTime? val, void Function(DateTime?) cb) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: val ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (d != null) cb(d);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 11, color: _grey),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: _bord)),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today, size: 14, color: _grey),
            const SizedBox(width: 6),
            Text(
              val != null
                  ? '${val.day.toString().padLeft(2, '0')}/${val.month.toString().padLeft(2, '0')}/${val.year}'
                  : '— Selecione —',
              style: const TextStyle(fontSize: 12, color: _dark),
            ),
          ]),
        ),
      ),
    );
  }

  // ── ITENS ──
  Widget _itensPanel() {
    return _sectionCard(
      title: 'Servicos da nota',
      icon: Icons.design_services,
      child: Column(children: [
        Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Itens (Servicos)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(width: 8),
              _togBtn(Icons.view_list, _itensGrid,
                  () => setState(() => _itensGrid = true)),
              const SizedBox(width: 4),
              _togBtn(Icons.edit_note, !_itensGrid,
                  () => setState(() => _itensGrid = false)),
              const SizedBox(width: 8),
              SizedBox(
                  height: 28,
                  child: ElevatedButton.icon(
                      onPressed: _novoItem,
                      icon: const Icon(Icons.add, size: 12),
                      label: const Text('Novo', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10)))),
              if (!_itensGrid && _itens.isNotEmpty) ...[
                const SizedBox(width: 4),
                SizedBox(
                    height: 28,
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
            ]),
        const SizedBox(height: 12),
        SizedBox(
          height: _itensGrid ? 420 : 360,
          child: _itensGrid
              ? _gridSemHeader(
                  telaNome: 'nfse_item',
                  extraParams: {'nfseId': _nfseId, 'nfse_id': _nfseId})
              : (_itens.isEmpty
                  ? const Center(
                      child: Text('Nenhum item',
                          style: TextStyle(color: GridColors.neutral)))
                  : _iForm()),
        ),
      ]),
    );
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
        // Produto — somente os marcados como serviço (Produto.isServico == true)
        _ddObjItem('Produto (Serviço)', prodId, _produtos, 'nome', (v) {
          final prod = _produtos.firstWhere((p) => p['id']?.toString() == v,
              orElse: () => {});
          setState(() {
            item['produto'] = {'id': int.tryParse(v ?? '') ?? v};
            if (prod.isNotEmpty) {
              item['descricao'] = prod['nome']?.toString() ?? '';
              item['valorUnitario'] = prod['preco']?.toString() ?? '';
              item['quantidade'] = item['quantidade'] ?? '1.00';
              item['aliquotaIss'] = prod['aliquotaIss']?.toString() ??
                  prod['aliquota_iss']?.toString() ??
                  '';
              item['codigoTributacaoMunicipal'] =
                  prod['codigoTributacaoMunicipal']?.toString() ?? '';
            }
            _recalcularServicoItem(item);
            if (v != null && v.isNotEmpty) {
              _carregarImpostosServico(item, v);
            }
          });
        }),
        _iInp('Descrição', item, 'descricao'),
        _iInp('Quantidade', item, 'quantidade',
            onChanged: (_) => setState(() => _recalcularServicoItem(item))),
        _iInp('Vl. Unitário', item, 'valorUnitario',
            onChanged: (_) => setState(() => _recalcularServicoItem(item))),
        // Bug real (2026-09-17, code review): 'Vl. Total' NAO pode ser
        // editavel em paralelo com "Valor ISS" abaixo -- os dois dependem
        // do mesmo total calculado, e um usuario editando aqui manualmente
        // sem tocar Quantidade/Vl.Unitario dessincronizava o valorIss
        // salvo (calculado sobre o total antigo) do valorTotal realmente
        // enviado ao backend.
        _iInpSomenteLeitura('Vl. Total', item, 'valorTotal'),
        // Bug real (2026-09-17, ver bugs.md): os campos de imposto do item
        // (aliquota, base de calculo/valor ISS, codigo de tributacao,
        // retencao) existiam no backend (NfseItem) e ate' eram calculados
        // em memoria (na versao Web), mas nunca apareciam como campo
        // visivel/editavel aqui na versao Windows -- a aba "Impostos"
        // sempre mostrava tudo em branco.
        _iInp('Alíquota ISS (%)', item, 'aliquotaIss',
            onChanged: (_) => setState(() => _recalcularServicoItem(item))),
        _iInpSomenteLeitura('Valor ISS', item, 'valorIss'),
        _iInp('Cód. Tributação Municipal', item, 'codigoTributacaoMunicipal'),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            title: const Text('ISS Retido pelo Tomador',
                style: TextStyle(fontSize: 12, color: _dark)),
            value: item['issRetido'] == true || item['iss_retido'] == true,
            onChanged: (v) => setState(() => item['issRetido'] = v ?? false),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _recalcularServicoItem(item)),
              icon: const Icon(Icons.calculate_outlined, size: 14),
              label: const Text('Calcular Impostos',
                  style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _green,
                side: const BorderSide(color: _green),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
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
      ]),
    );
  }

  Widget _iInp(String label, Map<String, dynamic> item, String key,
      {ValueChanged<String>? onChanged}) {
    final ctrl = TextEditingController(text: item[key]?.toString() ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: ctrl,
        onChanged: (value) {
          item[key] = value;
          onChanged?.call(value);
        },
        style: const TextStyle(fontSize: 12, color: _dark),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 11, color: _grey),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: _bord)),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
    );
  }

  Widget _iInpSomenteLeitura(
      String label, Map<String, dynamic> item, String key) {
    final value = item[key]?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        // ValueKey inclui o valor atual -- sem isso o TextFormField (sem
        // controller) so' aplica initialValue no primeiro build; ao
        // recalcular (setState em _recalcularServicoItem) o campo ficava
        // visualmente parado no valor antigo mesmo com o dado certo em
        // memoria (mesmo fix aplicado na versao Web).
        key: ValueKey('$key-$value'),
        initialValue: value,
        readOnly: true,
        style: const TextStyle(fontSize: 12, color: _grey),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 11, color: _grey),
          filled: true,
          fillColor: _bg,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: _bord)),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
    );
  }

  Widget _ddObjItem(String label, String? val, List<Map<String, dynamic>> opts,
      String df, void Function(String?) cb) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SearchableDropdownField(
        label: label,
        value: opts.any((o) => o['id']?.toString() == val) ? val : null,
        items: opts.map((o) {
          final nome = o[df]?.toString() ?? '';
          final preco = o['preco']?.toString() ?? '';
          final codigo = o['codigoTributacaoMunicipal']?.toString() ??
              o['cnae']?.toString() ??
              '';
          final display = codigo.isNotEmpty
              ? '$nome (R\$ $preco) [$codigo]'
              : '$nome (R\$ $preco)';
          return <String, dynamic>{
            'id': o['id']?.toString() ?? '',
            'nome': display
          };
        }).toList(),
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        nullLabel: '— Selecione Serviço —',
        onChanged: cb,
      ),
    );
  }

  Widget _gridSemHeader(
      {required String telaNome, Map<String, dynamic>? extraParams}) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      key: ValueKey('${telaNome}_$_nfseId'),
      telaNome: telaNome,
      hasPermission: (p) => p == 'create' ? false : true,
      fromJson: (json) => json,
      toJson: (a) => a,
      extraParams: extraParams,
      showAppBar: false,
    );
  }

  Widget _togBtn(IconData ic, bool on, VoidCallback cb) => InkWell(
        onTap: cb,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: on ? _green : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: on ? _green : _bord)),
          child: Icon(ic, size: 16, color: on ? Colors.white : _grey),
        ),
      );

  Widget _nb(IconData ic, VoidCallback cb) => InkWell(
        onTap: cb,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Icon(ic, size: 18, color: _dark)),
      );

  // ── RODAPÉ: abas ──
  Widget _rodape() {
    final tabs = ['Totais', 'Impostos'];
    return _sectionCard(
      title: 'Resumo e impostos',
      icon: Icons.summarize,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
            color: GridColors.gridHeader,
            child: Row(children: [
              const SizedBox(width: 8),
              ...tabs.asMap().entries.map((e) => _tabBtn(e.key, e.value)),
            ])),
        Container(height: 1, color: GridColors.borderSubtle),
        SizedBox(height: 180, child: _tabContent()),
      ]),
    );
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
                color: on ? _red : _grey)),
      ),
    );
  }

  Widget _tabContent() {
    switch (_tab) {
      case 0:
        return _totaisTab();
      case 1:
        return _impostosTab();
      default:
        return const SizedBox();
    }
  }

  Widget _totaisTab() {
    final vt = _item['valorTotal']?.toString() ?? '0,00';
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [_card('Vlr. NFSe', vt), _card('Total Serviços', vt)]),
    );
  }

  Widget _card(String label, String value) => Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _bord)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: _grey)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
        ]),
      );

  /// Aba Impostos — ISS / alíquota ISS / código de tributação municipal /
  /// ISS retido por item (espelha _impostosTab do NfeSankhyaDetailScreen,
  /// mas exibindo os campos de ISS de cada item da NFSe).
  Widget _impostosTab() {
    if (_itens.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(10),
        child: Text('Impostos (ISS) calculados a partir dos itens.',
            style: TextStyle(color: _grey, fontSize: 12)),
      );
    }
    final baseIss = _itens.fold<double>(0,
        (sum, item) => sum + _num(item['valorTotal'] ?? item['valor_total']));
    final totalIss = _itens.fold<double>(
        0, (sum, item) => sum + _num(item['valorIss'] ?? item['valor_iss']));
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        Wrap(spacing: 10, runSpacing: 8, children: [
          _card('Base ISS', _fmt(baseIss)),
          _card('ISS da nota', _fmt(totalIss)),
        ]),
        const SizedBox(height: 10),
        ..._itens.asMap().entries.map((entry) {
          final i = entry.key;
          final item = _itens[i];
          final descricao = item['descricao']?.toString() ?? 'Item ${i + 1}';
          final aliquota = item['aliquotaIss']?.toString() ??
              item['aliquota_iss']?.toString() ??
              '-';
          final valorIss = item['valorIss']?.toString() ??
              item['valor_iss']?.toString() ??
              '-';
          final codTrib = item['codigoTributacaoMunicipal']?.toString() ??
              item['codigo_tributacao_municipal']?.toString() ??
              '-';
          final retido =
              item['issRetido'] == true || item['iss_retido'] == true;
          return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _bord)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(descricao,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 6),
                      Wrap(spacing: 16, runSpacing: 6, children: [
                        _impInfo('Alíquota ISS', '$aliquota%'),
                        _impInfo('Valor ISS', valorIss),
                        _impInfo('Cód. Tributação Municipal', codTrib),
                        _impInfo('ISS Retido', retido ? 'Sim' : 'Não'),
                      ]),
                    ]),
              ));
        }),
      ],
    );
  }

  Widget _impInfo(String label, String value) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: _grey)),
        Text(value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: _dark)),
      ]);
}
