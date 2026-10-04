import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../mobile/screens/bottom_navbar_screen.dart';
import '../../windows/screens/bottom_navbar_screen.dart';
import '../../web/screens/bottom_navbar_screen.dart';
import '../../models/auth_utility.dart';
import '../../models/login_model.dart';
import '../../models/network_response.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';
import '../../utils/security_matrix.dart';
import '../../core/theme/zen_theme.dart';
import '../../widgets/app_loading_overlay.dart';
import '../services/network_caller.dart';
import 'email_verification_screeen.dart';
import 'solicitacao_acesso_screen.dart';

/// Tela de Login oficial do App Conta Própria (SaaS B2B Gestão Direta).
/// Design System "Serene Zen Management" com foco em clareza, tranquilidade e leveza.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loginInProgress = false;
  bool _obscurePassword = true;
  String _loginStepMessage = 'Autenticando credenciais...';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goHome() {
    if (kIsWeb) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WebBottomNavBarScreen()),
          (_) => false);
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WindowsBottomNavBarScreen()),
          (_) => false);
    } else {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const BottomNavBarScreen()),
          (_) => false);
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _loginInProgress = true;
      _loginStepMessage = 'Autenticando credenciais...';
    });

    NetworkResponse resp;
    try {
      resp = await NetworkCaller().postRequest(ApiLinks.login, {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      });
    } catch (e) {
      if (mounted) setState(() => _loginInProgress = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao conectar: $e',
              style: const TextStyle(color: Colors.white)),
          backgroundColor: GridColors.error,
        ));
      }
      return;
    }

    if (resp.isSuccess && resp.body != null) {
      final model = LoginModel.fromJson(resp.body!);
      if ((model.token ?? '').isEmpty) {
        if (mounted) {
          setState(() => _loginInProgress = false);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(GridTexts.loginTokenMissing)));
        }
        return;
      }

      if (mounted) {
        setState(() => _loginStepMessage = 'Carregando módulos e permissões...');
      }
      await AuthUtility.setUserInfo(model);
      ModuloAccess.reset();
      await ModuloAccess.load();

      if (!mounted) return;
      _goHome();
    } else if (mounted) {
      setState(() => _loginInProgress = false);
      _passwordController.clear();
      final msg = resp.statusCode == 400 || resp.statusCode == 401
          ? GridTexts.loginInvalidCredentials
          : resp.statusCode == -1
              ? GridTexts.loginNoConnection
              : 'Erro ao autenticar (código ${resp.statusCode})';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: GridColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    return Scaffold(
      backgroundColor: GridColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
              ),
            ),
          ),
          if (_loginInProgress)
            Positioned.fill(
              child: AppLoadingOverlay(
                title: 'Iniciando Sessão',
                message: _loginStepMessage,
                isFullScreen: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1000),
      decoration: ZenTheme.zenCardDecoration(radius: 20),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Painel lateral sereno (Hero Branding)
            Expanded(
              flex: 5,
              child: Container(
                color: GridColors.primaryDark,
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.chartPie,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Gestão Direta &\nConta Própria',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tome decisões com serenidade. Fluxo de caixa em tempo real, controle de itens e emissão ágil para o seu negócio.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 36),
                    _buildFeaturePill(Icons.check_circle_outline, 'Fluxo de Caixa e Extrato Unificado'),
                    const SizedBox(height: 12),
                    _buildFeaturePill(Icons.check_circle_outline, 'Contas a Pagar e Receber Sem Fricção'),
                    const SizedBox(height: 12),
                    _buildFeaturePill(Icons.check_circle_outline, 'Vendas e Emissão de Cupons/Notas'),

                  ],
                ),
              ),
            ),

            // Formulário de Login
            Expanded(
              flex: 6,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: _buildLoginForm(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.all(28),
      decoration: ZenTheme.zenCardDecoration(radius: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: GridColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const FaIcon(
              FontAwesomeIcons.chartPie,
              color: GridColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Gestão Conta Própria',
            style: TextStyle(
              color: GridColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Acesse o painel executivo da sua empresa',
            style: TextStyle(
              color: GridColors.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _buildLoginForm(),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Bem-vindo de volta',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: GridColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Informe seus dados de acesso para continuar',
            style: TextStyle(fontSize: 13, color: GridColors.textSecondary),
          ),
          const SizedBox(height: 28),

          // Campo E-mail
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              hintText: 'seu@email.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe seu e-mail';
              }
              if (!value.contains('@')) {
                return 'E-mail inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Campo Senha
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _login(),
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Informe sua senha';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Esqueci minha senha
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmailVarificationScreeen()),

                );
              },
              child: const Text(
                'Esqueci minha senha',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Botão Entrar
          ElevatedButton(
            onPressed: _loginInProgress ? null : _login,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _loginInProgress
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Entrar no Sistema',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 24),

          // Link para criar conta / onboarding da empresa
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Não tem uma conta? ',
                style: TextStyle(fontSize: 13, color: GridColors.textSecondary),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SolicitacaoAcessoScreen()),
                  );
                },
                child: const Text(
                  'Cadastre sua Empresa',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: GridColors.primaryLight, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

}
