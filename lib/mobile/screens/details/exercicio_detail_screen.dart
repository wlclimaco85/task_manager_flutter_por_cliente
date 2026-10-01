import 'package:flutter/material.dart';
import '../../../../web/screens/details/exercicio_detail_screen.dart' as web;
import '../../../../widgets/user_banners.dart';
import '../../../../customization/dynamic_grid_dynamic_screen.dart';

class MobileExercicioDetailScreen extends StatelessWidget {
  final Map<String, dynamic>? item;
  final bool Function(String)? hasPermission;

  const MobileExercicioDetailScreen({super.key, this.item, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Exercício',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: item != null
            ? web.ExercicioDetailScreen(item: item!, hasPermission: hasPermission ?? ((_) => true))
            : DynamicGridDynamicScreen(
                telaNome: 'exercicio',
                hasPermission: hasPermission ?? ((_) => true),
                showAppBar: false,
              ),
      ),
    );
  }
}
