import 'package:flutter/material.dart';

import '../../models/defaults_importacao_empresa_model.dart';
import '../../services/defaults_importacao_service.dart';
import '../../utils/dropdown_helpers.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';
import '../../widgets/searchable_dropdown.dart';

const _primary = GridColors.primary;
const _green = GridColors.secondary;
const _bg = Color(0xFFF5F5F5);
const _white = Colors.white;

/// Tela "Defaults de Importação" (Sistema > Config de Sistemas).
///
/// Configura, por empresa, a conta bancária/caixa e o centro de custo
/// padrão usados quando um arquivo de importação SINTEGRA/SPED vier
/// incompleto, além do toggle de baixa automática na data de vencimento.
class DefaultsImportacaoScreen extends StatefulWidget {
  final DefaultsImportacaoService? service;

  const DefaultsImportacaoScreen({super.key, this.service});

  @override
  State<DefaultsImportacaoScreen> createState() =>
      _DefaultsImportacaoScreenState();
}

class _DefaultsImportacaoScreenState extends State<DefaultsImportacaoScreen> {
  late final DefaultsImportacaoService _service =
      widget.service ?? DefaultsImportacaoService();

  List<Map<String, dynamic>> _empresas = [];
  List<Map<String, dynamic>> _contasBancarias = [];
  List<Map<String, dynamic>> _contasCaixa = [];
  List<Map<String, dynamic>> _centrosCusto = [];

  String? _empresaId;
  DefaultsImportacaoEmpresa _defaults = const DefaultsImportacaoEmpresa();

