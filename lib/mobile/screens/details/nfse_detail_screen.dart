import 'package:flutter/material.dart';

import '../../../web/screens/details/nfse_detail_screen.dart' as web;

class MobileNfseDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;

  const MobileNfseDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return web.NfseDetailScreen(item: item);
  }
}
