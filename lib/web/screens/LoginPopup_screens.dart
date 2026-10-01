import 'package:flutter/material.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import './ForgotPasswordScreen_screens.dart';
import './SignUpScreen_screens.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_texts.dart';
import '../../../models/auth_utility.dart';
import '../../../models/login_model.dart';

class WebLoginPopup extends StatefulWidget {
  const WebLoginPopup({super.key});

  @override
  _WebLoginPopupState createState() => _WebLoginPopupState();
}

class _WebLoginPopupState extends State<WebLoginPopup> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? errorMessage; // Armazena mensagens de erro
  bool isLoading = false;

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
      final NetworkResponse response = await NetworkCaller().postRequest(
        ApiLinks.login,
        requestBody,
      );

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
      } else if (response.statusCode == 400) {
        setState(() {
          errorMessage = GridTexts.loginPopupInvalidCredentials;
        });
      } else {
        setState(() {
          errorMessage = 'Erro: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erro: $e';
      });
    }
  }

  Future<void> _submitLogin() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    if (username.isNotEmpty && password.isNotEmpty) {
      await loginss(username, password);
    } else {
      setState(() {
        errorMessage = GridTexts.loginPopupFillFields;
      });
    }
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WebForgotPasswordScreen()),
    );
  }

  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WebSignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 231, 247, 233),
      title: const Text(GridTexts.loginPopupTitle, style: TextStyle(fontWeight: FontWeight.bold)),
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
              Text(errorMessage!, style: const TextStyle(color: Colors.red)),
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
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _navigateToSignUp,
                  child: const Text(
                    GridTexts.loginPopupCreateUser,
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
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
          child: const Text(GridTexts.cancel, style: TextStyle(color: Colors.white)),
        ),
        if (isLoading)
          const CircularProgressIndicator()
        else
          ElevatedButton(
            onPressed: _submitLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 128, 202, 132),
            ),
            child: const Text(GridTexts.loginPopupEnter, style: TextStyle(color: Colors.white)),
          ),
      ],
    );
  }
}
