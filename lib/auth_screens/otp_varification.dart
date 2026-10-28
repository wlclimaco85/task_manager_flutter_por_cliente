import 'package:flutter/material.dart';
import '../services/recuperacao_senha_service.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../auth_screens/login_screen.dart';
import '../auth_screens/reset_screen.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/screen_background.dart';
import '../../../widgets/signup_button.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.email,
  });
  final String email;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final PinInputController _otpController = PinInputController();
  bool _isLoading = false;
  final GlobalKey<FormState> _otpFormKey = GlobalKey<FormState>();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> otpVerify() async {
    _isLoading = true;
    setState(() {});

    final resultado = await RecuperacaoSenhaService.validarCodigo(
        widget.email, _otpController.text.trim());

    _isLoading = false;
    setState(() {});
    final BuildContext context = this.context;
    if (resultado.ok) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              email: widget.email,
              otp: _otpController.text.trim(),
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.mensagem),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: ScreenBackground(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                Text(
                  "VERIFICAÇÃO DO CÓDIGO",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  "Enviamos um código de 6 dígitos para o seu e-mail. Digite-o abaixo para continuar.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 16),
                Form(
                  key: _otpFormKey,
                  child: MaterialPinField(
                    pinController: _otpController,
                    length: 6,
                    keyboardType: TextInputType.number,
                    theme: MaterialPinTheme(
                      shape: MaterialPinShape.outlined,
                      cellSize: const Size(50, 50),
                      borderRadius: BorderRadius.circular(5),
                      borderWidth: 0.5,
                      fillColor: Colors.white,
                      focusedFillColor: Colors.white,
                      completeFillColor: Colors.white,
                      borderColor: Colors.white,
                      focusedBorderColor: Colors.green,
                      completeBorderColor: Colors.white,
                      followingBorderColor: Colors.white,
                      cursorColor: Colors.green,
                      entryAnimation: MaterialPinAnimation.fade,
                      animationDuration: const Duration(milliseconds: 300),
                    ),
                  ),
                ),
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : CustomButton(
                        onPresse: () {
                          otpVerify();
                        },
                        labels: "Validar código",
                      ),
                const SizedBox(
                  height: 16,
                ),
                SignUpButton(
                  text: "Já tem conta?",
                  onPresse: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()));
                  },
                  buttonText: 'Entrar',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
