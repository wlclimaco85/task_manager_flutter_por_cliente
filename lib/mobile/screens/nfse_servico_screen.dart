import 'package:flutter/material.dart';
import '../../widgets/user_banners.dart';

/// Tela stub para formulário de nova Nota de Serviço (NFS-e).
/// Reusa DynamicGridDynamicScreen em modo "create only" (sem listagem).
class NfseServicoScreen extends StatelessWidget {
  final Function(String action)? hasPermission;

  const NfseServicoScreen({
    super.key,
    this.hasPermission,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Nova Nota de Serviço',
      ),
      body: const Center(
        child: Text('Formulário de NFS-e em desenvolvimento'),
      ),
    );
  }
}
