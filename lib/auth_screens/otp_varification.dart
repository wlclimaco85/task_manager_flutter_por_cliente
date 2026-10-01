import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../utils/api_links.dart';
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

    NetworkResponse response = await NetworkCaller().getRequest(
        ApiLinks.recoverVerifyOTP(widget.email, _otpController.text.trim()));

    _isLoading = false;
    setState(() {});
    final BuildContext context = this.context;
    if (response.statusCode == 200 && response.body?['status'] == 'success') {
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
          const SnackBar(
            content: Text("Please enter valid OTP"),
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
                  "PIN VERIFICATION",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  "A 6 digit code has been sent to your email address. Please enter it below to continue.",
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
                        labels: "teste",
                      ),
                const SizedBox(
                  height: 16,
                ),
                SignUpButton(
                  text: "Have An Account?",
                  onPresse: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()));
                  },
                  buttonText: 'Login',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
