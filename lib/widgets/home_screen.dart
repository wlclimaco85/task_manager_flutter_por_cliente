import '../../../widgets/stagger_animation.dart';
import 'package:flutter/material.dart';
import '../../widgets/responsive_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      mobileBuilder: (context, width) => StaggerAnimation(controller: _controller),
      tabletBuilder: (context, width) => SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            StaggerAnimation(controller: _controller),
            const SizedBox(height: 32),
          ],
        ),
      ),
      desktopBuilder: (context, width) => Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 64),
              StaggerAnimation(controller: _controller),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }
}
