import 'package:flutter/material.dart';

import '../../models/regua_cobranca_model.dart';
import '../../services/regua_cobranca_service.dart';

class CobrancaAutomaticaScreen extends StatefulWidget {
  const CobrancaAutomaticaScreen({super.key, this.service});

  final ReguaCobrancaService? service;

  @override
  State<CobrancaAutomaticaScreen> createState() =>
      _CobrancaAutomaticaScreenState();
}

class _CobrancaAutomaticaScreenState extends State<CobrancaAutomaticaScreen>
    with SingleTickerProviderStateMixin {
  late final ReguaCobrancaService _service;
  late final TabController _tabs;
  List<ReguaCobranca> _reguas = const [];
  List<CobrancaRegua> _pendencias = const [];
  List<CobrancaRegua> _fila = const [];
  List<CobrancaRegua> _historico = const [];
  PainelReguaCobranca? _painel;
  bool _loading = true;
  bool _executando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ReguaCobrancaService();
    _tabs = TabController(length: 4, vsync: this);
    _carregar();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final resultados = await Future.wait([
        _service.listarReguas(),
        _service.listarPendencias(),
        _service.listarFila(),
        _service.listarHistorico(),
        _service.carregarPainel(),
      ]);
      if (!mounted) return;
      setState(() {
        _reguas = List<ReguaCobranca>.from(resultados[0] as List<ReguaCobranca>)
          ..sort((a, b) => a.ordem.compareTo(b.ordem));
        _pendencias = resultados[1] as List<CobrancaRegua>;
        _fila = resultados[2] as List<CobrancaRegua>;
        _historico = resultados[3] as List<CobrancaRegua>;
        _painel = resultados[4] as PainelReguaCobranca;
      });
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editar([ReguaCobranca? regua]) async {
    final salva = await showDialog<ReguaCobranca>(
      context: context,
      builder: (_) =>
          _EtapaDialog(regua: regua, proximaOrdem: _reguas.length + 1),
    );
    if (salva == null) return;
    setState(() => _loading = true);
    try {
      await _service.salvarRegua(salva);
      if (!mounted) return;
      _mensagem('Etapa salva com sucesso.');
      await _carregar();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _mensagem(e.toString(), erro: true);
      }
    }
  }

  Future<void> _executar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Executar régua agora?'),
        content: const Text(
          'Os títulos vencidos serão avaliados e os envios elegíveis serão enfileirados. Duplicidades serão ignoradas.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Executar')),
        ],
      ),
    );
    if (confirmado != true) return;
    setState(() => _executando = true);
    try {
      final resultado = await _service.executar();
      if (!mounted) return;
      _mensagem(
        '${resultado.titulosAvaliados} títulos avaliados, '
        '${resultado.enviosEnfileirados} envios enfileirados e '
        '${resultado.duplicadosIgnorados} duplicidades ignoradas.',
      );
      await _carregar();
    } catch (e) {
      if (mounted) _mensagem(e.toString(), erro: true);
    } finally {
      if (mounted) setState(() => _executando = false);
    }
  }

  void _mensagem(String texto, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: erro ? Colors.red.shade700 : Colors.green.shade700,
    ));
  }

  Future<void> _reprocessar(CobrancaRegua item) async {
    try {
      await _service.reprocessar(item.id);
      if (!mounted) return;
      _mensagem('Envio reenfileirado para processamento.');
      await _carregar();
    } catch (e) {
      if (mounted) _mensagem(e.toString(), erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _cabecalho(),
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabs,
            isScrollable: MediaQuery.sizeOf(context).width < 600,
            tabs: [
              Tab(text: 'Etapas (${_reguas.length})'),
              Tab(text: 'Pendências (${_pendencias.length})'),
              Tab(text: 'Fila (${_fila.length})'),
              Tab(text: 'Histórico (${_historico.length})'),
            ],
          ),
        ),
        Expanded(child: _conteudo()),
      ],
    );
  }

  Widget _cabecalho() {
    final size = MediaQuery.sizeOf(context);
    final compacto = size.width < 700;
    final alturaBaixa = size.height < 700;
    final botoes = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
            onPressed: _loading ? null : _carregar,
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar')),
        FilledButton.tonalIcon(
            onPressed: _loading ? null : () => _editar(),
            icon: const Icon(Icons.add),
            label: const Text('Nova etapa')),
        FilledButton.icon(
          onPressed: _loading || _executando ? null : _executar,
          icon: _executando
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.play_arrow),
          label: const Text('Executar agora'),
        ),
      ],
    );
    final conteudo = compacto
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _Titulo(),
            if (_painel != null) ...[
              const SizedBox(height: 12),
              _PainelResumo(painel: _painel!),
            ],
            const SizedBox(height: 12),
            botoes,
          ])
        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Expanded(child: _Titulo()), botoes]),
            if (_painel != null) ...[
              const SizedBox(height: 12),
              _PainelResumo(painel: _painel!),
            ],
          ]);
    return Container(
      width: double.infinity,
      constraints: alturaBaixa ? const BoxConstraints(maxHeight: 220) : null,
      padding: EdgeInsets.all(alturaBaixa ? 10 : 16),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: alturaBaixa ? SingleChildScrollView(child: conteudo) : conteudo,
    );
  }

  Widget _conteudo() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_erro != null) {
      return _EstadoVazio(
        icon: Icons.cloud_off,
        titulo: 'Não foi possível carregar a régua',
        descricao: _erro!,
        acao: TextButton.icon(
            onPressed: _carregar,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente')),
      );
    }
    return TabBarView(
      controller: _tabs,
      children: [
        _reguas.isEmpty
            ? const _EstadoVazio(
                icon: Icons.rule,
                titulo: 'Nenhuma etapa configurada',
                descricao:
                    'Crie a primeira etapa para iniciar sua régua de cobrança.')
            : _listaEtapas(),
        _pendencias.isEmpty
            ? const _EstadoVazio(
                icon: Icons.task_alt,
                titulo: 'Nenhuma pendência',
                descricao: 'Não há títulos vencidos aguardando ação.')
            : _listaCobrancas(_pendencias, historico: false),
        _fila.isEmpty
            ? const _EstadoVazio(
                icon: Icons.outgoing_mail,
                titulo: 'Fila vazia',
                descricao:
                    'Não há envios pendentes, em retry ou indisponíveis.')
            : _listaCobrancas(_fila, historico: true, fila: true),
        _historico.isEmpty
            ? const _EstadoVazio(
                icon: Icons.history,
                titulo: 'Histórico vazio',
                descricao: 'As execuções da régua aparecerão aqui.')
            : _listaCobrancas(_historico, historico: true),
      ],
    );
  }

  Widget _listaEtapas() => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _reguas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          final etapa = _reguas[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${etapa.ordem}')),
              title: Text(etapa.nome,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(spacing: 8, runSpacing: 6, children: [
                  _Chip(_descricaoOffset(etapa.diasAposVencimento),
                      Icons.calendar_today),
                  _Chip(etapa.canal.label, Icons.outgoing_mail),
                  if (etapa.somenteDiaUtil)
                    const _Chip('Somente dia útil', Icons.work_outline),
                  if (!etapa.canal.disponivel)
                    const _Chip('Provider indisponível', Icons.block,
                        alerta: true),
                ]),
              ),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Switch(value: etapa.ativo, onChanged: (_) => _editar(etapa)),
                IconButton(
                    onPressed: () => _editar(etapa),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Editar etapa'),
              ]),
            ),
          );
        },
      );

  Widget _listaCobrancas(List<CobrancaRegua> itens,
      {required bool historico, bool fila = false}) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 760) {
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: itens.length,
          itemBuilder: (_, i) => _CobrancaCard(
              cobranca: itens[i],
              historico: historico,
              onReprocessar: fila ? () => _reprocessar(itens[i]) : null),
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: constraints.maxWidth,
          child: DataTable(
            columns: historico
                ? [
                    DataColumn(label: Text('Cliente')),
                    DataColumn(label: Text('Execução')),
                    DataColumn(label: Text('Canal')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Resultado')),
                    if (fila) DataColumn(label: Text('Ação')),
                  ]
                : const [
                    DataColumn(label: Text('Cliente')),
                    DataColumn(label: Text('Valor')),
                    DataColumn(label: Text('Vencimento')),
                    DataColumn(label: Text('Dias em atraso')),
                    DataColumn(label: Text('Status')),
                  ],
            rows: itens.map((item) {
              if (historico) {
                return DataRow(cells: [
                  DataCell(Text(item.clienteNome)),
                  DataCell(Text(_dataHora(item.executadaEm))),
                  DataCell(Text(item.canal?.label ?? item.etapa ?? '-')),
                  DataCell(_Status(texto: item.status)),
                  DataCell(Text(item.resultado ?? '-')),
                  if (fila)
                    DataCell(TextButton(
                      onPressed: () => _reprocessar(item),
                      child: const Text('Reprocessar'),
                    )),
                ]);
              }
              return DataRow(cells: [
                DataCell(Text(item.clienteNome)),
                DataCell(Text(_moeda(item.valor))),
                DataCell(Text(_data(item.vencimento))),
                DataCell(Text(_diasAtraso(item))),
                DataCell(_Status(texto: item.status)),
              ]);
            }).toList(),
          ),
        ),
      );
    });
  }
}

