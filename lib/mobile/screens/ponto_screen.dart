import '../../utils/ponto_comprovante_helper.dart';
import 'dart:async';
import '../../widgets/user_banners.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:task_manager_flutter/constants/custom_colors.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/ponto_model.dart';
import 'package:task_manager_flutter/services/ponto_service.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import 'package:task_manager_flutter/utils/tenant_context.dart';

import 'pdf_preview_dialog.dart';
import 'relatorio_ponto_screen.dart';
import 'ponto_solicitacao_screen.dart';

class PontoScreen extends StatefulWidget {
  const PontoScreen({super.key});

  @override
  State<PontoScreen> createState() => _PontoScreenState();
}

class _PontoScreenState extends State<PontoScreen> {
  late DateTime now;
  Timer? _timer;

  bool _registering = false;
  bool _loading = false;

  List<PontoModel> _pontos = [];

  // H10: funcionário vinculado ao login logado
  Map<String, dynamic>? _funcionario;

  // Resumo: ferias nao tiradas, pontos incorretos no mes e solicitacoes pendentes
  Map<String, dynamic>? _resumo;

  Future<void> _carregarResumo() async {
    final funcId = _funcionario?['id'];
    if (funcId == null) return;
    try {
      final agora = DateTime.now();
      final resp = await TenantContext.get(
          '${ApiLinks.baseUrl}/api/ponto-resumo?funcionarioId=$funcId&mes=${agora.month}&ano=${agora.year}');
      if (resp.statusCode == 200 && mounted) {
        setState(() => _resumo = jsonDecode(resp.body) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Erro ao carregar resumo do ponto: $e');
    }
  }

  Widget _buildResumoCard() {
    final r = _resumo;
    if (r == null) return const SizedBox.shrink();
    final ferias = (r['feriasNaoTiradas'] as List?) ?? const [];
    final incorretos = (r['pontosIncorretos'] as List?) ?? const [];
    final ajustes = (r['ajustesPendentes'] as num?)?.toInt() ?? 0;
    final feriasPend = (r['feriasPendentes'] as num?)?.toInt() ?? 0;
    final nada = ferias.isEmpty && incorretos.isEmpty && ajustes == 0 && feriasPend == 0;
    final fmt = DateFormat('dd/MM/yyyy');

    final linhas = <Widget>[];
    for (final f in ferias.cast<Map<String, dynamic>>()) {
      final concessivo = DateTime.tryParse(f['concessivoFim']?.toString() ?? '');
      linhas.add(_linhaAviso(Icons.beach_access,
          'Férias não tiradas: ${f['saldoDias']} dia(s), concessivo até ${concessivo == null ? '-' : fmt.format(concessivo)} (${f['situacao']})'));
    }
    if (incorretos.isNotEmpty) {
      linhas.add(_linhaAviso(Icons.error_outline,
          'Ponto incorreto em ${incorretos.length} dia(s) este mês: ${incorretos.map((d) => d.toString()).join(', ')}'));
    }
    if (ajustes > 0) {
      linhas.add(_linhaAviso(Icons.edit_calendar, 'Ajuste(s) de ponto pendente(s): $ajustes'));
    }
    if (feriasPend > 0) {
      linhas.add(_linhaAviso(Icons.flight, 'Solicitação(ões) de férias pendente(s): $feriasPend'));
    }

    return Card(
      color: GridColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pendências',
                style: TextStyle(fontWeight: FontWeight.bold, color: GridColors.textPrimary, fontSize: 16)),
            const SizedBox(height: 8),
            if (nada)
              const Text('Nenhuma pendência.', style: TextStyle(color: GridColors.textSecondary))
            else
              ...linhas,
          ],
        ),
      ),
    );
  }

  Widget _linhaAviso(IconData icon, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: GridColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: const TextStyle(color: GridColors.textPrimary))),
        ],
      ),
    );
  }

  // Humor do dia: indice do icone (0 = mais feliz ... 4 = mais triste). Persistido em /api/ponto-humor como nivel = 5 - indice.
  int? _humorSelecionado;

  Future<void> _carregarHumor() async {
    final loginId = AuthUtility.userInfo?.login?.id;
    if (loginId == null) return;
    try {
      final hoje = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final resp = await TenantContext.get(
          '${ApiLinks.baseUrl}/api/ponto-humor/$loginId?data=$hoje');
      if (resp.statusCode == 200 && mounted) {
        final nivel = (jsonDecode(resp.body)['nivel'] as num).toInt();
        setState(() => _humorSelecionado = 5 - nivel);
      }
    } catch (e) {
      debugPrint('Erro ao carregar humor: $e');
    }
  }

  Future<void> _registrarHumor(int indice) async {
    final loginId = AuthUtility.userInfo?.login?.id;
    if (loginId == null) return;
    setState(() => _humorSelecionado = indice);
    try {
      final resp = await TenantContext.post(
          '${ApiLinks.baseUrl}/api/ponto-humor',
          {
            'loginId': loginId,
            if (TenantContext.empresaId != null) 'empresaId': TenantContext.empresaId,
            'dataHumor': DateFormat('yyyy-MM-dd').format(DateTime.now()),
            'nivel': 5 - indice,
          });
      if (resp.statusCode != 200 && mounted) {
        _mostrarSnack('Erro ao salvar humor (${resp.statusCode})');
      }
    } catch (e) {
      _mostrarSnack('Erro ao salvar humor: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => now = DateTime.now());
    });
    _carregarPontos();
    _carregarFuncionario();
    _carregarHumor();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // H10: busca o funcionário vinculado ao login logado
  Future<void> _carregarFuncionario() async {
    final userId = TenantContext.userId;
    if (userId == null) return;
    try {
      final url = TenantContext.applyToUrl(
          '${ApiLinks.baseUrl}/api/funcionario/por-login?userId=$userId');
      final resp =
          await http.get(Uri.parse(url), headers: TenantContext.headers);
      if (resp.statusCode == 200 && mounted) {
        final body = jsonDecode(resp.body);
        setState(() {
          _funcionario = body is Map<String, dynamic> ? body : body['data'];
        });
        _carregarResumo();
      }
    } catch (e) {
      debugPrint('H10: Erro ao carregar funcionário: $e');
    }
  }

  Future<void> _carregarPontos() async {
    setState(() => _loading = true);
    try {
      final loginId = AuthUtility.userInfo?.login?.id;
      if (loginId != null) {
        _pontos = await PontoService.listarPontos(loginId);
      }
    } catch (e) {
      debugPrint('Erro ao carregar pontos: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _registrarPonto() async {
    setState(() => _registering = true);
    try {
      final loginId = AuthUtility.userInfo?.login?.id;
      if (loginId == null) {
        _mostrarSnack('Login não encontrado na sessão');
        setState(() => _registering = false);
        return;
      }

      // Localizacao (GPS) obrigatoria: o PontoService obtem e recusa o ponto se estiver desligada/negada
      final ok = await PontoService.registrarPonto(loginId);
      if (ok) {
        if (mounted) {
          final aviso = PontoService.ultimoAviso;
          ScaffoldMessenger.of(context).showSnackBar(snackBatidaRegistrada(
              context, 'Ponto registrado com sucesso!${aviso != null ? ' $aviso' : ''}'));
        }
        await _carregarPontos();
      } else {
        _mostrarSnack(PontoService.ultimoErro ?? 'Erro ao registrar ponto');
      }
    } catch (e) {
      _mostrarSnack('Erro: $e');
    }
    if (mounted) setState(() => _registering = false);
  }

  void _mostrarSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // Agrupa pontos em pares entrada/saída
  List<Map<String, String>> get _marcacoesAgrupadas {
    final result = <Map<String, String>>[];
    for (int i = 0; i < _pontos.length; i += 2) {
      final entrada = _pontos[i];
      final saida = i + 1 < _pontos.length ? _pontos[i + 1] : null;
      result.add({
        'entrada': _fmtHora(entrada.dataHora),
        'saida': saida != null ? _fmtHora(saida.dataHora) : '--:--',
      });
    }
    return result;
  }

  String _fmtHora(DateTime? dt) {
    if (dt == null) return '--:--';
    return DateFormat.Hm().format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final login = AuthUtility.userInfo?.login;
    if (login == null || login.id == null) {
      return const Scaffold(
        body: Center(child: Text('Login não encontrado na sessão')),
      );
    }

    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: UserBannerAppBar(
        screenTitle: 'Registro de Ponto',
        showBackButton: Navigator.canPop(context),
        onRefresh: _carregarPontos,
      ),
      body: RefreshIndicator(
        onRefresh: _carregarPontos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildClockCard(),
              const SizedBox(height: 20),
              _buildMarcacoesCard(),
              const SizedBox(height: 20),
              _buildResumoCard(),
              const SizedBox(height: 20),
              _buildActionButtons(),
              const SizedBox(height: 30),
              _buildHumorSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClockCard() {
    return Card(
      color: GridColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Text(
              DateFormat.Hms().format(now),
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: GridColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat("EEEE, dd 'de' MMMM 'de' yyyy", 'pt_BR').format(now),
              style: const TextStyle(
                fontSize: 15,
                color: GridColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              onPressed: _registering ? null : _registrarPonto,
              icon: const Icon(Icons.fingerprint, color: Colors.white),
              label: Text(
                _registering ? 'Registrando...' : 'Registrar Ponto',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Clique para registrar sua entrada/saída automaticamente',
              style: TextStyle(fontSize: 13, color: GridColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarcacoesCard() {
    final marcacoes = _marcacoesAgrupadas;
    return Card(
      color: GridColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.schedule, color: GridColors.primary),
                SizedBox(width: 8),
                Text(
                  'Marcações de Hoje',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: GridColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (marcacoes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Nenhuma marcação registrada hoje.',
                  style: TextStyle(color: GridColors.textSecondary),
                ),
              )
            else
              Column(
                children: marcacoes
                    .map((m) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTimeBadge(
                                  Icons.login, m['entrada'] ?? '--:--', true),
                              const Icon(Icons.swap_horiz,
                                  color: GridColors.textSecondary),
                              _buildTimeBadge(
                                  Icons.logout, m['saida'] ?? '--:--', false),
                            ],
                          ),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBadge(IconData icon, String time, bool start) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: start
            ? GridColors.success.withValues(alpha: 0.15)
            : GridColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: start ? GridColors.success : GridColors.error, size: 18),
          const SizedBox(width: 6),
          Text(
            time,
            style: TextStyle(
              color: start ? GridColors.success : GridColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RelatorioPontoScreen()));
                },
                icon: const Icon(Icons.picture_as_pdf,
                    color: Colors.white, size: 20),
                label: const Text('Espelho',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.buttonBackground,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PontoSolicitacaoScreen()));
                },
                icon: const Icon(Icons.edit_calendar,
                    color: Colors.white, size: 20),
                label: const Text('Ajustes',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.secondary,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () async {
            final loginId = AuthUtility.userInfo?.login?.id;
            if (loginId == null) return;
            final valor = await PontoService.bancoHoras(loginId);
            if (!mounted) return;
            if (valor == null) {
              _mostrarSnack('Erro ao carregar banco de horas');
              return;
            }
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Banco de Horas'),
                content: Text('Saldo: ${valor.toStringAsFixed(2)} horas'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.timelapse, color: Colors.white),
          label: const Text('Saldo do Banco de Horas',
              style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: GridColors.success,
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildHumorSection() {
    final icons = [
      Icons.sentiment_very_satisfied,
      Icons.sentiment_satisfied,
      Icons.sentiment_neutral,
      Icons.sentiment_dissatisfied,
      Icons.sentiment_very_dissatisfied,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Como está seu humor hoje?',
          style: TextStyle(
            color: GridColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < icons.length; i++)
              IconButton(
                icon: Icon(icons[i],
                    size: 34,
                    color: _humorSelecionado == i
                        ? GridColors.success
                        : GridColors.primary),
                onPressed: () => _registrarHumor(i),
              ),
          ],
        ),
      ],
    );
  }
}
