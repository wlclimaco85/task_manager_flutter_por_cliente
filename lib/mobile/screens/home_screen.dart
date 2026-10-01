import 'package:flutter/material.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    AppLogger.i.initCapture();
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