class _EtapaDialog extends StatefulWidget {
  const _EtapaDialog({this.regua, required this.proximaOrdem});
  final ReguaCobranca? regua;
  final int proximaOrdem;

  @override
  State<_EtapaDialog> createState() => _EtapaDialogState();
}

class _EtapaDialogState extends State<_EtapaDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _dias;
  late final TextEditingController _mensagem;
  late final TextEditingController _ordem;
  late CanalCobranca _canal;
  late bool _somenteDiaUtil;
  late bool _ativo;

  @override
  void initState() {
    super.initState();
    final r = widget.regua;
    _nome = TextEditingController(text: r?.nome ?? 'Lembrete de pagamento');
    _dias = TextEditingController(text: '${r?.diasAposVencimento ?? 1}');
    _mensagem = TextEditingController(
        text: r?.mensagem ??
            'Olá, identificamos um pagamento em aberto. Podemos ajudar?');
    _ordem = TextEditingController(text: '${r?.ordem ?? widget.proximaOrdem}');
    _canal = r?.canal ?? CanalCobranca.email;
    _somenteDiaUtil = r?.somenteDiaUtil ?? true;
    _ativo = r?.ativo ?? true;
  }

  @override
  void dispose() {
    _nome.dispose();
    _dias.dispose();
    _mensagem.dispose();
    _ordem.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.regua == null ? 'Nova etapa' : 'Editar etapa'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                  controller: _nome,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: _obrigatorio),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: TextFormField(
                        controller: _dias,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Dias relativos ao vencimento'),
                        validator: _inteiroNaoNegativo)),
                const SizedBox(width: 12),
                Expanded(
                    child: TextFormField(
                        controller: _ordem,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Ordem'),
                        validator: _inteiroPositivo)),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<CanalCobranca>(
                value: _canal,
                decoration: const InputDecoration(labelText: 'Canal'),
                items: CanalCobranca.values
                    .map((canal) => DropdownMenuItem(
                          value: canal,
                          enabled: canal.disponivel,
                          child: Text(canal.disponivel
                              ? canal.label
                              : '${canal.label} (indisponível)'),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _canal = value ?? _canal),
              ),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _mensagem,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Mensagem'),
                  validator: _obrigatorio),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Variáveis: {{cliente}}, {{descricao}}, {{valor}}, {{vencimento}}, {{dias_atraso}}, {{linha_digitavel}}, {{pix_copia_cola}}, {{link_pagamento}}, {{nome_empresa}}, {{contato_empresa}}',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Executar somente em dia útil'),
                  value: _somenteDiaUtil,
                  onChanged: (v) => setState(() => _somenteDiaUtil = v)),
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Etapa ativa'),
                  value: _ativo,
                  onChanged: (v) => setState(() => _ativo = v)),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(onPressed: _salvar, child: const Text('Salvar')),
      ],
    );
  }

  String? _obrigatorio(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;
  String? _inteiroNaoNegativo(String? value) {
    final numero = int.tryParse(value ?? '');
    return numero == null ? 'Informe um número' : null;
  }

  String? _inteiroPositivo(String? value) {
    final numero = int.tryParse(value ?? '');
    return numero == null || numero < 1 ? 'Informe 1 ou mais' : null;
  }

  void _salvar() {
    if (!(_form.currentState?.validate() ?? false)) return;
    Navigator.pop(
        context,
        ReguaCobranca(
          id: widget.regua?.id,
          nome: _nome.text.trim(),
          diasAposVencimento: int.parse(_dias.text),
          canal: _canal,
          mensagem: _mensagem.text.trim(),
          somenteDiaUtil: _somenteDiaUtil,
          ordem: int.parse(_ordem.text),
          ativo: _ativo,
        ));
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo();
  @override
  Widget build(BuildContext context) =>
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Régua de Cobrança',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(
            'Automatize lembretes, acompanhe pendências e preserve o histórico dos contatos.'),
      ]);
}

