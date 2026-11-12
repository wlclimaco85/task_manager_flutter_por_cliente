import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Marca (icone) do Prumo Contábil: fio de prumo em lima sobre verde escuro.
/// Identidade exclusiva do task_manager_flutter_por_cliente.
class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, required this.size});

  static const String assetPath = 'assets/images/prumo_mark.svg';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticsLabel: 'Prumo Contábil',
    );
  }
}
