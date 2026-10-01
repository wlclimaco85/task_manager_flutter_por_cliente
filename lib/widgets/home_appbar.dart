import 'package:flutter/material.dart';
import '../utils/grid_colors.dart';

AppBar getHomeAppBar() {
  return AppBar(
    title: const Text("Minhas Academias"),
    centerTitle: true,
    backgroundColor: GridColors.primary,
    foregroundColor: GridColors.textPrimary,
    actions: [
      IconButton(
        icon: const Icon(
          Icons.more_vert_rounded,
          color: GridColors.textPrimary,
        ),
        onPressed: () {},
      ),
    ],
  );
}