class _PainelResumo extends StatelessWidget {
  const _PainelResumo({required this.painel});
  final PainelReguaCobranca painel;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ResumoCard('Em aberto', '${painel.titulosEmAberto}'),
            const SizedBox(width: 8),
            _ResumoCard('Valor vencido', _moeda(painel.valorVencido)),
            const SizedBox(width: 8),
            _ResumoCard('A vencer', _moeda(painel.valorAVencer)),
            const SizedBox(width: 8),
            _ResumoCard('Pendentes', '${painel.enviosPendentes}'),
            const SizedBox(width: 8),
            _ResumoCard('Enviados', '${painel.enviosEnviados}'),
            const SizedBox(width: 8),
            _ResumoCard('Falhas', '${painel.enviosFalha}'),
          ],
        ),
      );
}

class _ResumoCard extends StatelessWidget {
  const _ResumoCard(this.label, this.valor);
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 130),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(valor, style: Theme.of(context).textTheme.titleMedium),
        ]),
      );
}

String _descricaoOffset(int dias) {
  if (dias < 0) return '${dias.abs()} dia(s) antes do vencimento';
  if (dias == 0) return 'No vencimento';
  return '$dias dia(s) apos o vencimento';
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio(
      {required this.icon,
      required this.titulo,
      required this.descricao,
      this.acao});
  final IconData icon;
  final String titulo;
  final String descricao;
  final Widget? acao;
  @override
  Widget build(BuildContext context) => Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(titulo,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(descricao, textAlign: TextAlign.center),
          if (acao != null) ...[const SizedBox(height: 10), acao!],
        ]),
      ));
}

