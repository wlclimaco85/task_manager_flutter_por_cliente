import 'package:flutter/material.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../screens/ForgotPasswordScreen_screens.dart';
import '../screens/SignUpScreen_screens.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_texts.dart';
import '../../../models/auth_utility.dart';
import '../../../models/login_model.dart';

class LoginPopup extends StatefulWidget {
  const LoginPopup({super.key});

  @override
  _LoginPopupState createState() => _LoginPopupState();
}

class _LoginPopupState extends State<LoginPopup> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? errorMessage; // Armazena mensagens de erro
  bool isLoading = false;

  /// Validador de email com regex RFC 5322 básico
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> loginss(String username, String password) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    Map<String, dynamic> requestBody = {
      "email": username,
      "password": password,
    };

    try {
      final NetworkResponse response =
          await NetworkCaller().postRequest(ApiLinks.login, requestBody);

      setState(() {
        isLoading = false;
      });

      if (response.isSuccess) {
        LoginModel model = LoginModel.fromJson(response.body!);
        await AuthUtility.setUserInfo(model);

        if (mounted) {
          AuthUtility.userInfo?.token = model.token;
          Navigator.of(context).pop();
        }
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        setState(() {
          errorMessage = GridTexts.loginPopupInvalidCredentials;
        });
        // Exibir SnackBar de erro
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage ?? 'Erro ao fazer login'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() {
          errorMessage = 'Erro: ${response.statusCode}';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage ?? 'Erro desconhecido'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erro: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Erro de conexão'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitLogin() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = GridTexts.loginPopupFillFields;
      });
      return;
    }

    if (!_isValidEmail(username)) {
      setState(() {
        errorMessage = 'Email inválido';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira um email válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await loginss(username, password);
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 231, 247, 233),
      title: const Text(
        GridTexts.loginPopupTitle,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: GridTexts.loginUserHint,
                labelStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: const Color.fromARGB(255, 128, 202, 132),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: GridTexts.loginPasswordHint,
                labelStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: const Color.fromARGB(255, 128, 202, 132),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 5),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton(
                  onPressed: _navigateToForgotPassword,
                  child: const Text(
                    GridTexts.forgotPassword,
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: _navigateToSignUp,
                  child: const Text(
                    GridTexts.loginPopupCreateUser,
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 128, 202, 132),
          ),
          child: const Text(
            GridTexts.cancel,
            style: TextStyle(color: Colors.white),
          ),
        ),
        if (isLoading)
          const CircularProgressIndicator()
        else
          ElevatedButton(
            onPressed: _submitLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 128, 202, 132),
            ),
            child: const Text(
              GridTexts.loginPopupEnter,
              style: TextStyle(color: Colors.white),
            ),
          ),
      ],
    );
  }
}
