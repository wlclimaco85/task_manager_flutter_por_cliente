import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../utils/api_links.dart';
import '../utils/assets_utils.dart';
import '../utils/grid_colors.dart';
import '../utils/grid_texts.dart';

class SolicitacaoAcessoScreen extends StatefulWidget {
  const SolicitacaoAcessoScreen({super.key});

  @override
  State<SolicitacaoAcessoScreen> createState() =>
      _SolicitacaoAcessoScreenState();
}

class _SolicitacaoAcessoScreenState extends State<SolicitacaoAcessoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmarSenhaCtrl = TextEditingController();
  final _cpfCnpjCtrl = TextEditingController();
  final _cpfSolicitanteCtrl = TextEditingController();

  bool _obscureSenha = true;
  bool _obscureConfirmar = true;
  bool _enviando = false;
  bool _sucesso = false;
  String? _erroServidor;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmarSenhaCtrl.dispose();
    _cpfCnpjCtrl.dispose();
    _cpfSolicitanteCtrl.dispose();
    super.dispose();
  }

  String _apenasDigitos(String v) => v.replaceAll(RegExp(r'\D'), '');

  String? _validarObrigatorio(String? v, String campo) {
    if (v == null || v.trim().isEmpty) return '$campo é obrigatório';
    return null;
  }

  String? _validarCpfCnpj(String? v) {
    final digitos = _apenasDigitos(v ?? '');
    if (digitos.isEmpty) return 'CPF ou CNPJ é obrigatório';
    if (digitos.length != 11 && digitos.length != 14) {
      return 'Informe um CPF (11 dígitos) ou CNPJ (14 dígitos) válido';
    }
    return null;
  }

  String? _validarCpfSolicitante(String? v) {
    final digitos = _apenasDigitos(v ?? '');
    if (digitos.isEmpty) return 'CPF é obrigatório';
    if (digitos.length != 11) {
      return 'Informe um CPF válido (11 dígitos)';
    }
    return null;
  }

  String? _validarEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email é obrigatório';
    final regex = RegExp(r'^[\w.\-]+@([\w-]+\.)+\w{2,}$');
    if (!regex.hasMatch(v.trim())) return 'Email inválido';
    return null;
  }

  String? _validarSenha(String? v) {
    if (v == null || v.isEmpty) return 'Senha é obrigatória';
    if (v.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
    return null;
  }

  String? _validarConfirmarSenha(String? v) {
    if (v == null || v.isEmpty) return 'Confirme a senha';
    if (v != _senhaCtrl.text) return 'As senhas não coincidem';
    return null;
  }

  Future<void> _enviar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _enviando = true;
      _erroServidor = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse(ApiLinks.solicitacaoAcesso),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nome': _nomeCtrl.text.trim(),
              'email': _emailCtrl.text.trim(),
              'cpfCnpj': _apenasDigitos(_cpfCnpjCtrl.text),
              'cpfSolicitante': _apenasDigitos(_cpfSolicitanteCtrl.text),
              'senha': _senhaCtrl.text,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 201) {
        setState(() {
          _enviando = false;
          _sucesso = true;
        });
        return;
      }

      String mensagem = 'Erro ao enviar solicitação. Tente novamente.';
      if (response.statusCode == 409) {
        mensagem = 'Já existe uma solicitação pendente para este email/CPF-CNPJ.';
      }
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final msg = (body['response'] as Map<String, dynamic>?)?['message']
            ?.toString();
        if (msg != null && msg.isNotEmpty) mensagem = msg;
      } catch (e) {
        debugPrint('[SolicitacaoAcessoScreen] falha ao parsear corpo do erro: $e');
      }

      // Controller atual so retorna 201 ou 409; qualquer outro status e inesperado.
      if (response.statusCode != 409) {
        debugPrint(
            '[SolicitacaoAcessoScreen] erro inesperado statusCode=${response.statusCode} body=${response.body}');
      }
      setState(() {
        _enviando = false;
        _erroServidor = mensagem;
      });
    } catch (e) {
      debugPrint('[SolicitacaoAcessoScreen] falha ao enviar solicitação: $e');
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _erroServidor = GridTexts.loginNoConnection;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile =
        !kIsWeb && defaultTargetPlatform != TargetPlatform.windows;
    final bool isCompact = isMobile || MediaQuery.sizeOf(context).width < 900;

    return Scaffold(
      backgroundColor: GridColors.secondary,
      body: SafeArea(
        child: isCompact ? _buildCompact(context) : _buildSplit(context),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _buildCard(context, lightInputs: true),
          ),
        ),
      ),
    );
  }

  Widget _buildSplit(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            color: GridColors.secondaryDark,
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SafeLogoWidget(size: 72),
                  const SizedBox(height: 24),
                  const Text(
                    'Gestão completa para o seu escritório contábil',
                    style: TextStyle(
                      color: GridColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _bullet('Gestão completa do seu escritório contábil'),
                  _bullet('Acesso seguro e auditado'),
                  _bullet('Aprovação rápida pelo seu contador'),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Container(
            color: GridColors.background,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _buildCard(context, lightInputs: true),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: GridColors.textPrimary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: GridColors.textPrimaryMuted, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required bool lightInputs}) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: GridColors.shadow, blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: _sucesso ? _buildSucesso() : _buildFormulario(lightInputs),
    );
  }

  Widget _buildFormulario(bool lightInputs) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: GridColors.secondarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(6),
                child: _SafeLogoWidget(size: 48),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Solicitar Acesso',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GridColors.textSecondary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: const Text(
              'Preencha os dados abaixo para solicitar acesso ao sistema. '
              'Sua solicitação será analisada e você será avisado quando for aprovada.',
              textAlign: TextAlign.center,
              style: TextStyle(color: GridColors.textMuted, fontSize: 13),
            ),
          ),
          const SizedBox(height: 22),
          if (_erroServidor != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: GridColors.errorLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GridColors.error.withValues(alpha: 0.3)),
              ),
              child: Semantics(
                liveRegion: true,
                child: Text(_erroServidor ?? '',
                    style: const TextStyle(color: GridColors.errorDark, fontSize: 12)),
              ),
            ),
          _field(
            ctrl: _nomeCtrl,
            label: 'Nome completo',
            icon: Icons.person_outline,
            light: lightInputs,
            enabled: !_enviando,
            validator: (v) => _validarObrigatorio(v, 'Nome'),
          ),
          const SizedBox(height: 14),
          _field(
            ctrl: _emailCtrl,
            label: 'Email',
            icon: Icons.email_outlined,
            light: lightInputs,
            enabled: !_enviando,
            keyboardType: TextInputType.emailAddress,
            validator: _validarEmail,
          ),
          const SizedBox(height: 14),
          _field(
            ctrl: _senhaCtrl,
            label: 'Senha',
            icon: Icons.lock_outline,
            light: lightInputs,
            enabled: !_enviando,
            obscure: _obscureSenha,
            suffix: IconButton(
              onPressed: () => setState(() => _obscureSenha = !_obscureSenha),
              icon: Icon(
                _obscureSenha ? Icons.visibility_off : Icons.visibility,
                color: lightInputs ? GridColors.textMuted : Colors.white60,
                size: 18,
              ),
            ),
            validator: _validarSenha,
          ),
          const SizedBox(height: 14),
          _field(
            ctrl: _confirmarSenhaCtrl,
            label: 'Confirmar senha',
            icon: Icons.lock_outline,
            light: lightInputs,
            enabled: !_enviando,
            obscure: _obscureConfirmar,
            suffix: IconButton(
              onPressed: () =>
                  setState(() => _obscureConfirmar = !_obscureConfirmar),
              icon: Icon(
                _obscureConfirmar ? Icons.visibility_off : Icons.visibility,
                color: lightInputs ? GridColors.textMuted : Colors.white60,
                size: 18,
              ),
            ),
            validator: _validarConfirmarSenha,
          ),
          const SizedBox(height: 14),
          _field(
            ctrl: _cpfSolicitanteCtrl,
            label: 'Seu CPF',
            icon: Icons.badge_outlined,
            light: lightInputs,
            enabled: !_enviando,
            keyboardType: TextInputType.number,
            inputFormatters: [_CpfInputFormatter()],
            helperText: 'CPF pessoal de quem está solicitando o acesso',
            validator: _validarCpfSolicitante,
          ),
          const SizedBox(height: 14),
          _field(
            ctrl: _cpfCnpjCtrl,
            label: 'CPF ou CNPJ',
            icon: Icons.apartment_outlined,
            light: lightInputs,
            enabled: !_enviando,
            keyboardType: TextInputType.number,
            inputFormatters: [_CpfCnpjInputFormatter()],
            helperText: 'CPF ou CNPJ da empresa/escritório que você representa',
            validator: _validarCpfCnpj,
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.buttonBackground,
                foregroundColor: GridColors.buttonText,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _enviando ? null : _enviar,
              child: _enviando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Enviar Solicitação',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: _enviando ? null : () => Navigator.pop(context),
              child: Text('Voltar para o login',
                  style: TextStyle(
                      color: lightInputs ? GridColors.textMuted : Colors.white70)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSucesso() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mark_email_read_outlined, color: GridColors.success, size: 56),
        const SizedBox(height: 16),
        const Text(
          'Solicitação enviada!',
          style: TextStyle(
              color: GridColors.textSecondary, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        const Text(
          'Sua solicitação foi enviada para aprovação. Você será notificado por '
          'email quando ela for analisada.',
          textAlign: TextAlign.center,
          style: TextStyle(color: GridColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: GridColors.primary),
              foregroundColor: GridColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar para o login',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    required bool light,
    bool enabled = true,
    bool obscure = false,
    Widget? suffix,
    String? helperText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final fillColor = light ? GridColors.inputBackground : Colors.white.withValues(alpha: 0.1);
    final textColor = light ? GridColors.textSecondary : Colors.white;
    final hintColor = light ? GridColors.textMuted : Colors.white38;

    return TextFormField(
      controller: ctrl,
      enabled: enabled,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: TextStyle(color: textColor, fontSize: 13),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: hintColor, fontSize: 13),
        helperText: helperText,
        helperStyle: TextStyle(color: hintColor, fontSize: 11),
        prefixIcon: Icon(icon, color: light ? GridColors.textMuted : Colors.white54, size: 18),
        suffixIcon: suffix,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        filled: true,
        fillColor: fillColor,
        enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: GridColors.inputBorder, width: 1.5),
            borderRadius: BorderRadius.circular(8)),
        border: OutlineInputBorder(
            borderSide: const BorderSide(color: GridColors.inputBorder, width: 1.5),
            borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: GridColors.inputBorder, width: 2),
            borderRadius: BorderRadius.circular(8)),
        errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.orange, width: 1.5),
            borderRadius: BorderRadius.circular(8)),
        focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.orange, width: 2),
            borderRadius: BorderRadius.circular(8)),
        errorStyle: const TextStyle(color: Colors.orange, fontSize: 11),
      ),
    );
  }
}

