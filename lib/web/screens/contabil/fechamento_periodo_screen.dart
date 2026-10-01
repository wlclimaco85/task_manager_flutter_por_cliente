import 'package:flutter/material.dart';
import '../../../models/auth_utility.dart';
import '../../../services/periodo_contabil_service.dart';

const _primary = Color(0xFF93070A); // GridColors.primary
const _bg = Color(0xFFF5F5F5);
const _green = Color(0xFF005826);
const _red = Color(0xFF93070A);
const _orange = Color(0xFFE65100);
const _border = Color(0xFFDDDDDD);

class WebFechamentoPeriodoScreen extends StatefulWidget {
  const WebFechamentoPeriodoScreen({super.key});
  @override
  State<WebFechamentoPeriodoScreen> createState() => _WebFechamentoPeriodoScreenState();
}

class _WebFechamentoPeriodoScreenState extends State<WebFechamentoPeriodoScreen> {
  final _service = PeriodoContabilService();
  String _periodo = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
  Map<String, dynamic>? _validacao;
  Map<String, dynamic>? _aiAnalise;
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _validar();
  }

  Future<void> _validar() async {
    final login = AuthUtility.userInfo?.login;
    final empId = int.tryParse(login?.empresa?.id?.toString() ?? '');
    if (empId == null) return;
    setState(() => _loading = true);
    try {
      _validacao = await _service.validarFechamento(empId, _periodo);
      _aiAnalise = await _service.analisarFechamento(empId, _periodo);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fechar() async {
    final login = AuthUtility.userInfo?.login;
    final empId = int.tryParse(login?.empresa?.id?.toString() ?? '');
    if (empId == null) return;
    setState(() => _saving = true);
    try {
      final result = await _service.fecharPeriodo(empId, _periodo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result != null ? 'Período fechado com sucesso!' : 'Erro ao fechar período'),
          backgroundColor: result != null ? _green : _red,
        ));
        if (result != null) _validar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final podeFechar = _validacao?['podeFechar'] == true;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Fechamento de Período'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        actions: [
          SizedBox(
            width: 180,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Período (yyyy-MM)',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  filled: true, fillColor: Colors.white12,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                controller: TextEditingController(text: _periodo),
                onSubmitted: (v) { _periodo = v; _validar(); },
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _validar),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: 700,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _card('Validação', [
                    _linha('Obrigações Pendentes', '${_validacao?['obrigacoesPendentes'] ?? '?'} de ${_validacao?['obrigacoesTotal'] ?? '?'}',
                        (_validacao?['obrigacoesPendentes'] ?? 0) == 0 ? _green : _red),
                    _linha('Escriturações Abertas', '${_validacao?['escrituracoesAbertas'] ?? '?'}',
                        (_validacao?['escrituracoesAbertas'] ?? 0) == 0 ? _green : _red),
                    _linha('Lançamentos Conferem', _validacao?['lancamentosConferem'] == true ? 'Sim' : 'Não',
                        _validacao?['lancamentosConferem'] == true ? _green : _red),
                    if (_validacao?['diferenca'] != null)
                      _linha('Diferença Débito/Crédito', _fmt(_validacao!['diferenca']),
                          (_validacao!['diferenca'] is num && (_validacao!['diferenca'] as num) == 0) ? _green : _red),
                    if (_validacao?['anomalias'] is List)
                      ...(_validacao!['anomalias'] as List).map((a) => _linha('⚠️', a.toString(), _orange)),
                  ]),
                  const SizedBox(height: 16),
                  if (_aiAnalise != null) _card('Análise IA', [
                    _linha('Score', '${_aiAnalise!['score'] ?? '?'}/100',
                        (_aiAnalise!['score'] ?? 0) >= 80 ? _green : (_aiAnalise!['score'] ?? 0) >= 50 ? _orange : _red),
                    _linha('Receita', _fmt(_aiAnalise!['receita'])),
                    _linha('Despesa', _fmt(_aiAnalise!['despesa'])),
                    _linha('Resultado', _fmt(_aiAnalise!['resultado'])),
                    if (_aiAnalise!['variacaoReceitaPct'] != null)
                      _linha('Variação Receita', '${_aiAnalise!['variacaoReceitaPct']}%'),
                    if (_aiAnalise!['variacaoDespesaPct'] != null)
                      _linha('Variação Despesa', '${_aiAnalise!['variacaoDespesaPct']}%'),
                    if (_aiAnalise!['sugestoes'] is List)
                      ...(_aiAnalise!['sugestoes'] as List).map((s) => _linha('💡', s.toString(), _primary)),
                  ]),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(onPressed: _validar, child: const Text('Revalidar')),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: podeFechar && !_saving ? _fechar : null,
                        icon: _saving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.lock),
                        label: Text(_saving ? 'Fechando...' : 'Fechar Período'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ]),
              ),
            ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: _border)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _primary)),
          const Divider(),
          ...children,
        ]),
      ),
    );
  }

  Widget _linha(String label, String valor, [Color? cor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 220, child: Text(label, style: const TextStyle(fontSize: 13))),
        Expanded(child: Text(valor, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cor))),
      ]),
    );
  }

  String _fmt(dynamic v) {
    if (v == null) return '0,00';
    if (v is double || v is int) return v.toStringAsFixed(2).replaceAll('.', ',');
    return v.toString();
  }
}
