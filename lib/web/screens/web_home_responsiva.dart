import 'package:flutter/material.dart';

import '../../mobile/screens/bottom_navbar_screen.dart';
import 'bottom_navbar_screen.dart';

/// Largura maxima (px, inclusive) em que o Flutter Web usa o layout mobile.
/// Celular abrindo o site no navegador cai em `kIsWeb`, mas a tela estreita quebrava o layout de desktop.
const double kLarguraMaximaMobileWeb = 599;

/// Tela inicial do Flutter Web: layout mobile em tela estreita (<= 599 px), layout web nas demais.
/// A decisao e pela largura atual, entao acompanha rotacao do aparelho e redimensionamento da janela.
class WebHomeResponsiva extends StatelessWidget {
  final WidgetBuilder? mobileBuilder;
  final WidgetBuilder? webBuilder;

  const WebHomeResponsiva({super.key, this.mobileBuilder, this.webBuilder});

  static bool usaLayoutMobile(double largura) => largura <= kLarguraMaximaMobileWeb;

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    if (usaLayoutMobile(largura)) {
      return (mobileBuilder ?? (_) => const BottomNavBarScreen())(context);
    }
    return (webBuilder ?? (_) => const WebBottomNavBarScreen())(context);
  }
}
