// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../services/recuperacao_senha_service.dart';
import '../auth_screens/otp_varification.dart';
import '../../../widgets/custom_text_form_field.dart';
import '../../../widgets/screen_background.dart';
import '../../../widgets/signup_button.dart';

class EmailVarificationScreeen extends StatefulWidget {
  const EmailVarificationScreeen({super.key});

  @override
  State<EmailVarificationScreeen> createState() =>
      _EmailVarificationScreeenState();
}

class _EmailVarificationScreeenState extends State<EmailVarificationScreeen> {
  final TextEditingController _emailTEController = TextEditingController();
  bool _isLoading = false;
  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> emailVerify(String email) async {
    _isLoading = true;
    if (mounted) {
      setState(() {});
    }

    final resultado =
        await RecuperacaoSenhaService.solicitarCodigo(email);

    _isLoading = false;
    if (mounted) {
      setState(() {});
    }
    if (resultado.ok) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                    email: _emailTEController.text.trim(),
                  )));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado.mensagem),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  dispose() {
    super.dispose();
    _emailTEController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: ScreenBackground(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 80,
                ),
                Text(
                  "Seu e-mail",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  "Informe seu e-mail para receber um código de verificação",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 16),
                Form(
                    key: _emailFormKey,
                    child: CustomTextFormField(
                      validator: (value) {
                        if ((value ?? '').isEmpty ||
                            !RegExp(r'^[\w-.]+@([\w-]+\.)+\w{2,5}')
                                .hasMatch(value ?? '')) {
                          return "Informe um e-mail válido";
                        } else {
                          return null;
                        }
                      },
                      hintText: "E-mail",
                      controller: _emailTEController,
                      textInputType: TextInputType.emailAddress,
                    )),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Visibility(
                    visible: _isLoading == false,
                    replacement: const Center(
                      child: CircularProgressIndicator(),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (_emailFormKey.currentState?.validate() ?? false) {
                          emailVerify(_emailTEController.text.trim());
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
                SignUpButton(
                  text: "Já tem conta?",
                  onPresse: () {
                    Navigator.pop(context);
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
