import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../core/theme/zen_theme.dart';
import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import '../utils/grid_colors.dart';
import '../widgets/brand_logo.dart';
import 'login_modulos_vitrine.dart' show carregarModulosPublicos;

// Tela EXCLUSIVA do task_manager_flutter_por_cliente (ver CLAUDE.md: "Telas que NAO se Replicam").
// Cadastro gamificado em 3 missoes + parabens: empresa -> usuario master -> pacote com aceite.

/// Termo/contrato SaaS ativo cadastrado no Painel do Dono (`titulo`, `conteudo`).
Future<Map<String, dynamic>?> carregarTermoContrato() async {
  final res = await http
      .get(Uri.parse('${ApiLinks.baseUrl}/api/public/termo-contrato/ativo'))
      .timeout(const Duration(seconds: 10));
  if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
  final data = jsonDecode(utf8.decode(res.bodyBytes));
  return data is Map<String, dynamic> ? data : null;
}

/// Envia o cadastro. Devolve null em caso de sucesso, ou a mensagem de erro para o usuario.
Future<String?> enviarCadastroConta(Map<String, dynamic> payload) async {
  try {
    final res = await http
        .post(
          Uri.parse('${ApiLinks.baseUrl}/api/public/trial-request'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode == 200) return null;
    AppLogger.i.warn('Cadastro de conta: HTTP ${res.statusCode}');
    var msg = 'Não foi possível concluir o cadastro. Tente novamente.';
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body is Map && body['message'] is String) msg = body['message'] as String;
    } catch (e) {
      AppLogger.i.warn('Cadastro de conta: corpo de erro ilegivel: $e');
    }
    return msg;
  } catch (e, st) {
    AppLogger.i.error('Cadastro de conta: falha de rede: $e', st);
    return 'Sem conexão com o servidor. Tente novamente.';
  }
}

String _brl(num v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

class SolicitacaoAcessoScreen extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function() carregarModulos;
  final Future<Map<String, dynamic>?> Function() carregarTermo;
  final Future<String?> Function(Map<String, dynamic>) enviar;

  const SolicitacaoAcessoScreen({
    super.key,
    this.carregarModulos = carregarModulosPublicos,
    this.carregarTermo = carregarTermoContrato,
    this.enviar = enviarCadastroConta,
  });

  @override
  State<SolicitacaoAcessoScreen> createState() => _SolicitacaoAcessoScreenState();
}

class _SolicitacaoAcessoScreenState extends State<SolicitacaoAcessoScreen> {
  static const _missoes = [
    ('Sua empresa', Icons.business_outlined),
    ('Acesso master', Icons.key_outlined),
    ('Seu pacote', Icons.inventory_2_outlined),
  ];
  static const _pontosPorMissao = 100;

  final _formEmpresa = GlobalKey<FormState>();
  final _formMaster = GlobalKey<FormState>();

  final _cnpj = TextEditingController();
  final _razao = TextEditingController();
  final _fantasia = TextEditingController();
  final _ie = TextEditingController();
  final _im = TextEditingController();
  final _cep = TextEditingController();
  final _logradouro = TextEditingController();
  final _numero = TextEditingController();
  final _bairro = TextEditingController();
  final _cidade = TextEditingController();
  final _uf = TextEditingController();

  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _cpf = TextEditingController();
  final _senha = TextEditingController();
  final _confirmar = TextEditingController();

  int _etapa = 0; // 0..2 = missoes, 3 = parabens
  bool _verSenha = false;
  bool _enviando = false;
  String? _erro;

  List<Map<String, dynamic>> _modulos = const [];
  final Set<int> _escolhidos = {};
  Map<String, dynamic>? _termo;
  bool _aceite = false;
  bool _carregandoPacote = false;
  bool _pacoteFalhou = false;

