import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';
import '../../utils/api_links.dart';
import '../../utils/parceiro_form_rules.dart';
import 'details/parceiro_detail_screen.dart';

/// Tela mobile de Fornecedores — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileFornecedorGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileFornecedorGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_fornecedor'),
      telaNome: 'parceiro',
      tituloOverride: 'Fornecedor',
      hasPermission: hasPermission ?? (p) => true,
      fieldOverrides: [
        ParceiroFormRules.mobileSupplierType(),
        ...ParceiroFormRules.mobileModuleSuppression(),
      ],
      transformFormData: ParceiroFormRules.removeSupplierTypeFromPayload,
      fetchEndpointOverride: ApiLinks.allFornecedores,
      createEndpointOverride: ApiLinks.createFornecedor,
      updateEndpointOverride: ApiLinks.updateFornecedor(':id'),
      deleteEndpointOverride: ApiLinks.deleteFornecedor(':id'),
      detailScreenBuilder: (item) => MobileWebParceiroDetailScreen(
        item: item,
        hasPermission: hasPermission ?? (p) => true,
        titleOverride: 'Fornecedor',
      ),
      storageKey: 'mobile_dynamic_fornecedor',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}
