import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/grid_colors.dart';
import '../utils/tenant_context.dart';
import 'searchable_dropdown.dart';

class ReprocessarNfeReceitaCard extends StatefulWidget {
  final String baseUrl;

  const ReprocessarNfeReceitaCard({
    super.key,
    required this.baseUrl,
  });

  @override
  State<ReprocessarNfeReceitaCard> createState() =>
      _ReprocessarNfeReceitaCardState();
}

class _ReprocessarNfeReceitaCardState extends State<ReprocessarNfeReceitaCard> {
  List<Map<String, dynamic>> _empresas = [];
  List<Map<String, dynamic>> _parceiros = [];

  String? _empresaId;
  String? _parceiroId;
  int _limite = 50;

  bool _loadingEmpresas = false;
  bool _loadingParceiros = false;
  bool _executando = false;

  Map<String, dynamic>? _resultado;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarEmpresas();
  }

  Future<void> _carregarEmpresas() async {
    setState(() => _loadingEmpresas = true);
    try {
      final resp = await TenantContext.get('${widget.baseUrl}/api/empresa');
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        List lista = [];
        if (body is Map && body['data'] is Map && body['data']['dados'] is List) {
          lista = body['data']['dados'] as List;
        } else if (body is Map && body['data'] is List) {
          lista = body['data'] as List;
        } else if (body is List) {
          lista = body;
        }

        final mapeadas = lista.map<Map<String, dynamic>>((e) {
          final id = e['id']?.toString() ?? '';
          final nome = e['nome']?.toString() ?? e['razaoSocial']?.toString() ?? 'Empresa $id';
          final cnpj = e['cnpj']?.toString() ?? '';
          final display = cnpj.isNotEmpty ? '$nome ($cnpj)' : nome;
          return {
            'id': id,
            'nome': display,
          };
        }).toList();

        if (mounted) {
          setState(() {
            _empresas = mapeadas;
            if (_empresaId == null && _empresas.isNotEmpty) {
              if (TenantContext.hasEmpresa) {
                final ctxEmp = TenantContext.empresaId.toString();
                if (_empresas.any((emp) => emp['id'] == ctxEmp)) {
                  _empresaId = ctxEmp;
                  _carregarParceiros(_empresaId!);
                }
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar empresas: $e');
    } finally {
      if (mounted) setState(() => _loadingEmpresas = false);
    }
  }

  Future<void> _carregarParceiros(String empresaId) async {
    setState(() {
      _loadingParceiros = true;
      _parceiros = [];
      _parceiroId = null;
    });

    try {
      var resp = await TenantContext.get('${widget.baseUrl}/api/parceiro/empresa/$empresaId');
      if (resp.statusCode != 200) {
        resp = await TenantContext.get('${widget.baseUrl}/api/parceiro?empresaId=$empresaId');
      }

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        List lista = [];
        if (body is Map && body['data'] is Map && body['data']['dados'] is List) {
          lista = body['data']['dados'] as List;
        } else if (body is Map && body['data'] is List) {
          lista = body['data'] as List;
        } else if (body is List) {
          lista = body;
        }

        final mapeados = lista.map<Map<String, dynamic>>((p) {
          final id = p['id']?.toString() ?? '';
          final nome = p['nome']?.toString() ?? p['razaoSocial']?.toString() ?? 'Parceiro $id';
          final doc = p['cnpjCpf']?.toString() ?? p['cnpj']?.toString() ?? p['cpf']?.toString() ?? '';
          final display = doc.isNotEmpty ? '$nome - $doc' : nome;
          return {
            'id': id,
            'nome': display,
          };
        }).toList();

        if (mounted) {
          setState(() {
            _parceiros = mapeados;
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar parceiros: $e');
    } finally {
      if (mounted) setState(() => _loadingParceiros = false);
    }
  }

  Future<void> _executarReprocessamento() async {
    if (_empresaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Por favor, selecione uma empresa para reprocessar.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() {
      _executando = true;
      _erro = null;
      _resultado = null;
    });

    try {
      final queryParams = <String, String>{
        'empresaId': _empresaId!,
        'limite': _limite.toString(),
      };
      if (_parceiroId != null && _parceiroId!.isNotEmpty) {
        queryParams['parceiroId'] = _parceiroId!;
      }

      final uri = Uri.parse('${widget.baseUrl}/api/nfe/receita/reprocessar-incompletas')
          .replace(queryParameters: queryParams);

      final resp = await TenantContext.post(uri.toString(), {});

      if (resp.statusCode == 200) {
        final dados = jsonDecode(resp.body);
        setState(() => _resultado = dados is Map<String, dynamic> ? dados : {});
        if (mounted) {
          final msg = _resultado?['mensagem']?.toString() ?? 'Reprocessamento concluído com sucesso!';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg),
            backgroundColor: GridColors.secondary,
          ));
        }
      } else {
        setState(() {
          _erro = 'Falha HTTP ${resp.statusCode}: ${resp.body}';
        });
      }
    } catch (e) {
      setState(() {
        _erro = 'Erro de conexão: $e';
      });
    } finally {
      if (mounted) setState(() => _executando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: GridColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sync_problem_outlined,
                      color: GridColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Regerar / Enriquecer NF-es Incompletas da Receita (SEFAZ)',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: GridColors.primary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Seleciona a empresa e o cliente/parceiro para identificar notas de entrada importadas sem itens (resumos da SEFAZ), manifestar Ciência da Operação (210210), baixar o XML completo e auto-cadastrar itens, produtos, estoque, tributação e contas a pagar.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Dropdowns de Empresa e Parceiro
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final fields = [
                Expanded(
                  flex: 3,
                  child: SearchableDropdownField(
                    label: 'Empresa',
                    value: _empresaId,
                    items: _empresas,
                    valueField: 'id',
                    displayField: 'nome',
                    hintText: _loadingEmpresas
                        ? 'Carregando empresas...'
                        : 'Selecione a empresa...',
                    enabled: !_executando && !_loadingEmpresas,
                    onChanged: (val) {
                      setState(() {
                        _empresaId = val;
                      });
                      if (val != null) {
                        _carregarParceiros(val);
                      } else {
                        setState(() {
                          _parceiros = [];
                          _parceiroId = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: SearchableDropdownField(
                    label: 'Cliente / Parceiro (Destinatário)',
                    value: _parceiroId,
                    items: _parceiros,
                    valueField: 'id',
                    displayField: 'nome',
                    nullable: true,
                    nullLabel: 'Todos os parceiros da empresa',
                    hintText: _empresaId == null
                        ? 'Selecione uma empresa primeiro'
                        : _loadingParceiros
                            ? 'Carregando parceiros...'
                            : 'Todos os parceiros (opcional)',
                    enabled: !_executando &&
                        _empresaId != null &&
                        !_loadingParceiros,
                    onChanged: (val) {
                      setState(() => _parceiroId = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<int>(
                    value: _limite,
                    decoration: InputDecoration(
                      labelText: 'Qtd. Máx.',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 20, child: Text('20 notas')),
                      DropdownMenuItem(value: 50, child: Text('50 notas')),
                      DropdownMenuItem(value: 100, child: Text('100 notas')),
                      DropdownMenuItem(value: 200, child: Text('200 notas')),
                    ],
                    onChanged: _executando
                        ? null
                        : (v) => setState(() => _limite = v ?? 50),
                  ),
                ),
              ];

              if (isWide) {
                return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: fields);
              } else {
                return Column(
                  children: [
                    SearchableDropdownField(
                      label: 'Empresa',
                      value: _empresaId,
                      items: _empresas,
                      valueField: 'id',
                      displayField: 'nome',
                      hintText: _loadingEmpresas
                          ? 'Carregando empresas...'
                          : 'Selecione a empresa...',
                      enabled: !_executando && !_loadingEmpresas,
                      onChanged: (val) {
                        setState(() => _empresaId = val);
                        if (val != null) {
                          _carregarParceiros(val);
                        } else {
                          setState(() {
                            _parceiros = [];
                            _parceiroId = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SearchableDropdownField(
                      label: 'Cliente / Parceiro (Destinatário)',
                      value: _parceiroId,
                      items: _parceiros,
                      valueField: 'id',
                      displayField: 'nome',
                      nullable: true,
                      nullLabel: 'Todos os parceiros da empresa',
                      hintText: _empresaId == null
                          ? 'Selecione uma empresa primeiro'
                          : _loadingParceiros
                              ? 'Carregando parceiros...'
                              : 'Todos os parceiros (opcional)',
                      enabled: !_executando &&
                          _empresaId != null &&
                          !_loadingParceiros,
                      onChanged: (val) {
                        setState(() => _parceiroId = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _limite,
                      decoration: InputDecoration(
                        labelText: 'Quantidade Máxima',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 20, child: Text('20 notas')),
                        DropdownMenuItem(value: 50, child: Text('50 notas')),
                        DropdownMenuItem(value: 100, child: Text('100 notas')),
                        DropdownMenuItem(value: 200, child: Text('200 notas')),
                      ],
                      onChanged: _executando
                          ? null
                          : (v) => setState(() => _limite = v ?? 50),
                    ),
                  ],
                );
              }
            }),

            const SizedBox(height: 16),

            // Botão Executar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_executando) ...[
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  const Text('Consultando SEFAZ e enriquecendo notas...',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: GridColors.primary)),
                  const SizedBox(width: 16),
                ],
                ElevatedButton.icon(
                  onPressed: (_executando || _empresaId == null)
                      ? null
                      : _executarReprocessamento,
                  icon: const Icon(Icons.sync, size: 18),
                  label: Text(_executando
                      ? 'Processando...'
                      : 'Regerar / Enriquecer NF-es da Receita'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),

            // Exibição de Erro
            if (_erro != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_erro!,
                          style: TextStyle(
                              fontSize: 12, color: Colors.red.shade900)),
                    ),
                  ],
                ),
              ),
            ],

            // Exibição de Resultado
            if (_resultado != null) ...[
              const SizedBox(height: 16),
              _buildResultadoCard(_resultado!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultadoCard(Map<String, dynamic> res) {
    final total = res['totalIncompletas'] ?? 0;
    final sucessos = res['sucessos'] ?? 0;
    final falhas = res['falhas'] ?? 0;
    final msg = res['mensagem']?.toString() ?? '';
    final detalhes = (res['detalhes'] as List?) ?? [];

    final cor = falhas == 0 ? GridColors.secondary : Colors.orange.shade800;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(falhas == 0 ? Icons.check_circle : Icons.warning_amber,
                  color: cor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  msg.isNotEmpty ? msg : 'Reprocessamento finalizado.',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13, color: cor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _metricBadge('Total Encontradas', total.toString(), Colors.blueGrey),
              const SizedBox(width: 8),
              _metricBadge('Enriquecidas', sucessos.toString(), GridColors.secondary),
              if (falhas > 0) ...[
                const SizedBox(width: 8),
                _metricBadge('Falhas/Aguardando', falhas.toString(), Colors.red),
              ],
            ],
          ),
          if (detalhes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Detalhamento das notas processadas:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: detalhes.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final it = detalhes[index] as Map<String, dynamic>;
                  final id = it['id'];
                  final numero = it['numero'] ?? 'S/N';
                  final status = it['status'] ?? '';
                  final itens = it['itens'] ?? 0;
                  final valor = it['valorTotal'] != null
                      ? 'R\$ ${it['valorTotal']}'
                      : '';
                  final motivo = it['motivo'] ?? '';

                  final isOk = status == 'SUCESSO';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(isOk ? Icons.check : Icons.close,
                            size: 16,
                            color: isOk ? Colors.green : Colors.red),
                        const SizedBox(width: 6),
                        Text('NF-e #$id ($numero)',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        if (isOk) ...[
                          Text('$itens itens auto-cadastrados, estoque e financeiro gerados',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade700)),
                          const Spacer(),
                          Text(valor,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ] else ...[
                          Expanded(
                            child: Text(motivo,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.red),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
          Text(value,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
