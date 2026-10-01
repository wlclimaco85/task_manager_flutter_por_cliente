import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import 'package:intl/intl.dart';
import '../../../models/auth_utility.dart';
import '../../../models/ponto_model.dart';
import '../../../services/ponto_service.dart';

// ── Cores ─────────────────────────────────────────────────────────────────────
const _primary = GridColors.primary;
const _green   = GridColors.secondary;
const _bg      = Color(0xFFF5F5F5);
const _white   = Colors.white;

class WindowsPontoScreen extends StatefulWidget {
  const WindowsPontoScreen({super.key});
  @override
  State<WindowsPontoScreen> createState() => _WebPontoScreenState();
}

class _WebPontoScreenState extends State<WindowsPontoScreen> {
  late DateTime _now;
  Timer? _timer;
  bool _registering = false;
  bool _loading = false;
  List<PontoModel> _pontos = [];

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
    _carregar();
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final id = AuthUtility.userInfo?.login?.id;
    if (id != null) _pontos = await PontoService.listarPontos(id);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _registrar() async {
    setState(() => _registering = true);
    final id = AuthUtility.userInfo?.login?.id;
    if (id == null) { _snack('Login não encontrado'); setState(() => _registering = false); return; }
    final ok = await PontoService.registrarPonto(id);
    _snack(ok ? 'Ponto registrado!' : 'Erro ao registrar ponto');
    if (ok) await _carregar();
    if (mounted) setState(() => _registering = false);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  List<Map<String, String>> get _pares {
    final r = <Map<String, String>>[];
    for (int i = 0; i < _pontos.length; i += 2) {
      final e = _pontos[i];
      final s = i + 1 < _pontos.length ? _pontos[i + 1] : null;
      r.add({'entrada': _fmt(e.dataHora), 'saida': s != null ? _fmt(s.dataHora) : '--:--'});
    }
    return r;
  }

  String _fmt(DateTime? dt) => dt == null ? '--:--' : DateFormat.Hm().format(dt);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary, foregroundColor: _white, elevation: 2,
        title: const Row(children: [
          Icon(Icons.fingerprint, size: 20),
          SizedBox(width: 8),
          Text('Registro de Ponto', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        actions: [
          IconButton(onPressed: _carregar, icon: const Icon(Icons.refresh), tooltip: 'Atualizar'),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              _buildRelogio(),
              const SizedBox(height: 24),
              _buildMarcacoes(),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildRelogio() {
    return Card(
      elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          Text(DateFormat.Hms().format(_now),
              style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: _primary)),
          const SizedBox(height: 8),
          Text(DateFormat("EEEE, dd 'de' MMMM 'de' yyyy", 'pt_BR').format(_now),
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _registering ? null : _registrar,
            icon: _registering
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _white))
                : const Icon(Icons.fingerprint, color: _white),
            label: Text(_registering ? 'Registrando...' : 'Registrar Ponto',
                style: const TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Clique para registrar entrada/saída', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildMarcacoes() {
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.schedule, color: _primary),
            SizedBox(width: 8),
            Text('Marcações de Hoje', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          const Divider(height: 20),
          if (_loading) const Center(child: CircularProgressIndicator(color: _primary))
          else if (_pares.isEmpty)
            const Text('Nenhuma marcação hoje.', style: TextStyle(color: Colors.grey))
          else
            ..._pares.map((p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _badge(Icons.login, p['entrada']!, _green),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                _badge(Icons.logout, p['saida']!, _primary),
              ]),
            )),
        ]),
      ),
    );
  }

  Widget _badge(IconData icon, String time, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 6),
      Text(time, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
    ]),
  );
}