/// Logo institucional com fallback gracioso para ícone.
class _SafeLogoWidget extends StatelessWidget {
  final double size;
  const _SafeLogoWidget({required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AssetsUtils.logoJPG,
      height: size,
      width: size,
      fit: BoxFit.contain,
      errorBuilder: (_, error, __) {
        return SizedBox(
          height: size,
          width: size,
          child: const Center(
            child: Icon(Icons.business_center, color: GridColors.secondary, size: 32),
          ),
        );
      },
    );
  }
}

/// Aplica máscara de CPF (11 dígitos) ou CNPJ (14 dígitos) conforme o usuário digita.
class _CpfCnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 14 ? digits.substring(0, 14) : digits;
    final isCnpj = limited.length > 11;
    final buffer = StringBuffer();
    if (isCnpj) {
      for (var i = 0; i < limited.length; i++) {
        buffer.write(limited[i]);
        if (i == 1 || i == 4) buffer.write('.');
        if (i == 7) buffer.write('/');
        if (i == 11) buffer.write('-');
      }
    } else {
      for (var i = 0; i < limited.length; i++) {
        buffer.write(limited[i]);
        if (i == 2 || i == 5) buffer.write('.');
        if (i == 8) buffer.write('-');
      }
    }
    final text = buffer.toString();
    return TextEditingValue(
        text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      buffer.write(limited[i]);
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('-');
    }
    final text = buffer.toString();
    return TextEditingValue(
        text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
