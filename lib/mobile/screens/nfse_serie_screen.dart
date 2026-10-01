import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../customization/generic_grid_card.dart';
import '../../../models/nfse_serie_model.dart';

/// Cadastro de séries de NFS-e — módulo NFS-e do cliente. CRUD via
/// `/api/nfse_serie` (NfseSerieController).
class NfseSerieScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  final VoidCallback? onUserBannerTapped;

  const NfseSerieScreen({
    super.key,
    required this.hasPermission,
    this.onUserBannerTapped,
  });

  @override
  Widget build(BuildContext context) {
    return GenericMobileGridScreen<NfseSerie>(
      title: 'Séries NFS-e',
      fetchEndpoint: ApiLinks.allNfseSerie,
      createEndpoint: ApiLinks.allNfseSerie,
      updateEndpoint: ApiLinks.nfseSerie(':id'),
      deleteEndpoint: ApiLinks.nfseSerie(':id'),
      fromJson: (json) => NfseSerie.fromJson(json),
      toJson: (obj) => obj.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: NfseSerie.fieldConfigs,
      idFieldName: 'id',
      useUserBannerAppBar: true,
      onUserBannerTapped: onUserBannerTapped,
      paginationConfig: const PaginationConfig(
        defaultRowsPerPage: 10,
        availableRowsPerPage: [10, 25, 50],
      ),
      enableSearch: true,
    );
  }
}
