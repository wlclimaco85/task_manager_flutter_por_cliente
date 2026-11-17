import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../services/dp_ponto_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/grid_colors.dart';

/// Mapa dos pontos batidos: um marcador por batida (cor pela situacao), circulo do raio da empresa/parceiro e a lista
/// das batidas fora do raio para aprovar ou reprovar. Mesma tela em Web, Windows e Mobile.
class DpPontoMapaScreen extends StatefulWidget {
  const DpPontoMapaScreen({super.key, this.service});

  /// Injetavel para teste.
  final DpPontoService? service;

  @override
  State<DpPontoMapaScreen> createState() => _DpPontoMapaScreenState();
}

class _DpPontoMapaScreenState extends State<DpPontoMapaScreen> {
  late final DpPontoService _service = widget.service ?? DpPontoService();
  final MapController _mapController = MapController();

  late DateTime _inicio = DateTime.now().subtract(const Duration(days: 6));
  late DateTime _fim = DateTime.now();
  String? _status;
  Map<String, dynamic>? _dados;
  bool _carregando = true;
  bool _executando = false;
  String? _erro;

  static const _situacoes = <String?, String>{
    null: 'Todas',
    'PENDENTE': 'Fora do raio (aguardando)',
    'APROVADO': 'Aprovadas',
    'REPROVADO': 'Reprovadas',
    'DENTRO': 'Dentro do raio',
    'SEM_GEOCERCA': 'Sem geocerca',
  };

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final d = await _service.mapaPontos(_inicio, _fim, status: _status);
      if (mounted) setState(() => _dados = d);
    } on DpPontoException catch (e) {
      if (mounted) setState(() { _dados = null; _erro = e.message; });
    } catch (e, st) {
      AppLogger.i.error('DP: erro ao carregar o mapa de pontos: $e', st);
      if (mounted) setState(() { _dados = null; _erro = 'Não foi possível carregar o mapa dos pontos.'; });
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

  Future<void> _escolherPeriodo() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _inicio, end: _fim),
    );
    if (r == null) return;
    setState(() { _inicio = r.start; _fim = r.end; });
    await _carregar();
  }

  Future<void> _decidir(Map p, bool aprovar) async {
    String? motivo;
    if (!aprovar) {
      final controller = TextEditingController();
      motivo = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reprovar ponto fora do raio'),
          content: TextField(
            key: const Key('dp_mapa_motivo'),
            controller: controller,
            autofocus: true,
            maxLength: 300,
            decoration: const InputDecoration(labelText: 'Motivo (obrigatório, mín. 5 caracteres)'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: GridColors.error),
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Reprovar'),
            ),
          ],
        ),
      );
      if (motivo == null) return;
    }
    setState(() => _executando = true);
    try {
      await _service.decidirPonto((p['pontoId'] as num).toInt(), aprovar, motivo: motivo);
      _aviso(aprovar ? 'Ponto aprovado.' : 'Ponto reprovado: não entra mais na apuração.');
      await _carregar();
    } on DpPontoException catch (e) {
      _aviso(e.message, erro: true);
    } catch (e, st) {
      AppLogger.i.error('DP: erro ao decidir ponto fora do raio: $e', st);
      _aviso('Não foi possível registrar a decisão.', erro: true);
    } finally {
      if (mounted) setState(() => _executando = false);
    }
  }

  static Color _cor(String? s) => switch (s) {
        'PENDENTE' => GridColors.warningDark,
        'REPROVADO' => GridColors.error,
        'APROVADO' => GridColors.primary,
        'DENTRO' => GridColors.success,
        _ => GridColors.textSecondary,
      };

  static String _rotuloStatus(String? s) => switch (s) {
        'PENDENTE' => 'Fora do raio · aguardando aprovação',
        'REPROVADO' => 'Reprovado',
        'APROVADO' => 'Aprovado',
        'DENTRO' => 'Dentro do raio',
        _ => 'Sem geocerca configurada',
      };

  static String _dataHora(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    String d2(int n) => n.toString().padLeft(2, '0');
    return '${d2(dt.day)}/${d2(dt.month)} ${d2(dt.hour)}:${d2(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GridColors.pageBackground,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _filtros(),
          const SizedBox(height: 12),
          if (_carregando) const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
          if (_erro != null)
            Card(
              color: GridColors.errorLight,
              child: Padding(padding: const EdgeInsets.all(16), child: Text(_erro!, style: const TextStyle(color: GridColors.errorDark))),
            ),
          if (!_carregando && _dados != null) ..._conteudo(_dados!),
        ],
      ),
    );
  }

  Widget _filtros() => Card(
        color: GridColors.card,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(spacing: 16, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
            const Text('Mapa dos pontos batidos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: GridColors.textPrimary)),
            OutlinedButton.icon(
              key: const Key('dp_mapa_periodo'),
              onPressed: _carregando ? null : _escolherPeriodo,
              icon: const Icon(Icons.date_range),
              label: Text('${_dataBr(_inicio)} a ${_dataBr(_fim)}'),
            ),
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<String?>(
                key: const Key('dp_mapa_status'),
                value: _status,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Situação', border: OutlineInputBorder()),
                items: _situacoes.entries.map((e) => DropdownMenuItem<String?>(value: e.key, child: Text(e.value))).toList(),
                onChanged: _carregando ? null : (v) { setState(() => _status = v); _carregar(); },
              ),
            ),
            IconButton(tooltip: 'Atualizar', onPressed: _carregando ? null : _carregar, icon: const Icon(Icons.refresh)),
          ]),
        ),
      );

  static String _dataBr(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  List<Widget> _conteudo(Map<String, dynamic> dados) {
    final pontos = (dados['pontos'] as List? ?? []).whereType<Map>().toList();
    final centros = (dados['centros'] as List? ?? []).whereType<Map>().toList();
    final pendentes = (dados['pendentes'] as num? ?? 0).toInt();
    return [
      Wrap(spacing: 12, runSpacing: 12, children: [
        _indicador('Pontos no período', '${pontos.length}', GridColors.primary),
        _indicador('Fora do raio (aguardando)', '$pendentes', pendentes > 0 ? GridColors.warningDark : GridColors.success),
      ]),
      const SizedBox(height: 12),
      Card(
        color: GridColors.card,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(height: 420, child: _mapa(pontos, centros)),
      ),
      const SizedBox(height: 4),
      Wrap(spacing: 14, children: [
        for (final s in const ['DENTRO', 'PENDENTE', 'APROVADO', 'REPROVADO', 'SEM_GEOCERCA'])
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.circle, size: 12, color: _cor(s)),
            const SizedBox(width: 4),
            Text(_rotuloStatus(s).split(' · ').first, style: const TextStyle(fontSize: 12)),
          ]),
      ]),
      const SizedBox(height: 12),
      _lista(pontos),
    ];
  }

  Widget _mapa(List<Map> pontos, List<Map> centros) {
    final coords = <LatLng>[
      for (final p in pontos) LatLng((p['latitude'] as num).toDouble(), (p['longitude'] as num).toDouble()),
      for (final c in centros) LatLng((c['latitude'] as num).toDouble(), (c['longitude'] as num).toDouble()),
    ];
    final centro = coords.isEmpty ? const LatLng(-14.235, -51.925) : coords.first; // sem dados: Brasil
    return FlutterMap(
      key: const Key('dp_mapa'),
      mapController: _mapController,
      options: MapOptions(
        initialCenter: centro,
        initialZoom: coords.isEmpty ? 4 : 13,
        initialCameraFit: coords.length > 1
            ? CameraFit.coordinates(coordinates: coords, padding: const EdgeInsets.all(48), maxZoom: 16)
            : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'br.com.appacademia.contapropria',
        ),
        CircleLayer(circles: [
          for (final c in centros)
            CircleMarker(
              point: LatLng((c['latitude'] as num).toDouble(), (c['longitude'] as num).toDouble()),
              radius: (c['raioKm'] as num).toDouble() * 1000,
              useRadiusInMeter: true,
              color: GridColors.primary.withValues(alpha: 0.10),
              borderColor: GridColors.primary,
              borderStrokeWidth: 1.5,
            ),
        ]),
        MarkerLayer(markers: [
          for (final c in centros)
            Marker(
              point: LatLng((c['latitude'] as num).toDouble(), (c['longitude'] as num).toDouble()),
              width: 36,
              height: 36,
              child: Tooltip(message: '${c['nome']} (raio ${c['raioKm']} km)', child: const Icon(Icons.business, color: GridColors.primaryDark)),
            ),
          for (final p in pontos)
            Marker(
              point: LatLng((p['latitude'] as num).toDouble(), (p['longitude'] as num).toDouble()),
              width: 34,
              height: 34,
              child: GestureDetector(
                key: Key('dp_mapa_ponto_${p['pontoId']}'),
                onTap: () => _detalhe(p),
                child: Icon(Icons.location_on, size: 34, color: _cor(p['status'] as String?)),
              ),
            ),
        ]),
        const RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap contributors')]),
      ],
    );
  }

  Future<void> _detalhe(Map p) async {
    final pendente = p['status'] == 'PENDENTE';
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${p['funcionario'] ?? 'Funcionário'} · ${_dataHora('${p['dataHora']}')}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(_rotuloStatus(p['status'] as String?), style: TextStyle(color: _cor(p['status'] as String?), fontWeight: FontWeight.w600)),
          if (p['distanciaKm'] != null)
            Text('${(p['distanciaKm'] as num).toStringAsFixed(2)} km de ${p['referencia']} (raio ${p['raioKm']} km)'),
          if (p['motivo'] != null) Text('Motivo: ${p['motivo']}'),
          if (pendente) ...[
            const SizedBox(height: 12),
            Row(children: [
              FilledButton(onPressed: _executando ? null : () { Navigator.pop(ctx); _decidir(p, true); }, child: const Text('Aprovar')),
              const SizedBox(width: 12),
              OutlinedButton(onPressed: _executando ? null : () { Navigator.pop(ctx); _decidir(p, false); }, child: const Text('Reprovar')),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _lista(List<Map> pontos) {
    final pend = pontos.where((p) => p['status'] == 'PENDENTE').toList();
    return Card(
      color: GridColors.card,
      child: ExpansionTile(
        key: const Key('dp_mapa_pendentes'),
        initiallyExpanded: pend.isNotEmpty,
        leading: Icon(Icons.pin_drop_outlined, color: pend.isEmpty ? GridColors.success : GridColors.warningDark),
        title: Text('Batidas fora do raio aguardando aprovação (${pend.length})', style: const TextStyle(fontWeight: FontWeight.w600)),
        children: pend.isEmpty
            ? const [ListTile(dense: true, title: Text('Nenhuma batida aguardando aprovação.'))]
            : pend.map((p) => ListTile(
                  key: Key('dp_pend_${p['pontoId']}'),
                  dense: true,
                  title: Text('${p['funcionario'] ?? '-'} · ${_dataHora('${p['dataHora']}')}'),
                  subtitle: Text('${(p['distanciaKm'] as num? ?? 0).toStringAsFixed(2)} km de ${p['referencia']} (raio ${p['raioKm']} km)'),
                  trailing: Wrap(spacing: 4, children: [
                    IconButton(
                      key: Key('dp_aprovar_${p['pontoId']}'),
                      tooltip: 'Aprovar',
                      onPressed: _executando ? null : () => _decidir(p, true),
                      icon: const Icon(Icons.check_circle_outline, color: GridColors.success),
                    ),
                    IconButton(
                      key: Key('dp_reprovar_${p['pontoId']}'),
                      tooltip: 'Reprovar',
                      onPressed: _executando ? null : () => _decidir(p, false),
                      icon: const Icon(Icons.cancel_outlined, color: GridColors.error),
                    ),
                  ]),
                )).toList(),
      ),
    );
  }

  Widget _indicador(String titulo, String valor, Color cor) => SizedBox(
        width: 220,
        child: Card(
          color: GridColors.card,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo, style: const TextStyle(color: GridColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Text(valor, style: TextStyle(color: cor, fontSize: 26, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );
}
