import 'package:flutter/material.dart';
import '../services/recuperacao_senha_service.dart';

import '../auth_screens/login_screen.dart';
import '../../../widgets/custom_password_text_field.dart';
import '../../../widgets/screen_background.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordTEController = TextEditingController();
  final TextEditingController _confirmPasswordTEController =
      TextEditingController();
  bool _isLoading = false;
  final GlobalKey<FormState> _resetFormKey = GlobalKey<FormState>();

  Future<void> resetPassword() async {
    if (!RecuperacaoSenhaService.senhaValida(_passwordTEController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('A senha precisa ter pelo menos 8 caracteres, com letras e números.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    _isLoading = true;
    if (mounted) {
      setState(() {});
    }

    final resultado = await RecuperacaoSenhaService.redefinirSenha(
        widget.email, widget.otp, _passwordTEController.text);
    _isLoading = false;
    if (mounted) {
      setState(() {});
    }
    if (resultado.ok) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false);
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
      body: ScreenBackground(
          child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Form(
            key: _resetFormKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Defina sua nova senha",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  'Mínimo de 8 caracteres, com letras e números',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(
                  height: 16,
                ),
                CustomPasswordTextFormField(
                  controller: _passwordTEController,
                  hintText: "Nova senha",
                  textInputType: TextInputType.text,
                ),
                const SizedBox(
                  height: 8,
                ),
                CustomPasswordTextFormField(
                  validator: (String? value) {
                    if (value?.isEmpty ?? true) {
                      return "Confirme a nova senha";
                    } else if ((value ?? '') != _passwordTEController.text) {
                      return "As senhas não conferem";
                    }
                    return null;
                  },
                  controller: _confirmPasswordTEController,
                  hintText: "Confirmar nova senha",
                  textInputType: TextInputType.text,
                ),
                const SizedBox(
                  height: 16,
                ),
                SizedBox(
                  width: double.infinity,
                  child: Visibility(
                    visible: _isLoading == false,
                    replacement: const Center(
                      child: CircularProgressIndicator(),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if ((_resetFormKey.currentState?.validate() ?? false) &&
                            _passwordTEController.text ==
                                _confirmPasswordTEController.text) {
                          resetPassword();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("A senha precisa ter pelo menos 8 caracteres, com letras e números."),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Icon(
                        Icons.arrow_circle_right_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Have an Account?",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(
                      width: 2,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()));
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(letterSpacing: .7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      )),
    );
  }
}
