import 'package:flutter/material.dart';

import '../../services/dp_ponto_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/grid_colors.dart';

/// Assinatura eletronica do espelho de ponto: o funcionario aceita (data/hora, IP e hash gravados no backend) e o
/// gestor valida (fecha). Mesma tela em Web, Windows e Mobile; o layout se adapta a largura.
class DpEspelhoAssinaturaScreen extends StatefulWidget {
  const DpEspelhoAssinaturaScreen({super.key, this.service});

  /// Injetavel para teste.
  final DpPontoService? service;

  @override
  State<DpEspelhoAssinaturaScreen> createState() => _DpEspelhoAssinaturaScreenState();
}

class _DpEspelhoAssinaturaScreenState extends State<DpEspelhoAssinaturaScreen> {
  late final DpPontoService _service = widget.service ?? DpPontoService();

  List<Map<String, dynamic>> _funcionarios = [];
  int? _funcionarioId;
  late DateTime _competencia = _mesAnterior();
  Map<String, dynamic>? _estado;
  bool _carregando = true;
  bool _executando = false;
  String? _erro;

  static const _meses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];

  static DateTime _mesAnterior() {
    final h = DateTime.now();
    return DateTime(h.year, h.month - 1, 1);
  }

  List<DateTime> get _opcoesCompetencia {
    final h = DateTime.now();
    return List.generate(12, (i) => DateTime(h.year, h.month - i, 1));
  }

  String _rotulo(DateTime d) => '${_meses[d.month - 1]}/${d.year}';

  @override
  void initState() {
    super.initState();
    _carregarFuncionarios();
  }

  Future<void> _carregarFuncionarios() async {
    try {
      final lista = await _service.funcionarios();
      if (!mounted) return;
      setState(() {
        _funcionarios = lista;
        _carregando = false;
      });
    } on DpPontoException catch (e) {
      if (mounted) setState(() { _erro = e.message; _carregando = false; });
    } catch (e, st) {
      AppLogger.i.error('DP: erro ao carregar funcionários: $e', st);
      if (mounted) setState(() { _erro = 'Não foi possível carregar os funcionários.'; _carregando = false; });
    }
  }

  Future<void> _carregarEstado() async {
    final id = _funcionarioId;
    if (id == null) return;
    setState(() { _carregando = true; _erro = null; });
    try {
      final e = await _service.estadoAssinatura(id, _competencia.month, _competencia.year);
      if (mounted) setState(() => _estado = e);
    } on DpPontoException catch (e) {
      if (mounted) setState(() { _estado = null; _erro = e.message; });
    } catch (e, st) {
      AppLogger.i.error('DP: erro ao consultar assinatura do espelho: $e', st);
      if (mounted) setState(() { _estado = null; _erro = 'Não foi possível consultar o espelho.'; });
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _aviso(String msg, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: erro ? GridColors.error : GridColors.primary,
    ));
  }

  Future<void> _executar(Future<Map<String, dynamic>> Function() acao, String sucesso, String falha) async {
    setState(() => _executando = true);
    try {
      final e = await acao();
      if (!mounted) return;
      setState(() => _estado = e);
      _aviso(sucesso);
    } on DpPontoException catch (e) {
      _aviso(e.message, erro: true);
    } catch (e, st) {
      AppLogger.i.error('DP: $falha: $e', st);
      _aviso(falha, erro: true);
    } finally {
      if (mounted) setState(() => _executando = false);
    }
  }

  Future<void> _assinar() async {
    final id = _funcionarioId!;
    await _executar(() => _service.aceitarEspelho(id, _competencia.month, _competencia.year),
        'Espelho assinado.', 'Não foi possível assinar o espelho.');
  }

  Future<void> _validar() async {
    final id = _funcionarioId!;
    final semAceite = _estado?['status'] != 'ACEITO_FUNC';
    String? justificativa;
    if (semAceite) {
      final controller = TextEditingController();
      justificativa = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Fechar sem aceite do funcionário'),
          content: TextField(
            key: const Key('dp_justificativa'),
            controller: controller,
            autofocus: true,
            maxLength: 300,
            decoration: const InputDecoration(labelText: 'Justificativa (obrigatória, mín. 5 caracteres)'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Fechar espelho')),
          ],
        ),
      );
      if (justificativa == null) return;
    }
    await _executar(
        () => _service.validarEspelho(id, _competencia.month, _competencia.year, justificativa: justificativa),
        'Espelho validado e fechado.',
        'Não foi possível validar o espelho.');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GridColors.pageBackground,
      child: RefreshIndicator(
        onRefresh: _carregarEstado,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _filtros(),
            const SizedBox(height: 16),
            if (_carregando) const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
            if (_erro != null)
              Card(
                color: GridColors.errorLight,
                child: Padding(padding: const EdgeInsets.all(16), child: Text(_erro!, style: const TextStyle(color: GridColors.errorDark))),
              ),
            if (!_carregando && _estado != null) _cartaoEstado(_estado!),
          ],
        ),
      ),
    );
  }

  Widget _filtros() => Card(
        color: GridColors.card,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Assinatura do espelho de ponto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: GridColors.textPrimary)),
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<int>(
                  key: const Key('dp_assin_funcionario'),
                  value: _funcionarioId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Funcionário', border: OutlineInputBorder()),
                  items: _funcionarios
                      .map((f) => DropdownMenuItem<int>(value: (f['id'] as num).toInt(), child: Text('${f['nome'] ?? f['id']}', overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: _executando ? null : (v) { setState(() => _funcionarioId = v); _carregarEstado(); },
                ),
              ),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<DateTime>(
                  key: const Key('dp_assin_competencia'),
                  value: _opcoesCompetencia.firstWhere((d) => d.year == _competencia.year && d.month == _competencia.month,
                      orElse: () => _opcoesCompetencia.first),
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Competência', border: OutlineInputBorder()),
                  items: _opcoesCompetencia.map((d) => DropdownMenuItem(value: d, child: Text(_rotulo(d)))).toList(),
                  onChanged: _executando ? null : (v) { if (v != null) { setState(() => _competencia = v); _carregarEstado(); } },
                ),
              ),
            ],
          ),
        ),
      );

  Widget _cartaoEstado(Map<String, dynamic> e) {
    final status = '${e['status']}';
    final (rotulo, cor) = switch (status) {
      'FECHADO' => ('Fechado e validado pelo gestor', GridColors.primary),
      'ACEITO_FUNC' => ('Assinado pelo funcionário', GridColors.success),
      _ => ('Aguardando assinatura do funcionário', GridColors.warningDark),
    };
    final inconsist = (e['inconsistencias'] as num? ?? 0).toInt();
    final fechado = status == 'FECHADO';
    return Card(
      color: GridColors.card,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${e['nome']} · ${_rotulo(_competencia)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(rotulo, key: const Key('dp_assin_status'), style: TextStyle(color: cor, fontWeight: FontWeight.w600)),
          if (inconsist > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('$inconsist dia(s) com batida ímpar: peça o ajuste do ponto antes de assinar.',
                  style: const TextStyle(color: GridColors.error)),
            ),
          const SizedBox(height: 12),
          if (e['dhAceite'] != null) _linha('Aceite em', _dataHora('${e['dhAceite']}')),
          if (e['aceiteIp'] != null) _linha('IP do aceite', '${e['aceiteIp']}'),
          if (e['hashAceite'] != null) _linha('Hash do espelho (SHA-256)', _curto('${e['hashAceite']}')),
          if (e['dhAceite'] != null)
            _linha('Assinatura confere', e['aceiteConfere'] == true ? 'Sim' : 'Não: o espelho mudou depois do aceite'),
          if (e['dhFechamento'] != null) _linha('Validado em', _dataHora('${e['dhFechamento']}')),
          if (e['validacaoJustificativa'] != null) _linha('Justificativa do gestor', '${e['validacaoJustificativa']}'),
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 8, children: [
            FilledButton.icon(
              key: const Key('dp_assinar'),
              onPressed: _executando || fechado || status == 'ACEITO_FUNC' ? null : _assinar,
              icon: const Icon(Icons.draw_outlined),
              label: const Text('Assinar meu espelho'),
            ),
            OutlinedButton.icon(
              key: const Key('dp_validar'),
              onPressed: _executando || fechado ? null : _validar,
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Validar e fechar (gestor)'),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _linha(String rotulo, String valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Wrap(children: [
          Text('$rotulo: ', style: const TextStyle(color: GridColors.textSecondary)),
          Text(valor),
        ]),
      );

  static String _curto(String hash) => hash.length > 20 ? '${hash.substring(0, 16)}…${hash.substring(hash.length - 8)}' : hash;

  static String _dataHora(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    String d2(int n) => n.toString().padLeft(2, '0');
    return '${d2(dt.day)}/${d2(dt.month)}/${dt.year} ${d2(dt.hour)}:${d2(dt.minute)}';
  }
}