  bool _carregandoEmpresas = true;
  bool _carregandoDefaults = false;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarEmpresas();
  }

  Future<void> _carregarEmpresas() async {
    setState(() {
      _carregandoEmpresas = true;
      _erro = null;
    });
    try {
      final empresaLogada = TenantContext.empresaId?.toString();
      if (empresaLogada != null) {
        final label = await DropdownHelpers.empresaLabelPorId(empresaLogada);
        if (label != null) {
          if (!mounted) return;
          setState(() {
            _empresas = [
              {'id': int.parse(empresaLogada), 'nome': label}
            ];
          });
          await _selecionarEmpresa(empresaLogada);
          if (!mounted) return;
          setState(() {
            _carregandoEmpresas = false;
          });
          return;
        }
      }
      final empresas = await _service.empresas();
      if (!mounted) return;
      setState(() {
        _empresas = empresas;
        _carregandoEmpresas = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregandoEmpresas = false;
        _erro = 'Falha ao carregar empresas: $e';
      });
    }
  }

  Future<void> _selecionarEmpresa(String? empresaId) async {
    setState(() {
      _empresaId = empresaId;
      _defaults = DefaultsImportacaoEmpresa.vazio(
          empresaId != null ? int.tryParse(empresaId) : null);
      _contasBancarias = [];
      _contasCaixa = [];
      _centrosCusto = [];
      _erro = null;
    });
    if (empresaId == null || empresaId.isEmpty) return;

    setState(() => _carregandoDefaults = true);
    try {
      final empresaIdInt = int.parse(empresaId);
      final resultados = await Future.wait([
        _service.buscar(empresaIdInt),
        _service.contasBancarias(empresaId),
        _service.contasCaixa(empresaId),
        _service.centrosCusto(empresaId),
      ]);
      if (!mounted) return;
      setState(() {
        _defaults = resultados[0] as DefaultsImportacaoEmpresa;
        _contasBancarias = resultados[1] as List<Map<String, dynamic>>;
        _contasCaixa = resultados[2] as List<Map<String, dynamic>>;
        _centrosCusto = resultados[3] as List<Map<String, dynamic>>;
        _carregandoDefaults = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregandoDefaults = false;
        _erro = 'Falha ao carregar defaults da empresa: $e';
      });
    }
  }

  Future<void> _salvar() async {
    final empresaId = _empresaId;
    if (empresaId == null || empresaId.isEmpty) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final salvo = await _service.salvar(int.parse(empresaId), _defaults);
      if (!mounted) return;
      setState(() {
        _defaults = salvo;
        _salvando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Defaults de importação salvos com sucesso.'),
          backgroundColor: _green));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = 'Falha ao salvar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: _white,
        elevation: 2,
        title: const Row(children: [
          Icon(Icons.account_balance_wallet_outlined, size: 20),
          SizedBox(width: 8),
          Text('Defaults de Importação',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
      ),
      body: _carregandoEmpresas
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                          'Defaults financeiros usados quando um arquivo '
                          'de importação SINTEGRA/SPED vier com dados '
                          'incompletos: o dado do arquivo sempre tem '
                          'prioridade sobre o default configurado aqui.',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 16),
                      if (_erro != null) ...[
                        _erroBanner(_erro!),
                        const SizedBox(height: 12),
                      ],
                      SearchableDropdownField(
                        key: const Key('defaults_importacao_empresa'),
                        label: 'Empresa',
                        value: _empresaId,
                        items: _empresas,
                        valueField: 'id',
                        displayField: 'nome',
                        isRequired: true,
                        onChanged: (v) => _selecionarEmpresa(v),
                        onSearch: (q) async {
                          final pagina = await DropdownHelpers.empresasBusca(
                              busca: q, pagina: 0, tamanho: 50);
                          return pagina.items;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_empresaId == null)
                        const Text(
                            'Selecione uma empresa para configurar os '
                            'defaults de importação.',
                            style: TextStyle(color: Colors.grey))
                      else if (_carregandoDefaults)
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                                child:
                                    CircularProgressIndicator(color: _primary)))
                      else
                        _formulario(),
                    ]),
              ),
            ),
    );
  }

  Widget _erroBanner(String mensagem) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: _primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _primary.withValues(alpha: 0.3))),
      child: Row(children: [
        const Icon(Icons.error_outline, color: _primary, size: 18),
        const SizedBox(width: 8),
        Expanded(
            child: Text(mensagem,
                style: const TextStyle(color: _primary, fontSize: 12))),
      ]),
    );
  }

  /// Aviso de "default órfão": o id salvo não está mais na lista carregada
  /// pelo dropdown (ex: cadastro inativado ou que mudou de tipo/filtro).
  Widget _avisoOrfao(String mensagem) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
        const SizedBox(width: 6),
        Expanded(
            child: Text(mensagem,
                style: const TextStyle(color: Colors.orange, fontSize: 11))),
      ]),
    );
  }

  /// Injeta, quando necessário, um item sintético representando o default
  /// salvo (id + nome vindos do próprio DTO) na lista carregada pelo
  /// dropdown — evita o "default órfão" silencioso: um id salvo que não
  /// está mais na lista atual (ex: conta/centro de custo inativado ou que
  /// mudou de tipo/filtro) faria o [SearchableDropdownField] cair em
  /// "— Selecione —" mesmo havendo um default configurado. Retorna a lista
  /// original quando o id já está presente ou quando não há id/nome salvos.
  List<Map<String, dynamic>> _comFallbackOrfao(
    List<Map<String, dynamic>> itens,
    int? idSalvo,
    String? nomeSalvo,
  ) {
    if (idSalvo == null) return itens;
    final jaPresente =
        itens.any((i) => i['id']?.toString() == idSalvo.toString());
    if (jaPresente) return itens;
    return [
      ...itens,
      {'id': idSalvo.toString(), 'nome': nomeSalvo ?? '(id $idSalvo)'},
    ];
  }

  /// `true` quando o id salvo não está na lista carregada pelo dropdown —
  /// usado para exibir o aviso de "default órfão" abaixo do campo.
  bool _ehOrfao(List<Map<String, dynamic>> itens, int? idSalvo) {
    if (idSalvo == null) return false;
    return !itens.any((i) => i['id']?.toString() == idSalvo.toString());
  }

  Widget _formulario() {
    final orfaoContaBancaria =
        _ehOrfao(_contasBancarias, _defaults.contaBancariaId);
    final orfaoContaCaixa = _ehOrfao(_contasCaixa, _defaults.contaCaixaId);
    final orfaoCentroCusto = _ehOrfao(_centrosCusto, _defaults.centroCustoId);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SearchableDropdownField(
        key: const Key('defaults_importacao_conta_bancaria'),
        label: 'Conta bancária padrão',
        value: _defaults.contaBancariaId?.toString(),
        items: _comFallbackOrfao(_contasBancarias, _defaults.contaBancariaId,
            _defaults.contaBancariaNome),
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        onChanged: (v) => setState(() {
          _defaults = _defaults.copyWith(
            contaBancariaId: v != null ? int.tryParse(v) : null,
            limparContaBancaria: v == null,
          );
        }),
      ),
      if (orfaoContaBancaria)
        _avisoOrfao(
            'Default configurado (${_defaults.contaBancariaNome ?? 'id ${_defaults.contaBancariaId}'}) '
            'não encontrado na lista atual de contas bancárias.'),
      const SizedBox(height: 12),
      SearchableDropdownField(
        key: const Key('defaults_importacao_conta_caixa'),
        label: 'Conta/caixa padrão',
        value: _defaults.contaCaixaId?.toString(),
        items: _comFallbackOrfao(
            _contasCaixa, _defaults.contaCaixaId, _defaults.contaCaixaNome),
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        onChanged: (v) => setState(() {
          _defaults = _defaults.copyWith(
            contaCaixaId: v != null ? int.tryParse(v) : null,
            limparContaCaixa: v == null,
          );
        }),
      ),
      if (orfaoContaCaixa)
        _avisoOrfao(
            'Default configurado (${_defaults.contaCaixaNome ?? 'id ${_defaults.contaCaixaId}'}) '
            'não encontrado na lista atual de contas/caixa.'),
      const SizedBox(height: 12),
      SearchableDropdownField(
        key: const Key('defaults_importacao_centro_custo'),
        label: 'Centro de custo padrão',
        value: _defaults.centroCustoId?.toString(),
        items: _comFallbackOrfao(
            _centrosCusto, _defaults.centroCustoId, _defaults.centroCustoNome),
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        onChanged: (v) => setState(() {
          _defaults = _defaults.copyWith(
            centroCustoId: v != null ? int.tryParse(v) : null,
            limparCentroCusto: v == null,
          );
        }),
      ),
      if (orfaoCentroCusto)
        _avisoOrfao(
            'Default configurado (${_defaults.centroCustoNome ?? 'id ${_defaults.centroCustoId}'}) '
            'não encontrado na lista atual de centros de custo.'),
      const SizedBox(height: 8),
      SwitchListTile(
        key: const Key('defaults_importacao_baixar_automatico'),
        contentPadding: EdgeInsets.zero,
        activeColor: _primary,
        title: const Text('Baixar automaticamente na data de vencimento',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: const Text(
            'Aplica a baixa/pagamento na própria data de vencimento quando '
            'faltar dado financeiro de baixa no arquivo importado.',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
        value: _defaults.baixarAutomaticoNoVencimento,
        onChanged: (v) => setState(() =>
            _defaults = _defaults.copyWith(baixarAutomaticoNoVencimento: v)),
      ),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          key: const Key('defaults_importacao_salvar'),
          onPressed: _salvando ? null : _salvar,
          icon: _salvando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: _white))
              : const Icon(Icons.save),
          label: Text(_salvando ? 'Salvando...' : 'Salvar'),
          style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: _white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
        ),
      ),
    ]);
  }
}
