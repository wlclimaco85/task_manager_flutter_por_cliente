import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Marca (icone) do PortalCont, identidade deste app white-label.
/// Nao usar o logo do Abraco aqui (pertence ao task_manager_flutter).
class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, required this.size});

  static const String assetPath = 'assets/images/portalcont_mark.svg';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticsLabel: 'PortalCont',
    );
  }
}
