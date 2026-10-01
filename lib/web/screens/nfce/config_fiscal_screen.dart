import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../utils/grid_colors.dart';

import '../../../services/nfce_service.dart';
import '../../../utils/api_links.dart';
import '../../../utils/api_response_helpers.dart';
import '../../../utils/grid_texts.dart';
import '../../../utils/security_matrix.dart';
import '../../../utils/tenant_context.dart';
import '../../../models/nfce/nfce_config_fiscal_cache_model.dart';
import '../../../repositories/nfce_config_fiscal_cache_repository.dart';
import '../../../widgets/nfce/nfce_notice_banner.dart';
import '../../../widgets/searchable_dropdown.dart';
import 'nfce_inutilizacao_screen.dart';

/// Tela de configuração fiscal NFC-e.
/// Configurações como CSC, certificado, ambiente, série e UF.
class ConfigFiscalScreen extends StatefulWidget {
  const ConfigFiscalScreen({super.key});

  @override
  State<ConfigFiscalScreen> createState() => _ConfigFiscalScreenState();
}

class _ConfigFiscalScreenState extends State<ConfigFiscalScreen> {
  final NfceService _service = NfceService();
  final NfceConfigFiscalCacheRepository _cache =
      NfceConfigFiscalCacheRepository();
  final _formKey = GlobalKey<FormState>();

  String _uf = 'SP';
  String _ambiente = 'HOMOLOGACAO';
  String _idCsc = '';
  String _csc = '';
  String _serie = '001';
  String _senhaCertificado = '';
  bool _mostrarSenha = false;
  bool _mostrarCsc = false;
  bool _contingenciaHabilitada = false;

  String? _nomeCertificado;
  List<int>? _bytesCertificado;
  int? _configId;
  // CSC e senha do certificado sao segredos write-only: o backend nunca os
  // devolve (por design). Esta flag indica que ja existe um certificado
  // salvo no backend, para nao dar a falsa impressao de "nao configurado".
  bool _certificadoJaSalvo = false;

  bool _carregando = false;
  bool _salvando = false;
  bool _verificandoSefaz = false;
  NfceSefazHealthResult? _sefazHealth;

  // ── Cliente/Parceiro (card ConfigFiscalScreen por Cliente) ────────────────
  List<Map<String, dynamic>> _clientes = [];
  bool _loadingClientes = false;
  int? _clienteId;
  String _escopoConfig = 'EMPRESA';
  // true quando os campos vieram do cache local e ainda nao foram destravados
  // pelo botao "Editar" (nao se aplica quando o campo esta travado pela
  // identidade do login — nesse caso nao ha botao de destravar).
  bool _camposTravadosPeloCache = false;
  bool get _clienteTravadoPeloLogin => TenantContext.hasParceiro;
  bool get _camposFiscaisEditaveis => !_camposTravadosPeloCache;
  // Mesmo criterio usado em _salvar() para decidir POST (config nova) vs
  // PUT (config existente): quando um Cliente sem config propria esta
  // selecionado, _configId aponta para o fallback da config da Empresa
  // (nao nulo!), entao "_configId == null" sozinho NAO basta para saber
  // se estamos criando uma config nova.
  bool get _criandoConfigNova =>
      _configId == null || (_clienteId != null && _escopoConfig != 'CLIENTE');

  static const _ufs = [
    'AC',
    'AL',
    'AM',
    'AP',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MG',
    'MS',
    'MT',
    'PA',
    'PB',
    'PE',
    'PI',
    'PR',
    'RJ',
    'RN',
    'RO',
    'RR',
    'RS',
    'SC',
    'SE',
    'SP',
    'TO',
  ];

  @override
  void initState() {
    super.initState();
    if (_clienteTravadoPeloLogin) {
      _clienteId = TenantContext.parceiroId;
    }
    _carregarConfig();
    if (!_clienteTravadoPeloLogin) {
      _carregarClientes();
    }
  }

