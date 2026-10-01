import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../models/auth_utility.dart';
import '../../auth_screens/login_screen.dart';
import '../../windows/screens/bottom_navbar_screen.dart';
import '../../../utils/assets_utils.dart';
import '../../../widgets/screen_background.dart';

class WindowsSplashScreen extends StatefulWidget {
  const WindowsSplashScreen({super.key});

  @override
  State<WindowsSplashScreen> createState() => _WindowsSplashScreenState();
}

class _WindowsSplashScreenState extends State<WindowsSplashScreen> {
  @override
  void initState() {
    navigateToLogin();
    super.initState();
  }

  void navigateToLogin() {
    //another way to impliment splash screen;
    // await Future.delayed(Duration(seconds: 4));
    // Navigator.pushAndRemoveUntil(
    //   context,
    //   MaterialPageRoute(builder: (context) => const LoginScreen()),
    //       (route) => false,
    // );
    Future.delayed(const Duration(seconds: 3)).then((_) async {
      final bool loggedIn = await AuthUtility.isUserLoggedIn();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => loggedIn
                  ? const WindowsBottomNavBarScreen()
                  : const LoginScreen()),
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
          child: SvgPicture.asset(
            AssetsUtils.logoSVG,
            width: 90,
            fit: BoxFit.scaleDown,
          ),
        ),
      ),
    );
  }
}
