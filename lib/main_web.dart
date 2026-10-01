import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:task_manager_flutter/core/theme/zen_theme.dart';
import 'package:task_manager_flutter/web/screens/splash_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  runApp(const TaskManagerWebApp());
}

class TaskManagerWebApp extends StatelessWidget {
  const TaskManagerWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestão Empresarial - Conta Própria',
      theme: ZenTheme.lightTheme,
      home: const WebSplashScreen(),
    );
  }
}
