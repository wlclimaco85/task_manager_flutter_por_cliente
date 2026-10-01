import 'package:flutter/material.dart';

import '../../models/alerta_manual_model.dart';
import '../../services/alertas_manuais_service.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';

class AlertasManuaisScreen extends StatefulWidget {
  final AlertasManuaisRepository? repository;
  final bool? possuiParceiroNoTenant;

  const AlertasManuaisScreen({
    super.key,
    this.repository,
    this.possuiParceiroNoTenant,
  });

  @override
  State<AlertasManuaisScreen> createState() => _AlertasManuaisScreenState();
}

class _AlertasManuaisScreenState extends State<AlertasManuaisScreen> {
  late final AlertasManuaisRepository _repository;
  final TextEditingController _mensagemController = TextEditingController();
  final TextEditingController _buscaParceiroController =
      TextEditingController();
  final Set<int> _parceirosSelecionados = {};

  bool _carregando = true;
  bool _enviando = false;
  String? _erro;
  List<AlertaManual> _alertas = [];
  List<ParceiroAlertaOpcao> _parceiros = [];

  bool get _possuiParceiro =>
      widget.possuiParceiroNoTenant ?? TenantContext.hasParceiro;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? AlertasManuaisService();
    _carregar();
  }

  @override
  void dispose() {
    _mensagemController.dispose();
    _buscaParceiroController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final resultados = await Future.wait([
        _repository.listar(),
        if (!_possuiParceiro) _repository.listarParceiros(),
      ]);
      if (!mounted) return;
      setState(() {
        _alertas = resultados[0] as List<AlertaManual>;
        _parceiros = _possuiParceiro
            ? <ParceiroAlertaOpcao>[]
            : resultados[1] as List<ParceiroAlertaOpcao>;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString();
        _carregando = false;
      });
    }
  }

  Future<void> _enviar() async {
    final texto = _mensagemController.text.trim();
    if (texto.isEmpty) {
      _mostrarMensagem('Informe a mensagem do alerta.');
      return;
    }

    if (_parceirosSelecionados.isEmpty && !_possuiParceiro) {
      final confirmado = await _confirmarEnvioParaTodos();
      if (confirmado != true) return;
    }

    setState(() => _enviando = true);
    try {
      final resultado = await _repository.disparar(
        texto: texto,
        parceiroIds: _parceirosSelecionados.toList(),
      );
      if (!mounted) return;
      _mostrarMensagem(
          'Alerta enviado para ${resultado.destinatarios} destinatario(s).');
      _mensagemController.clear();
      setState(() {
        _parceirosSelecionados.clear();
      });
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      _mostrarMensagem(e.toString());
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  Future<bool?> _confirmarEnvioParaTodos() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar para todos os clientes?'),
        content: const Text(
          'Nenhum parceiro foi selecionado. O alerta sera enviado para todos os clientes ativos da empresa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nao'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: GridColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sim'),
          ),
        ],
      ),
    );
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  void _alternarTodos() {
    setState(() {
      if (_parceirosSelecionados.length == _parceiros.length) {
        _parceirosSelecionados.clear();
      } else {
        _parceirosSelecionados
          ..clear()
          ..addAll(_parceiros.map((p) => p.id));
      }
    });
  }

  List<ParceiroAlertaOpcao> get _parceirosFiltrados {
    final busca = _buscaParceiroController.text.trim().toLowerCase();
    if (busca.isEmpty) return _parceiros;
    return _parceiros.where((p) {
      return p.nome.toLowerCase().contains(busca) ||
          (p.documento ?? '').toLowerCase().contains(busca);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      body: SafeArea(
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : _erro != null
                ? _ErroState(erro: _erro!, onRetry: _carregar)
                : RefreshIndicator(
                    onRefresh: _carregar,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compacto = constraints.maxWidth < 820;
                        final children = [
                          if (!_possuiParceiro)
                            _FormularioAlerta(
                              mensagemController: _mensagemController,
                              buscaController: _buscaParceiroController,
                              parceiros: _parceirosFiltrados,
                              selecionados: _parceirosSelecionados,
                              todosSelecionados:
                                  _parceirosSelecionados.length ==
                                          _parceiros.length &&
                                      _parceiros.isNotEmpty,
                              enviando: _enviando,
                              onEnviar: _enviar,
                              onToggleTodos: _alternarTodos,
                              onParceiroChanged: (id, selected) {
                                setState(() {
                                  selected
                                      ? _parceirosSelecionados.add(id)
                                      : _parceirosSelecionados.remove(id);
                                });
                              },
                              onBuscaChanged: () => setState(() {}),
                            ),
                          _ListaAlertas(alertas: _alertas),
                        ];
                        return ListView(
                          padding: EdgeInsets.all(compacto ? 12 : 20),
                          children: [
                            _Header(onRefresh: _carregar),
                            const SizedBox(height: 12),
                            if (compacto)
                              ...children.map((w) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: w,
                                  ))
                            else
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!_possuiParceiro) ...[
                                    Expanded(flex: 5, child: children.first),
                                    const SizedBox(width: 16),
                                    Expanded(flex: 7, child: children.last),
                                  ] else
                                    Expanded(child: children.last),
                                ],
                              ),
                          ],
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onRefresh;

  const _Header({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.notifications_active_outlined,
            color: GridColors.primary),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Alertas',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: GridColors.textSecondary,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Atualizar',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _FormularioAlerta extends StatelessWidget {
  final TextEditingController mensagemController;
  final TextEditingController buscaController;
  final List<ParceiroAlertaOpcao> parceiros;
  final Set<int> selecionados;
  final bool todosSelecionados;
  final bool enviando;
  final VoidCallback onEnviar;
  final VoidCallback onToggleTodos;
  final VoidCallback onBuscaChanged;
  final void Function(int id, bool selected) onParceiroChanged;

  const _FormularioAlerta({
    required this.mensagemController,
    required this.buscaController,
    required this.parceiros,
    required this.selecionados,
    required this.todosSelecionados,
    required this.enviando,
    required this.onEnviar,
    required this.onToggleTodos,
    required this.onBuscaChanged,
    required this.onParceiroChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _Painel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Novo alerta',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: mensagemController,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Mensagem',
              hintText: 'Ex.: Por favor mande o extrato bancario',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Parceiros (${selecionados.length})',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                onPressed: parceiros.isEmpty ? null : onToggleTodos,
                icon: Icon(todosSelecionados
                    ? Icons.check_box_outline_blank
                    : Icons.done_all),
                label: Text(
                    todosSelecionados ? 'Desmarcar todos' : 'Marcar todos'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: buscaController,
            onChanged: (_) => onBuscaChanged(),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Buscar parceiro',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: parceiros.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Nenhum parceiro encontrado'),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: parceiros.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final parceiro = parceiros[index];
                      return Material(
                        color: Colors.transparent,
                        child: CheckboxListTile(
                          dense: true,
                          value: selecionados.contains(parceiro.id),
                          activeColor: GridColors.secondary,
                          onChanged: (value) =>
                              onParceiroChanged(parceiro.id, value == true),
                          title: Text(
                            parceiro.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: parceiro.documento == null
                              ? null
                              : Text(
                                  parceiro.documento!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: enviando ? null : onEnviar,
              icon: enviando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(enviando ? 'Enviando...' : 'Enviar alerta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListaAlertas extends StatelessWidget {
  final List<AlertaManual> alertas;

  const _ListaAlertas({required this.alertas});

  @override
  Widget build(BuildContext context) {
    return _Painel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alertas enviados (${alertas.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (alertas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Nenhum alerta encontrado')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alertas.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final alerta = alertas[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: GridColors.primarySoft,
                    child: Icon(
                      alerta.status.toUpperCase() == 'NOVO'
                          ? Icons.notifications_active_outlined
                          : Icons.done,
                      color: GridColors.primary,
                    ),
                  ),
                  title: Text(alerta.texto),
                  subtitle: Text([
                    if ((alerta.parceiroNome ?? '').isNotEmpty)
                      alerta.parceiroNome!,
                    if ((alerta.data ?? '').isNotEmpty) alerta.data!,
                  ].join(' - ')),
                  trailing: Text(
                    alerta.status,
                    style: const TextStyle(
                      color: GridColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Painel extends StatelessWidget {
  final Widget child;

  const _Painel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GridColors.card,
        border: Border.all(color: GridColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class _ErroState extends StatelessWidget {
  final String erro;
  final VoidCallback onRetry;

  const _ErroState({required this.erro, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: GridColors.error, size: 42),
            const SizedBox(height: 10),
            Text(erro, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