  @override
  void dispose() {
    for (final c in [
      _cnpj, _razao, _fantasia, _ie, _im, _cep, _logradouro, _numero, _bairro,
      _cidade, _uf, _nome, _email, _cpf, _senha, _confirmar,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _digitos(String v) => v.replaceAll(RegExp(r'\D'), '');

  double get _total => _escolhidos.fold<double>(
      0, (s, i) => s + (double.tryParse('${_modulos[i]['valorMensal'] ?? 0}') ?? 0));

  int get _pontos => (_etapa > 3 ? 3 : _etapa) * _pontosPorMissao;

  Future<void> _carregarPacote() async {
    setState(() {
      _carregandoPacote = true;
      _pacoteFalhou = false;
    });
    try {
      final resultados = await Future.wait([widget.carregarModulos(), widget.carregarTermo()]);
      if (!mounted) return;
      setState(() {
        _modulos = resultados[0] as List<Map<String, dynamic>>;
        _termo = resultados[1] as Map<String, dynamic>?;
        _pacoteFalhou = _termo == null;
        _carregandoPacote = false;
      });
    } catch (e, st) {
      AppLogger.i.error('Cadastro de conta: falha ao carregar pacote/contrato: $e', st);
      if (!mounted) return;
      setState(() {
        _pacoteFalhou = true;
        _carregandoPacote = false;
      });
    }
  }

  void _voltar() => setState(() {
        _erro = null;
        if (_etapa > 0) _etapa--;
      });

  void _continuar() {
    final form = _etapa == 0 ? _formEmpresa : _formMaster;
    if (!(form.currentState?.validate() ?? false)) return;
    setState(() {
      _erro = null;
      _etapa++;
    });
    if (_etapa == 2 && _termo == null && !_carregandoPacote) _carregarPacote();
  }

  bool get _podeFinalizar =>
      !_enviando &&
      _termo != null &&
      _aceite &&
      (_modulos.isEmpty || _escolhidos.isNotEmpty);

  Future<void> _finalizar() async {
    if (!_podeFinalizar) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    final escolhidos = [for (final i in _escolhidos.toList()..sort()) _modulos[i]];
    final payload = <String, dynamic>{
      'nome': _nome.text.trim(),
      'email': _email.text.trim(),
      'cpf': _digitos(_cpf.text),
      'cnpj': _digitos(_cnpj.text),
      'localizacao': '${_cidade.text.trim()}/${_uf.text.trim().toUpperCase()}',
      'papel': 'MASTER',
      'modulos': [for (final m in escolhidos) '${m['nome']}'],
      'valorTotal': _total,
      'contratoTextoAceito': '${_termo!['conteudo']}',
      'senha': _senha.text,
      'empresa': {
        'razaoSocial': _razao.text.trim(),
        'nomeFantasia': _fantasia.text.trim(),
        'ie': _ie.text.trim(),
        'im': _im.text.trim(),
        'cep': _digitos(_cep.text),
        'logradouro': _logradouro.text.trim(),
        'numero': _numero.text.trim(),
        'bairro': _bairro.text.trim(),
        'cidade': _cidade.text.trim(),
        'uf': _uf.text.trim().toUpperCase(),
      },
    };
    final erro = await widget.enviar(payload);
    if (!mounted) return;
    setState(() {
      _enviando = false;
      if (erro == null) {
        _etapa = 3;
      } else {
        _erro = erro;
      }
    });
  }

  // ── Validadores ─────────────────────────────────────────────────────────
  String? _obrigatorio(String? v, String campo) =>
      (v == null || v.trim().isEmpty) ? '$campo é obrigatório' : null;

  String? _validarCnpj(String? v) =>
      _digitos(v ?? '').length == 14 ? null : 'Informe um CNPJ válido (14 dígitos)';

  String? _validarCpf(String? v) =>
      _digitos(v ?? '').length == 11 ? null : 'Informe um CPF válido (11 dígitos)';

  String? _validarEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email é obrigatório';
    return RegExp(r'^[\w.\-]+@([\w-]+\.)+\w{2,}$').hasMatch(v.trim()) ? null : 'Email inválido';
  }

  String? _validarSenha(String? v) {
    if (v == null || v.isEmpty) return 'Senha é obrigatória';
    return v.length < 8 ? 'A senha deve ter pelo menos 8 caracteres' : null;
  }

  String? _validarConfirmar(String? v) {
    if (v == null || v.isEmpty) return 'Confirme a senha';
    return v != _senha.text ? 'As senhas não coincidem' : null;
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      backgroundColor: GridColors.background,
      body: SafeArea(
        child: desktop
            ? Row(children: [
                SizedBox(width: 360, child: _painelMissoes()),
                Expanded(child: _areaConteudo(desktop: true)),
              ])
            : _areaConteudo(desktop: false),
      ),
    );
  }

  Widget _painelMissoes() {
    return Container(
      color: GridColors.primaryDark,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BrandLogo(size: 56),
          const SizedBox(height: 24),
          const Text('Vamos montar\nsua conta',
              style: TextStyle(
                  color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, height: 1.2)),
          const SizedBox(height: 8),
          Text('Complete as missões e libere o seu Prumo Contábil.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
          const SizedBox(height: 32),
          for (var i = 0; i < _missoes.length; i++) _linhaMissao(i),
          const SizedBox(height: 24),
          _chipPontos(),
        ],
      ),
    );
  }