  Future<void> _carregarClientes() async {
    final empresaId = TenantContext.empresaId;
    if (empresaId == null) return;
    setState(() => _loadingClientes = true);
    try {
      final url = ApiLinks.allParceirosPorEmp(empresaId.toString());
      final response = await TenantContext.get(url);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final lista = extrairListaDeResposta(jsonDecode(response.body));
        setState(() {
          _clientes = lista
              .whereType<Map>()
              .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
              .toList();
        });
      }
    } catch (_) {
      // Lista de clientes é auxiliar — falha ao carregar não bloqueia a tela.
    } finally {
      if (mounted) setState(() => _loadingClientes = false);
    }
  }

  /// Carrega a config fiscal aplicando a regra de precedência Cliente > Empresa.
  /// Primeiro tenta o cache local (Hive); se não houver cache, busca no backend
  /// e grava no cache para a próxima abertura da tela.
  Future<void> _carregarConfig({bool ignorarCache = false}) async {
    final empresaId = TenantContext.empresaId;
    if (empresaId == null) return;

    setState(() => _carregando = true);
    try {
      if (!ignorarCache) {
        final cacheado = await _cache.obterCache(
          empresaId: empresaId,
          parceiroId: _clienteId,
        );
        if (cacheado != null) {
          if (!mounted) return;
          setState(() {
            _configId = cacheado.configId;
            _uf = cacheado.uf;
            _ambiente = cacheado.ambiente;
            _idCsc = cacheado.idCsc;
            _csc = cacheado.csc;
            _serie = cacheado.serieNfce;
            _contingenciaHabilitada = cacheado.contingenciaHabilitada;
            _escopoConfig = cacheado.escopo;
            _certificadoJaSalvo = cacheado.temCertificado;
            _camposTravadosPeloCache = true;
          });
          return;
        }
      }

      final config = await _service.buscarConfigFiscal(
        empresaId,
        parceiroId: _clienteId,
      );
      if (!mounted) return;
      final escopoResolvido = config['escopo']?.toString() ?? 'EMPRESA';
      final configuracoes = (config['configuracoes'] is List)
          ? (config['configuracoes'] as List)
              .whereType<Map>()
              .map((item) => item.map(
                    (key, value) => MapEntry(key.toString(), value),
                  ))
              .toList()
          : const <Map<String, dynamic>>[];
      final selecionada = configuracoes.cast<Map<String, dynamic>>().firstWhere(
            (item) =>
                (item['uf']?.toString().toUpperCase() ?? '') == _uf &&
                (item['ambiente']?.toString().toUpperCase() ?? '') == _ambiente,
            orElse: () => configuracoes.isNotEmpty
                ? configuracoes.first.cast<String, dynamic>()
                : <String, dynamic>{},
          );
      setState(() {
        _configId = selecionada['id'] is num
            ? (selecionada['id'] as num).toInt()
            : int.tryParse(selecionada['id']?.toString() ?? '');
        _uf = selecionada['uf']?.toString() ?? _uf;
        _ambiente = selecionada['ambiente']?.toString() ?? _ambiente;
        _idCsc = selecionada['idCsc']?.toString() ?? '';
        _csc = selecionada['csc']?.toString() ?? '';
        _serie = selecionada['serieNfce']?.toString() ??
            selecionada['serie']?.toString() ??
            _serie;
        _contingenciaHabilitada = selecionada['contingenciaHabilitada'] == true;
        _escopoConfig = escopoResolvido;
        _certificadoJaSalvo = selecionada['temCertificado'] == true;
        _camposTravadosPeloCache = false;
      });

      if (_configId != null && _csc.isNotEmpty) {
        await _cache.salvarCache(NfceConfigFiscalCacheModel(
          configId: _configId!,
          empresaId: empresaId,
          parceiroId: _clienteId,
          escopo: escopoResolvido,
          uf: _uf,
          ambiente: _ambiente,
          idCsc: _idCsc,
          csc: _csc,
          serieNfce: _serie,
          contingenciaHabilitada: _contingenciaHabilitada,
          temCertificado: _certificadoJaSalvo,
          cacheadoEm: DateTime.now(),
        ));
      }
    } catch (_) {
      // Config ainda não existe — usa defaults (fluxo de criação para o cliente).
      if (mounted) {
        setState(() {
          _configId = null;
          _escopoConfig = _clienteId != null ? 'CLIENTE' : 'EMPRESA';
          _certificadoJaSalvo = false;
          _camposTravadosPeloCache = false;
        });
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  /// Destrava os campos preenchidos a partir do cache local e busca a versão
  /// mais recente no backend antes de permitir edição.
  Future<void> _alternarEdicao() async {
    setState(() => _camposTravadosPeloCache = false);
    await _carregarConfig(ignorarCache: true);
  }

  void _onClienteAlterado(String? novoClienteId) {
    setState(() {
      _clienteId = novoClienteId != null ? int.tryParse(novoClienteId) : null;
      _configId = null;
      _escopoConfig = _clienteId != null ? 'CLIENTE' : 'EMPRESA';
      _idCsc = '';
      _csc = '';
      _serie = '001';
      _certificadoJaSalvo = false;
      _camposTravadosPeloCache = false;
    });
    _carregarConfig();
  }

  List<Map<String, dynamic>> get _clientesComSelecionado {
    final id = _clienteId;
    if (id == null ||
        _clientes
            .any((cliente) => cliente['id']?.toString() == id.toString())) {
      return _clientes;
    }
    return [
      {'id': id, 'nome': 'Cliente ID $id'},
      ..._clientes,
    ];
  }

  Widget _buildClienteField() {
    if (_clienteTravadoPeloLogin) {
      return TextFormField(
        key: ValueKey('cliente_login_${_clienteId ?? ''}'),
        initialValue: _clienteId?.toString() ?? '—',
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'Cliente (ID)',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.lock_outline, size: 16),
        ),
      );
    }

    return SearchableDropdownField(
      label: _loadingClientes ? 'Carregando clientes...' : 'Cliente',
      value: _clienteId?.toString(),
      items: _clientesComSelecionado,
      valueField: 'id',
      displayField: 'nome',
      nullable: true,
      nullLabel: 'Configuração da empresa',
      hintText: 'Selecione para configuração por cliente',
      onChanged: _onClienteAlterado,
    );
  }

  Widget _buildEscopoBanner() {
    final isCliente = _escopoConfig == 'CLIENTE';
    final text = isCliente
        ? 'Configuração específica do cliente selecionado.'
        : _clienteId == null
            ? 'Configuração geral da empresa.'
            : 'Cliente sem configuração própria: usando configuração da empresa até salvar uma específica.';
    return NfceNoticeBanner(
      icon: isCliente ? Icons.person_pin_circle_outlined : Icons.business,
      backgroundColor:
          isCliente ? const Color(0xFFEAF4FF) : const Color(0xFFF4F6F8),
      borderColor:
          isCliente ? const Color(0xFFB6D4FE) : const Color(0xFFD0D7DE),
      textColor: isCliente ? const Color(0xFF0B5CAD) : GridColors.secondary,
      title: isCliente ? 'Escopo Cliente' : 'Escopo Empresa',
      message: text,
      trailing: _camposTravadosPeloCache
          ? TextButton.icon(
              onPressed: _alternarEdicao,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar'),
            )
          : null,
    );
  }

  Future<void> _selecionarCertificado() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pfx', 'p12'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() {
      _nomeCertificado = file.name;
      _bytesCertificado = file.bytes?.toList();
    });
  }

  Future<void> _verificarSefaz() async {
    final empresaId = TenantContext.empresaId;
    if (empresaId == null) {
      _mostrarErro('Empresa não identificada.');
      return;
    }

    setState(() {
      _verificandoSefaz = true;
      _sefazHealth = null;
    });
    try {
      final result = await _service.verificarSaudeSefaz(
        empresaId: empresaId,
        uf: _uf,
        ambiente: _ambiente,
      );
      if (mounted) setState(() => _sefazHealth = result);
    } catch (e) {
      if (mounted) {
        setState(() {
          _sefazHealth = NfceSefazHealthResult(
            disponivel: false,
            status: 'DOWN',
            mensagem: 'Falha ao consultar a saúde da SEFAZ: $e',
            uf: _uf,
            ambiente: _ambiente,
          );
        });
      }
    } finally {
      if (mounted) setState(() => _verificandoSefaz = false);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final empresaId = TenantContext.empresaId;
    if (empresaId == null) {
      _mostrarErro('Empresa não identificada.');
      return;
    }

    setState(() => _salvando = true);
    try {
      if (_bytesCertificado != null && _nomeCertificado != null) {
        if (_senhaCertificado.isEmpty) {
          _mostrarErro(GridTexts.certificatePasswordRequiredBeforeSave);
          return;
        }
      }

      final payload = <String, dynamic>{
        'empresaId': empresaId,
        if (_clienteId != null) 'parceiroId': _clienteId,
        'uf': _uf,
        'ambiente': _ambiente,
        'idCsc': _idCsc,
        // O backend nunca devolve o CSC salvo (segredo write-only). Se o
        // campo estiver vazio numa config ja existente, e porque o valor
        // nao foi redigitado — omite do payload para o backend manter o
        // que ja esta salvo, em vez de sobrescrever com vazio.
        if (_csc.trim().isNotEmpty) 'csc': _csc,
        'serieNfce': int.tryParse(_serie) ?? 1,
        'contingenciaHabilitada': _contingenciaHabilitada,
      };

      Map<String, dynamic>? salvo;
      if (_criandoConfigNova) {
        salvo = await _service.criarConfigFiscal(payload);
        _configId = salvo['id'] is num
            ? (salvo['id'] as num).toInt()
            : int.tryParse(salvo['id']?.toString() ?? '');
      } else {
        await _service.salvarConfigFiscal({
          'id': _configId,
          ...payload,
        });
      }

      final escopoSalvo = (salvo?['escopo']?.toString() ??
              (_clienteId != null ? 'CLIENTE' : 'EMPRESA'))
          .toUpperCase();
      if (_configId != null) {
        if (_bytesCertificado != null && _nomeCertificado != null) {
          await _service.uploadCertificado(
            fileBytes: _bytesCertificado!,
            fileName: _nomeCertificado!,
            senha: _senhaCertificado,
            empresaId: empresaId,
            parceiroId: _clienteId,
            uf: _uf,
            ambiente: _ambiente,
          );
          _certificadoJaSalvo = true;
        }
        await _cache.salvarCache(NfceConfigFiscalCacheModel(
          configId: _configId!,
          empresaId: empresaId,
          parceiroId: _clienteId,
          escopo: escopoSalvo,
          uf: _uf,
          ambiente: _ambiente,
          idCsc: _idCsc,
          csc: _csc,
          serieNfce: _serie,
          contingenciaHabilitada: _contingenciaHabilitada,
          temCertificado: _certificadoJaSalvo,
          cacheadoEm: DateTime.now(),
        ));
      }

      if (!mounted) return;
      setState(() {
        _escopoConfig = escopoSalvo;
        _camposTravadosPeloCache = true;
        _nomeCertificado = null;
        _bytesCertificado = null;
        _senhaCertificado = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuração fiscal salva com sucesso.'),
          backgroundColor: Colors.green,
        ),
      );
    } on NfceException catch (e) {
      _mostrarErro(e.message);
    } catch (e) {
      _mostrarErro('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _abrirInutilizacao() {
    final sec = SecurityMatrix.current();
    if (!sec.canManageFiscalEvents) {
      _mostrarErro(
          'A inutilização está disponível apenas para perfis FISCAL/ADMIN.');
      return;
    }

    final empresaId = TenantContext.empresaId;
    if (empresaId == null) {
      _mostrarErro('Empresa não identificada.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NfceInutilizacaoScreen(
          empresaId: empresaId,
          uf: _uf,
          ambiente: _ambiente,
        ),
      ),
    );
  }

  void _mostrarErro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Widget _buildEnvironmentBanner() {
    final isProducao = _ambiente == 'PRODUCAO';
    return NfceNoticeBanner(
      icon: isProducao ? Icons.verified_outlined : Icons.warning_amber_rounded,
      backgroundColor:
          isProducao ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3CD),
      borderColor:
          isProducao ? const Color(0xFFA5D6A7) : const Color(0xFFFFD54F),
      textColor: isProducao ? const Color(0xFF1B5E20) : const Color(0xFF7A4B00),
      title: isProducao ? 'Produção NFC-e' : 'Homologação NFC-e',
      message: isProducao
          ? 'Ambiente de produção ativo. Revise UF, CSC, certificado e prazo de cancelamento antes de operar o PDV.'
          : 'Ambiente de homologação ativo. Use este fluxo para testes, validações de inutilização e contingência.',
    );
  }

  Widget _buildSefazBanner() {
    if (_verificandoSefaz) {
      return NfceNoticeBanner(
        icon: Icons.sync,
        backgroundColor: GridColors.selectedRow,
        borderColor: const Color(0xFF90CAF9),
        textColor: const Color(0xFF0D47A1),
        title: 'Verificando SEFAZ',
        message:
            'Consultando a saúde da SEFAZ para UF $_uf no ambiente $_ambiente.',
        trailing: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_sefazHealth == null) {
      return NfceNoticeBanner(
        icon: Icons.network_check,
        backgroundColor: const Color(0xFFEAF4FF),
        borderColor: const Color(0xFFB6D4FE),
        textColor: const Color(0xFF0B5CAD),
        title: 'Saúde da SEFAZ',
        message:
            'Valide certificado e conectividade do ambiente antes de emitir, cancelar ou regularizar vendas em contingência.',
        trailing: TextButton.icon(
          onPressed: _verificandoSefaz ? null : _verificarSefaz,
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF0B5CAD)),
          icon: const Icon(Icons.refresh),
          label: const Text('Verificar'),
        ),
      );
    }

    final online = _sefazHealth!.disponivel;
    return NfceNoticeBanner(
      icon: online ? Icons.check_circle_outline : Icons.error_outline,
      backgroundColor:
          online ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
      borderColor: online ? const Color(0xFFA5D6A7) : const Color(0xFFEF9A9A),
      textColor: online ? const Color(0xFF1B5E20) : GridColors.error,
      title: online ? 'SEFAZ disponível' : 'SEFAZ indisponível',
      message: _sefazHealth!.mensagem,
      trailing: TextButton.icon(
        onPressed: _verificandoSefaz ? null : _verificarSefaz,
        style: TextButton.styleFrom(
          foregroundColor: online ? const Color(0xFF1B5E20) : GridColors.error,
        ),
        icon: const Icon(Icons.refresh),
        label: const Text('Reverificar'),
      ),
    );
  }

  Widget _buildEventosCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Eventos fiscais do épico',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: GridColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'A inutilização já pode ser iniciada pelo app. Cancelamento fica disponível na NFC-e autorizada. Contingência local está pronta; o registro real em EPEC continua dependente do backend.',
              style: TextStyle(height: 1.35),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: _abrirInutilizacao,
                  icon: const Icon(Icons.block),
                  label: const Text('Abrir inutilização'),
                ),
                OutlinedButton.icon(
                  onPressed: _verificandoSefaz ? null : _verificarSefaz,
                  icon: const Icon(Icons.health_and_safety_outlined),
                  label: const Text('Validar saúde da SEFAZ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração Fiscal NFC-e'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEnvironmentBanner(),
                  const SizedBox(height: 12),
                  _buildSefazBanner(),
                  const SizedBox(height: 12),
                  _buildEventosCard(),
                  const SizedBox(height: 16),
                  const _SectionTitle(title: 'Identificação'),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: TenantContext.empresaId?.toString() ?? '—',
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Empresa (ID)',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.lock_outline, size: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildClienteField(),
                  const SizedBox(height: 12),
                  _buildEscopoBanner(),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _uf,
                    decoration: const InputDecoration(
                      labelText: 'UF',
                      border: OutlineInputBorder(),
                    ),
                    items: _ufs
                        .map((uf) =>
                            DropdownMenuItem(value: uf, child: Text(uf)))
                        .toList(),
                    onChanged: _camposFiscaisEditaveis
                        ? (v) => setState(() => _uf = v ?? 'SP')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _ambiente,
                    decoration: const InputDecoration(
                      labelText: 'Ambiente',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'HOMOLOGACAO', child: Text('Homologação')),
                      DropdownMenuItem(
                          value: 'PRODUCAO', child: Text('Produção')),
                    ],
                    onChanged: _camposFiscaisEditaveis
                        ? (v) => setState(() => _ambiente = v ?? 'HOMOLOGACAO')
                        : null,
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(
                      title: 'CSC (Código de Segurança do Contribuinte)'),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: ValueKey('id_csc_$_idCsc'),
                    initialValue: _idCsc,
                    readOnly: !_camposFiscaisEditaveis,
                    decoration: InputDecoration(
                      labelText: 'ID CSC',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_mostrarCsc
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: _camposFiscaisEditaveis
                            ? () => setState(() => _mostrarCsc = !_mostrarCsc)
                            : null,
                      ),
                    ),
                    obscureText: !_mostrarCsc,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Informe o ID CSC.' : null,
                    onSaved: (v) => _idCsc = v?.trim() ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: ValueKey('csc_$_csc'),
                    initialValue: _csc,
                    readOnly: !_camposFiscaisEditaveis,
                    decoration: InputDecoration(
                      labelText: 'CSC',
                      border: const OutlineInputBorder(),
                      // O backend nunca devolve o CSC salvo (segredo write-only).
                      // Quando ja existe configuracao e o campo vem vazio, o
                      // valor esta salvo — so nao pode ser reexibido. Usa
                      // helperText (nao hintText) porque precisa ficar visivel
                      // mesmo sem o campo estar focado.
                      helperText: !_criandoConfigNova && _csc.isEmpty
                          ? 'Já configurado — deixe em branco para manter'
                          : null,
                    ),
                    obscureText: !_mostrarCsc,
                    validator: (v) => (v == null || v.isEmpty) && _criandoConfigNova
                        ? 'Informe o CSC.'
                        : null,
                    onSaved: (v) => _csc = v?.trim() ?? '',
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(title: 'Certificado Digital A1'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: Icon(_nomeCertificado == null &&
                            _certificadoJaSalvo &&
                            !_criandoConfigNova
                        ? Icons.check_circle_outline
                        : Icons.upload_file),
                    label: Text(_nomeCertificado ??
                        (_certificadoJaSalvo && !_criandoConfigNova
                            ? 'Certificado configurado — clique para substituir'
                            : 'Selecionar arquivo .pfx / .p12')),
                    style: _nomeCertificado == null &&
                            _certificadoJaSalvo &&
                            !_criandoConfigNova
                        ? OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1B5E20))
                        : null,
                    onPressed:
                        _camposFiscaisEditaveis ? _selecionarCertificado : null,
                  ),
                  if (_nomeCertificado != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Arquivo selecionado: $_nomeCertificado',
                      style: const TextStyle(
                          color: GridColors.secondary, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    // Sem key/initialValue, o Flutter reaproveita o Element
                    // interno no rebuild e o TextEditingController mantem o
                    // ultimo texto digitado na tela mesmo apos _salvar()
                    // zerar _senhaCertificado — a senha ficaria visivel na
                    // tela mesmo com o estado Dart ja limpo.
                    key: ValueKey('senha_cert_$_senhaCertificado'),
                    initialValue: _senhaCertificado,
                    readOnly: !_camposFiscaisEditaveis,
                    obscureText: !_mostrarSenha,
                    decoration: InputDecoration(
                      labelText: 'Senha do certificado',
                      hintText: 'Nunca é armazenada em texto puro',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_mostrarSenha
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: _camposFiscaisEditaveis
                            ? () =>
                                setState(() => _mostrarSenha = !_mostrarSenha)
                            : null,
                      ),
                    ),
                    onChanged: (v) => _senhaCertificado = v,
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(title: 'NFC-e'),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: ValueKey('serie_$_serie'),
                    initialValue: _serie,
                    readOnly: !_camposFiscaisEditaveis,
                    decoration: const InputDecoration(
                      labelText: 'Série NFC-e',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Informe a série.' : null,
                    onSaved: (v) => _serie = v?.trim() ?? '001',
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    key: const Key('nfce_contingencia_habilitada_switch'),
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.warning_amber_rounded),
                    title: const Text('Permitir contingencia'),
                    subtitle: const Text('Usar contingencia quando a SEFAZ estiver indisponivel.'),
                    value: _contingenciaHabilitada,
                    onChanged: _camposFiscaisEditaveis
                        ? (value) => setState(() => _contingenciaHabilitada = value)
                        : null,
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        icon: _verificandoSefaz
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.network_check),
                        label: const Text('Verificar SEFAZ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _verificandoSefaz ? null : _verificarSefaz,
                      ),
                      OutlinedButton.icon(
                        onPressed: _abrirInutilizacao,
                        icon: const Icon(Icons.block),
                        label: const Text('Inutilização'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _salvando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Salvar configuração'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GridColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _salvando ? null : _salvar,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: GridColors.secondary,
          ),
        ),
        const Divider(),
      ],
    );
  }
}
