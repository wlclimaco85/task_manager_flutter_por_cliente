import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/personal_model.dart';
import './details/personal_detail_screen.dart';

class WebPersonalGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WebPersonalGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<PersonalDto>(
      telaNome: 'personal',
      hasPermission: hasPermission,
      fromJson: (json) => PersonalDto.fromJson(json),
      toJson: (a) => a.toJson(),
      detailScreenBuilder: (item) => PersonalDetailScreen(
        item: item.toJson(),
        hasPermission: hasPermission,
      ),
    );
  }
}