  Widget _linhaMissao(int i) {
    final feita = _etapa > i;
    final atual = _etapa == i;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: feita
              ? GridColors.accent
              : (atual ? Colors.white : Colors.white.withValues(alpha: 0.15)),
          child: Icon(feita ? Icons.check_rounded : _missoes[i].$2,
              size: 18, color: feita || atual ? GridColors.primaryDark : Colors.white70),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text('Missão ${i + 1} · ${_missoes[i].$1}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: atual || feita ? 1 : 0.6),
                  fontWeight: atual ? FontWeight.bold : FontWeight.w500)),
        ),
      ]),
    );
  }

  Widget _chipPontos() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: GridColors.accent, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star_rounded, size: 18, color: GridColors.primaryDark),
          const SizedBox(width: 6),
          Text('$_pontos pontos',
              key: const Key('pontos'),
              style: const TextStyle(
                  color: GridColors.primaryDark, fontWeight: FontWeight.bold)),
        ]),
      );

  Widget _areaConteudo({required bool desktop}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: ZenTheme.zenCardDecoration(radius: 20),
            // Material proprio: os CheckboxListTile precisam pintar o ink sobre o fundo do card.
            child: Material(
              type: MaterialType.transparency,
              child: _etapa == 3
                ? _parabens()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!desktop) ...[
                        Row(children: [
                          const BrandLogo(size: 36),
                          const Spacer(),
                          _chipPontos(),
                        ]),
                        const SizedBox(height: 16),
                      ],
                      _barraProgresso(),
                      const SizedBox(height: 20),
                      if (_etapa == 0) _passoEmpresa(),
                      if (_etapa == 1) _passoMaster(),
                      if (_etapa == 2) _passoPacote(),
                      if (_erro != null) ...[
                        const SizedBox(height: 12),
                        Text(_erro!,
                            key: const Key('erro'),
                            style: const TextStyle(color: GridColors.error, fontSize: 13)),
                      ],
                      const SizedBox(height: 20),
                      _botoes(),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _barraProgresso() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Missão ${_etapa + 1} de 3 · ${_missoes[_etapa].$1}',
              style: const TextStyle(
                  color: GridColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (_etapa + 1) / 3),
            duration: const Duration(milliseconds: 400),
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                  value: v,
                  minHeight: 8,
                  color: GridColors.primary,
                  backgroundColor: GridColors.primarySoft),
            ),
          ),
        ],
      );

  Widget _botoes() {
    final ultima = _etapa == 2;
    return Row(children: [
      Flexible(
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _etapa > 0
                ? (_enviando ? null : _voltar)
                : () => Navigator.pop(context),
            child: Text(_etapa > 0 ? 'Voltar' : 'Voltar para o login',
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
      const SizedBox(width: 8),
      ElevatedButton(
        key: const Key('avancar'),
        onPressed: ultima ? (_podeFinalizar ? _finalizar : null) : _continuar,
        child: _enviando
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(ultima ? 'Finalizar' : 'Continuar'),
      ),
    ]);
  }

  // ── Missao 1: empresa ───────────────────────────────────────────────────
  Widget _passoEmpresa() => Form(
        key: _formEmpresa,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _titulo('Conte sobre sua empresa', 'Só o essencial. Você completa o resto depois.'),
          _campo(_cnpj, 'CNPJ', Icons.badge_outlined,
              formatters: [_CnpjInputFormatter()],
              teclado: TextInputType.number,
              validator: _validarCnpj),
          _campo(_razao, 'Razão social', Icons.business_outlined,
              validator: (v) => _obrigatorio(v, 'Razão social')),
          _campo(_fantasia, 'Nome fantasia (opcional)', Icons.storefront_outlined),
          _linha([
            _campo(_ie, 'Inscrição estadual (IE)', Icons.numbers_outlined),
            _campo(_im, 'Inscrição municipal (IM)', Icons.numbers_outlined),
          ]),
          _linha([
            _campo(_cep, 'CEP', Icons.pin_drop_outlined,
                formatters: [_CepInputFormatter()], teclado: TextInputType.number),
            _campo(_numero, 'Número', Icons.tag_outlined),
          ]),
          _campo(_logradouro, 'Endereço (rua)', Icons.signpost_outlined),
          _campo(_bairro, 'Bairro', Icons.map_outlined),
          _linha([
            _campo(_cidade, 'Cidade', Icons.location_city_outlined,
                validator: (v) => _obrigatorio(v, 'Cidade')),
            SizedBox(
              width: 90,
              child: _campo(_uf, 'UF', null,
                  formatters: [LengthLimitingTextInputFormatter(2)],
                  validator: (v) =>
                      (v ?? '').trim().length == 2 ? null : 'UF'),
            ),
          ]),
        ]),
      );

  // ── Missao 2: usuario master ────────────────────────────────────────────
  Widget _passoMaster() => Form(
        key: _formMaster,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _titulo('Quem vai mandar no sistema?',
              'O usuário master tem acesso total à conta da empresa.'),
          _campo(_nome, 'Nome completo', Icons.person_outline,
              validator: (v) => _obrigatorio(v, 'Nome')),
          _campo(_email, 'Email', Icons.mail_outline,
              teclado: TextInputType.emailAddress, validator: _validarEmail),
          _campo(_cpf, 'Seu CPF', Icons.badge_outlined,
              formatters: [_CpfInputFormatter()],
              teclado: TextInputType.number,
              validator: _validarCpf),
          _campo(_senha, 'Senha (mín. 8 caracteres)', Icons.lock_outline,
              obscuro: !_verSenha, validator: _validarSenha, sufixo: _olho()),
          _campo(_confirmar, 'Confirmar senha', Icons.lock_outline,
              obscuro: !_verSenha, validator: _validarConfirmar),
        ]),
      );

  Widget _olho() => IconButton(
        icon: Icon(_verSenha ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20),
        onPressed: () => setState(() => _verSenha = !_verSenha),
      );

  // ── Missao 3: pacote + contrato ─────────────────────────────────────────
  Widget _passoPacote() {
    if (_carregandoPacote) {
      return const Padding(
          padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _titulo('Escolha o seu pacote', 'Marque os módulos que quer contratar.'),
      if (_pacoteFalhou)
        Column(children: [
          const Text('Não foi possível carregar o contrato agora.',
              key: Key('pacote-falhou'), style: TextStyle(color: GridColors.error)),
          TextButton(onPressed: _carregarPacote, child: const Text('Tentar de novo')),
        ])
      else ...[
        for (var i = 0; i < _modulos.length; i++)
          CheckboxListTile(
            key: Key('modulo-$i'),
            value: _escolhidos.contains(i),
            onChanged: (v) => setState(() => v == true ? _escolhidos.add(i) : _escolhidos.remove(i)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text('${_modulos[i]['nome']}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${_modulos[i]['descricao'] ?? ''}',
                maxLines: 2, overflow: TextOverflow.ellipsis),
            secondary: Text(_brl(double.tryParse('${_modulos[i]['valorMensal'] ?? 0}') ?? 0),
                style: const TextStyle(
                    color: GridColors.primary, fontWeight: FontWeight.bold)),
          ),
        const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Flexible(
              child: Text('Total por mês',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600))),
          Text(_brl(_total),
              key: const Key('total'),
              style: const TextStyle(
                  color: GridColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        const SizedBox(height: 16),
        Text('${_termo?['titulo'] ?? 'Contrato'}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          height: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: GridColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GridColors.divider)),
          child: SingleChildScrollView(
              child: Text('${_termo?['conteudo'] ?? ''}',
                  style: const TextStyle(fontSize: 12, height: 1.4))),
        ),
        CheckboxListTile(
          key: const Key('aceite'),
          value: _aceite,
          onChanged: (v) => setState(() => _aceite = v == true),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: const Text('Li e aceito o contrato e os termos de uso.'),
        ),
      ],
    ]);
  }

  // ── Parabens ────────────────────────────────────────────────────────────
  Widget _parabens() => Column(mainAxisSize: MainAxisSize.min, children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: const Icon(Icons.emoji_events_rounded, size: 88, color: GridColors.primary),
        ),
        const SizedBox(height: 12),
        Text('Parabéns, ${_nome.text.trim().split(' ').first}!',
            key: const Key('parabens'),
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: GridColors.textPrimary)),
        const SizedBox(height: 8),
        Text('Você completou as 3 missões e ganhou ${3 * _pontosPorMissao} pontos.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: GridColors.textSecondary)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: GridColors.primarySoft, borderRadius: BorderRadius.circular(12)),
          child: Text(
              'Recebemos o cadastro da ${_razao.text.trim()} com ${_escolhidos.length} '
              'módulo(s) (${_brl(_total)}/mês). Nossa equipe vai analisar e liberar o '
              'seu acesso. Você será avisado por email.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13)),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
            onPressed: () => Navigator.pop(context), child: const Text('Ir para o login')),
      ]);

  // ── Helpers de UI ───────────────────────────────────────────────────────
  Widget _titulo(String t, String s) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: GridColors.textPrimary)),
          const SizedBox(height: 4),
          Text(s, style: const TextStyle(fontSize: 13, color: GridColors.textSecondary)),
        ]),
      );

  Widget _linha(List<Widget> filhos) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < filhos.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          filhos[i] is SizedBox ? filhos[i] : Expanded(child: filhos[i]),
        ],
      ]);

  Widget _campo(
    TextEditingController c,
    String label,
    IconData? icone, {
    String? Function(String?)? validator,
    List<TextInputFormatter>? formatters,
    TextInputType? teclado,
    bool obscuro = false,
    Widget? sufixo,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: c,
          validator: validator,
          inputFormatters: formatters,
          keyboardType: teclado,
          obscureText: obscuro,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: icone == null ? null : Icon(icone, size: 20),
            suffixIcon: sufixo,
          ),
        ),
      );
}

class _CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final d = newValue.text.replaceAll(RegExp(r'\D'), '');
    final l = d.length > 14 ? d.substring(0, 14) : d;
    final b = StringBuffer();
    for (var i = 0; i < l.length; i++) {
      b.write(l[i]);
      if (i == 1 || i == 4) b.write('.');
      if (i == 7) b.write('/');
      if (i == 11) b.write('-');
    }
    final t = b.toString();
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final d = newValue.text.replaceAll(RegExp(r'\D'), '');
    final l = d.length > 11 ? d.substring(0, 11) : d;
    final b = StringBuffer();
    for (var i = 0; i < l.length; i++) {
      b.write(l[i]);
      if (i == 2 || i == 5) b.write('.');
      if (i == 8) b.write('-');
    }
    final t = b.toString();
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

class _CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final d = newValue.text.replaceAll(RegExp(r'\D'), '');
    final l = d.length > 8 ? d.substring(0, 8) : d;
    final t = l.length > 5 ? '${l.substring(0, 5)}-${l.substring(5)}' : l;
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}
