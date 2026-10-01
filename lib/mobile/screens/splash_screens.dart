import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';
import '../../../models/auth_utility.dart';
import '../../auth_screens/login_screen.dart';
import '../screens/bottom_navbar_screen.dart';
import '../../../utils/assets_utils.dart';
import '../../../widgets/screen_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    navigateToLogin();
  }

  void navigateToLogin() {
    Future.delayed(const Duration(seconds: 3)).then((_) async {
      if (mounted) {
        final bool loggedIn = await AuthUtility.isUserLoggedIn();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                loggedIn ? const BottomNavBarScreen() : const LoginScreen(),
          ),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo SVG
              SvgPicture.asset(
                AssetsUtils.logoSVG,
                width: 90,
                height: 90,
                fit: BoxFit.contain,
                placeholderBuilder: (context) => const SizedBox(
                  width: 90,
                  height: 90,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: GridColors.textPrimary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Texto "Carregando..."
              const Text(
                GridTexts.splashLoading,
                style: TextStyle(
                  color: GridColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 20),

              // Indicador de loading
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    GridColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