class _Chip extends StatelessWidget {
  const _Chip(this.texto, this.icon, {this.alerta = false});
  final String texto;
  final IconData icon;
  final bool alerta;
  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(icon, size: 15),
        label: Text(texto),
        backgroundColor: alerta ? Colors.orange.shade50 : null,
      );
}

class _Status extends StatelessWidget {
  const _Status({required this.texto});
  final String texto;
  @override
  Widget build(BuildContext context) =>
      Chip(label: Text(texto), visualDensity: VisualDensity.compact);
}

class _CobrancaCard extends StatelessWidget {
  const _CobrancaCard(
      {required this.cobranca, required this.historico, this.onReprocessar});
  final CobrancaRegua cobranca;
  final bool historico;
  final VoidCallback? onReprocessar;
  @override
  Widget build(BuildContext context) => Card(
          child: ListTile(
        title: Text(cobranca.clienteNome,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${_moeda(cobranca.valor)} • vencimento ${_data(cobranca.vencimento)}\n${historico ? (cobranca.canal?.label ?? cobranca.etapa ?? '-') : _diasAtraso(cobranca)}'),
        isThreeLine: true,
        trailing: onReprocessar == null
            ? _Status(texto: cobranca.status)
            : TextButton(
                onPressed: onReprocessar,
                child: const Text('Reprocessar'),
              ),
      ));
}

String _moeda(double valor) =>
    'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
String _data(DateTime? data) => data == null
    ? '-'
    : '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
String _dataHora(DateTime? data) => data == null
    ? '-'
    : '${_data(data)} ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
String _diasAtraso(CobrancaRegua item) {
  if (item.vencimento == null) return '-';
  final dias = DateTime.now().difference(item.vencimento!).inDays;
  return '$dias dia(s)';
}
