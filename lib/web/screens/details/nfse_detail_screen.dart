import 'dart:convert';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/auth_utility.dart';
import '../../../models/empresa_acesso_model.dart';
import '../../../models/parceiro_model.dart';
import '../../../utils/api_links.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/nfse_tax_calculator.dart';
import '../../../services/nfse_caller.dart';
import '../../../widgets/searchable_dropdown.dart';

const _red = GridColors.primary;
const _green = GridColors.secondary;
const _bord = Color(0xFFDDDDDD);
const _grey = Color(0xFF757575);
const _dark = Color(0xFF212121);
const _bg = Color(0xFFF5F5F5);

String? resolveCodigoServicoMunicipalNfseWeb(Map<String, dynamic>? cidade) {
  final valor = cidade?['codigoServicoMunicipal'] ??
      cidade?['codigo_servico_municipal'] ??
      cidade?['codigoServico'] ??
      cidade?['codigo_servico'] ??
      cidade?['ibge'];
  final texto = valor?.toString().trim();
  return texto == null || texto.isEmpty ? null : texto;
}

class NfseEmpresaDefaults {
  final String? municipio;
  final String? cidadeId;
  final String? ambiente;
  final String? codigoServicoMunicipal;

  const NfseEmpresaDefaults({
    this.municipio,
    this.cidadeId,
    this.ambiente,
    this.codigoServicoMunicipal,
  });
}

NfseEmpresaDefaults resolveNfseEmpresaDefaults(Map<String, dynamic> empresa) {
  final cidade = empresa['cidade'] is Map
      ? Map<String, dynamic>.from(empresa['cidade'] as Map)
      : <String, dynamic>{};
  String? texto(dynamic value) {
    final result = value?.toString().trim();
    return result == null || result.isEmpty ? null : result;
  }

  return NfseEmpresaDefaults(
    municipio: texto(cidade['nome']) ?? texto(empresa['cidade']),
    cidadeId: texto(cidade['id']),
    ambiente: texto(empresa['ambiente']),
    codigoServicoMunicipal: resolveCodigoServicoMunicipalNfseWeb(cidade),
  );
}

class NfseTomadorDefaults {
  final String? municipio;
  final String? cidadeId;
  final String? ambiente;
  final String? codigoServicoMunicipal;

  const NfseTomadorDefaults(
      {this.municipio,
      this.cidadeId,
      this.ambiente,
      this.codigoServicoMunicipal});
}

