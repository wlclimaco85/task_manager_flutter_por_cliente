import 'package:flutter/material.dart';
import '../../web/screens/certificado_empresa_screen.dart' as web;
import '../../widgets/user_banners.dart';
import '../../utils/tenant_context.dart';
import '../../../models/auth_utility.dart';

class MobileCertificadoEmpresaScreen extends StatelessWidget {
  final int? empresaId;
  final int? parceiroId;
  final String? empresaNome;

  const MobileCertificadoEmpresaScreen({
    super.key,
    this.empresaId,
    this.parceiroId,
    this.empresaNome,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveEmpresaId = empresaId ?? (parceiroId == null ? (TenantContext.empresaId ?? 1) : null);
    final effectiveParceiroId = parceiroId ?? TenantContext.parceiroId;
    final effectiveNome = empresaNome ?? AuthUtility.userInfo?.login?.empresa?.nome ?? 'Empresa';

    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Certificado Digital',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.CertificadoEmpresaScreen(
          empresaId: effectiveEmpresaId,
          parceiroId: effectiveParceiroId,
          empresaNome: effectiveNome,
        ),
      ),
    );
  }
}
