// Mobile Calendar Screen
// Re-exports the full-featured financial calendar for mobile use.

import 'package:flutter/material.dart';
import 'package:task_manager_flutter/windows/screens/documento_screen.dart';

/// Mobile alias — same calendar used in Windows/Web.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WindowsCalendarScreen();
  }
}