NfseTomadorDefaults resolveNfseTomadorDefaults(Map<String, dynamic> tomador) {
  final endereco = tomador['endereco'] is Map
      ? Map<String, dynamic>.from(tomador['endereco'] as Map)
      : <String, dynamic>{};
  final cidadeEndereco = endereco['cidade'];
  final cidadeValue = cidadeEndereco is Map
      ? cidadeEndereco
      : tomador['cidade'] ?? cidadeEndereco;
  final cidade = cidadeValue is Map
      ? Map<String, dynamic>.from(cidadeValue)
      : <String, dynamic>{};
  String? texto(dynamic value) {
    final result = value?.toString().trim();
    return result == null || result.isEmpty ? null : result;
  }

  final ambienteRaw = texto(tomador['ambiente']);
  String? ambiente;
  if (ambienteRaw != null) {
    final normalizado = ambienteRaw.toUpperCase();
    ambiente = normalizado.contains('PRODU') || normalizado == '1'
        ? 'PRODUCAO'
        : normalizado.contains('HOMOLOG') || normalizado == '2'
            ? 'HOMOLOGACAO'
            : null;
  }

  return NfseTomadorDefaults(
    municipio:
        texto(cidade['nome']) ?? texto(tomador['cidade']) ?? texto(cidadeValue),
    cidadeId: texto(cidade['id']),
    ambiente: ambiente,
    codigoServicoMunicipal: resolveCodigoServicoMunicipalNfseWeb(cidade),
  );
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
  final _nfseCaller = NfseCaller();

  double _cabWidth = 320;
  double _rodapeHeight = 240;

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
  String? _tomadorNome;
  String? _serieId;
  String? _cidadeId;
  DateTime? _dataEmissao;
  DateTime? _dataCompetencia;

  String? _empresaNome;

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
    final ambienteParceiro = resolveNfseTomadorDefaults({
      'ambiente': login?.parceiro?.ambiente,
    }).ambiente;
    _ambienteVal = i['ambiente']?.toString() ??
        (_isNovo || TenantContext.hasParceiro ? ambienteParceiro : null);

    // O parceiro autenticado e' o emissor. O tomador e' outro cadastro.
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
      final codigoMunicipal = resolveCodigoServicoMunicipalNfseWeb(cidade);
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

  String _primeiroTextoPreenchido(
      Map<String, dynamic> origem, List<String> chaves) {
    for (final chave in chaves) {
      final valor = origem[chave]?.toString().trim();
      if (valor != null && valor.isNotEmpty) return valor;
    }
    return '';
  }

  String _codigoServicoMunicipalInicial(Map<String, dynamic> item) {
    final codigoDireto = _primeiroTextoPreenchido(item, const [
      'codigoServicoMunicipal',
      'codigo_servico_municipal',
      'codigoServico',
      'codigo_servico',
    ]);
    if (codigoDireto.isNotEmpty) return codigoDireto;

    final cidade = item['cidade'];
    if (cidade is Map) {
      return _codigoServicoMunicipalDaCidade(Map<String, dynamic>.from(cidade));
    }
    return '';
  }

  String _codigoServicoMunicipalDaCidade(Map<String, dynamic> cidade) {
    return resolveCodigoServicoMunicipalNfseWeb(cidade) ?? '';
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
    if (_parceiroEmissorId != null && _parceiroEmissorId!.isNotEmpty) {
      await _carregarDadosParceiroEmissor();
    } else {
      await _carregarDadosEmpresa();
    }
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
    final parceiroSessao = _login?.parceiro;
    final data = <String, dynamic>{};
    void mesclarDados(Map<String, dynamic> origem) {
      for (final entry in origem.entries) {
        if (entry.value != null && entry.value.toString().trim().isNotEmpty) {
          data[entry.key] = entry.value;
        }
      }
    }

    if (parceiroSessao != null) mesclarDados(parceiroSessao.toJson());
    for (final parceiro in _tomadores) {
      if (parceiro['id']?.toString() == id) {
        mesclarDados(parceiro);
        break;
      }
    }
    try {
      final response =
          await TenantContext.get('${ApiLinks.baseUrl}/api/parceiro/$id');
      if (response.statusCode == 200) {
        final raw = jsonDecode(response.body);
        final parceiro = raw is Map && raw['data'] is Map
            ? Map<String, dynamic>.from(raw['data'] as Map)
            : raw is Map
                ? Map<String, dynamic>.from(raw)
                : <String, dynamic>{};
        mesclarDados(parceiro);
      } else {
        AppLogger.i.warn(
            'Usando dados da sessao para parceiro emissor $id (HTTP ${response.statusCode}).');
      }
    } catch (e, stack) {
      AppLogger.i.error(
          'Erro ao consultar parceiro emissor $id; usando dados da sessao: $e',
          stack);
    }
    if (data.isEmpty || !mounted) return;
    try {
      final defaults = resolveNfseTomadorDefaults(data);
      final cidadeNome = defaults.municipio;
      Map<String, dynamic>? cidadeEncontrada;
      if (defaults.cidadeId == null && cidadeNome != null) {
        final cidades = await _buscarCidadesServidor(cidadeNome);
        final normalizado = cidadeNome.trim().toUpperCase();
        for (final cidade in cidades) {
          if (cidade['nome']?.toString().trim().toUpperCase() == normalizado) {
            cidadeEncontrada = cidade;
            break;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _parceiroEmissorNome =
            (data['nome'] ?? data['razaoSocial'])?.toString() ??
                _parceiroEmissorNome;
        if (_municipioCtrl.text.trim().isEmpty && cidadeNome != null) {
          _municipioCtrl.text = cidadeNome;
        }
        if (_cidadeId == null) {
          _cidadeId = defaults.cidadeId ?? cidadeEncontrada?['id']?.toString();
          if (cidadeEncontrada != null &&
              !_cidades.any((c) => c['id']?.toString() == _cidadeId)) {
            _cidades = [cidadeEncontrada!, ..._cidades];
          }
        }
        if (_codigoServicoCtrl.text.trim().isEmpty) {
          _codigoServicoCtrl.text = defaults.codigoServicoMunicipal ??
              _codigoServicoMunicipalDaCidade(cidadeEncontrada ?? {});
        }
        if ((_ambienteVal == null || _ambienteVal!.isEmpty) &&
            defaults.ambiente != null) {
          _ambienteVal = defaults.ambiente;
        }
      });
    } catch (e, stack) {
      AppLogger.i.error(
          'Erro ao aplicar defaults fiscais do parceiro emissor $id: $e',
          stack);
    }
  }

  Future<void> _carregarDadosEmpresa() async {
    if (!_isNovo || _empresaId == null || _empresaId!.isEmpty) return;
    try {
      final response = await TenantContext.get(
          '${ApiLinks.baseUrl}/api/empresa/$_empresaId');
      if (response.statusCode != 200) {
        AppLogger.i.warn(
            'Nao foi possivel carregar defaults da empresa $_empresaId (HTTP ${response.statusCode}).');
        return;
      }
      final raw = jsonDecode(response.body);
      if (raw is! Map) return;
      final defaults = resolveNfseEmpresaDefaults(
          Map<String, dynamic>.from(raw['data'] is Map ? raw['data'] : raw));
      if (!mounted) return;
      setState(() {
        if (_municipioCtrl.text.trim().isEmpty && defaults.municipio != null) {
          _municipioCtrl.text = defaults.municipio!;
          _cidadeId ??= defaults.cidadeId;
        }
        if ((_ambienteVal == null || _ambienteVal!.isEmpty) &&
            defaults.ambiente != null) {
          _ambienteVal = defaults.ambiente;
        }
        if (_codigoServicoCtrl.text.trim().isEmpty &&
            defaults.codigoServicoMunicipal != null) {
          _codigoServicoCtrl.text = defaults.codigoServicoMunicipal!;
        }
      });
    } catch (e, stack) {
      AppLogger.i.error(
          'Erro ao carregar ambiente/municipio da empresa $_empresaId para nova NFS-e: $e',
          stack);
    }
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
    // sem id) mandava nfseId=null pro backend, que rejeita com 400
    // ("nfseId e obrigatorio"). O cabecalho precisa existir antes do item
    // -- salva o cabecalho primeiro se ainda for uma NFSe nova.
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
      'nfseId': item['nfse_id'] ?? int.tryParse(_nfseId),
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

  void _novoItem() => setState(() {
        _itens.add({'nfse_id': int.tryParse(_nfseId) ?? 0});
        _selItem = _itens.length - 1;
        _itensGrid = false;
      });

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

  void _aplicarProdutoServicoSelecionado(
      Map<String, dynamic> item, Map<String, dynamic> selected) {
    final id = selected['id']?.toString();
    item['produto'] = {'id': int.tryParse(id ?? '') ?? id};
    item['descricao'] = selected['nome']?.toString() ??
        selected['descricao']?.toString() ??
        item['descricao'] ??
        '';
    item['valorUnitario'] =
        selected['preco']?.toString() ?? item['valorUnitario'] ?? '0.00';
    item['quantidade'] = item['quantidade'] ?? '1.00';
    item['cnae'] = selected['cnae']?.toString() ?? item['cnae'] ?? '';
    item['codigoTributacaoMunicipal'] =
        selected['codigoTributacaoMunicipal']?.toString() ??
            selected['codigo_tributacao_municipal']?.toString() ??
            item['codigoTributacaoMunicipal'] ??
            '';
    _recalcularServicoItem(item);
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
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
      body: Column(children: [
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                            size: 14, color: _grey))),
              ),
            ),
            Expanded(child: _itensPanel()),
          ]),
        ),
        GestureDetector(
          onVerticalDragUpdate: (d) => setState(() =>
              _rodapeHeight = (_rodapeHeight - d.delta.dy).clamp(120, 400)),
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeRow,
            child: Container(
                height: 6,
                color: _bord,
                child: const Center(
                    child: Icon(Icons.drag_handle, size: 14, color: _grey))),
          ),
        ),
        SizedBox(height: _rodapeHeight, child: _rodape()),
      ]),
    );
  }

  // ── CABEÇALHO ──
  Widget _cabecalho() {
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
            ElevatedButton.icon(
              onPressed: _enviando ? null : () => _salvarCabecalho(),
              icon: const Icon(Icons.save, size: 14),
              label: const Text('Salvar', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005A2B),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              _empresaId != null
                  ? _inpDisabledText(
                      'Empresa', _empresaNome ?? 'Empresa $_empresaId')
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
                  'Número',
                  (_statusVal == 'AUTORIZADA' || _statusAtual == 'AUTORIZADA')
                      ? _numeroCtrl.text
                      : ''),
              _dateField('Data Emissão', _dataEmissao,
                  (d) => setState(() => _dataEmissao = d)),
              _dateField('Data Competência', _dataCompetencia,
                  (d) => setState(() => _dataCompetencia = d)),
              _ddCidade(),
              _inp('Código de Serviço Municipal', _codigoServicoCtrl),
              _textArea('Observação', _observacaoCtrl),
              _inpDisabledText('Status', _statusVal ?? 'RASCUNHO'),
              _parceiroEmissorId != null
                  ? _inpDisabledText('Ambiente', _ambienteVal ?? '')
                  : _dd('Ambiente', _ambienteVal, ['HOMOLOGACAO', 'PRODUCAO'],
                      (v) => setState(() => _ambienteVal = v)),
            ]),
          ),
        ),
      ]),
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
  Map<String, dynamic> _cidadeDropdownItem(Map<String, dynamic> cidade) {
    final codigo = _codigoServicoMunicipalDaCidade(cidade);
    return <String, dynamic>{
      'id': cidade['id']?.toString() ?? '',
      'nome': cidade['nome']?.toString() ?? '',
      if (codigo.isNotEmpty) 'codigoServicoMunicipal': codigo,
    };
  }

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
    return Container(
      color: Colors.white,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: const Color(0xFFF8F8F8),
          child: Row(children: [
            const Text('Itens (Serviços)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: 8),
            _togBtn(Icons.view_list, _itensGrid,
                () => setState(() => _itensGrid = true)),
            const SizedBox(width: 4),
            _togBtn(Icons.edit_note, !_itensGrid,
                () => setState(() => _itensGrid = false)),
            const SizedBox(width: 8),
            SizedBox(
                height: 24,
                child: ElevatedButton.icon(
                    onPressed: _novoItem,
                    icon: const Icon(Icons.add, size: 12),
                    label: const Text('Novo', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10)))),
            if (!_itensGrid && _itens.isNotEmpty) ...[
              const SizedBox(width: 4),
              SizedBox(
                  height: 24,
                  child: ElevatedButton.icon(
                      onPressed: () => _salvarItem(_itens[_selItem]),
                      icon: const Icon(Icons.save, size: 12),
                      label:
                          const Text('Salvar', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _green,
                          padding: const EdgeInsets.symmetric(horizontal: 8)))),
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
          ]),
        ),
        Container(height: 1, color: _bord),
        Expanded(
          child: _itensGrid
              ? _gridSemHeader(
                  telaNome: 'nfse_item',
                  extraParams: {'nfseId': _nfseId, 'nfse_id': _nfseId})
              : (_itens.isEmpty
                  ? const Center(
                      child:
                          Text('Nenhum item', style: TextStyle(color: _grey)))
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
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Builder(builder: (context) {
            final login = _login;
            final empId = login?.empresa?.id?.toString() ?? _empresaId;
            final parceiroId = _parceiroEmissorId;
            return SearchableDropdownField(
              label: 'Produto (Serviço)',
              value: prodId,
              items: _produtos,
              valueField: 'id',
              displayField: 'nome',
              nullable: true,
              nullLabel: '— Selecione Serviço —',
              loadPage: ({String? busca, required int pagina}) =>
                  DropdownHelpers.produtosContabeisBusca(
                busca: busca,
                pagina: pagina,
                tamanho: 20,
                empresaId: empId,
                parceiroId: parceiroId,
                isServico: true,
              ),
              labelResolver: DropdownHelpers.produtoContabilLabelPorId,
              onChanged: (v) {
                setState(() {
                  item['produto'] = {'id': int.tryParse(v ?? '') ?? v};
                });
              },
              onItemSelected: (selected) {
                if (selected == null) return;
                final id = selected['id']?.toString();
                setState(() {
                  _aplicarProdutoServicoSelecionado(item, selected);
                });
                if (id != null && id.isNotEmpty) {
                  _carregarImpostosServico(item, id);
                }
              },
            );
          }),
        ),
        _iInp('Descrição', item, 'descricao'),
        _iInp('Quantidade', item, 'quantidade',
            onChanged: (_) => setState(() => _recalcularServicoItem(item))),
        _iInp('Vl. Unitário', item, 'valorUnitario',
            onChanged: (_) => setState(() => _recalcularServicoItem(item))),
        // Bug real (2026-09-17, code review): 'Vl. Total' NAO pode ser
        // editavel em paralelo com o campo "Base de Calculo (ISS)" abaixo
        // -- os dois apontam pra mesma chave (valorTotal), e um usuario
        // editando aqui manualmente sem tocar Quantidade/Vl.Unitario
        // dessincronizava o valorIss salvo (calculado sobre o total
        // antigo) do valorTotal realmente enviado ao backend.
        _iInpSomenteLeitura('Vl. Total', item, 'valorTotal'),
        // Bug real (2026-09-17, ver bugs.md): os campos de imposto do item
        // (aliquota, base de calculo/valor ISS, codigo de tributacao,
        // retencao) existiam no backend (NfseItem) e ate' eram calculados
        // em memoria (_recalcularServicoItem), mas nunca apareciam como
        // campo visivel/editavel no formulario -- a aba "Impostos" sempre
        // mostrava tudo em branco porque o produto pode nao ter cadastro
        // de aliquota (produto_imposto_uf), e o usuario nao tinha como
        // digitar/corrigir manualmente.
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

  /// Campo somente-leitura pra valores calculados (base de calculo/valor
  /// ISS) -- mostra o valor mas nao deixa o usuario editar diretamente
  /// (o calculo vem de quantidade x valor unitario x aliquota).
  Widget _iInpSomenteLeitura(
      String label, Map<String, dynamic> item, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        key: ValueKey('$key-${item[key]}'),
        initialValue: item[key]?.toString() ?? '',
        readOnly: true,
        style: const TextStyle(fontSize: 12, color: _grey),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 11, color: _grey),
          filled: true,
          fillColor: const Color(0xFFF0F0F0),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: _bord)),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
    );
  }

  Widget _iInp(String label, Map<String, dynamic> item, String key,
      {void Function(String)? onChanged}) {
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
      child:
          Row(children: [_card('Vlr. NFSe', vt), _card('Total Serviços', vt)]),
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
