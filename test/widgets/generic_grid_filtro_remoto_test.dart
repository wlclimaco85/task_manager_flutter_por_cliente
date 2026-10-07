import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Bug: filtros Parceiro/Fornecedor (dropdownRemoteSearch) ficavam para sempre em
  // "carregando", pois o painel de filtros esperava um cache que nunca era preenchido
  // para campos com busca remota.
  test('filtro de campo com busca remota nao espera cache e usa o dialogo remoto', () {
    final source = File('lib/widgets/generic_grid_windows_screen.dart')
        .readAsStringSync();
    final inicio = source.indexOf('Widget _buildFilterDropdown');
    expect(inicio, greaterThan(0));
    final trecho = source.substring(inicio, inicio + 7000);

    expect(trecho, contains('final remoteSearch = config.dropdownRemoteSearch;'));
    expect(trecho, contains('cached == null && remoteSearch == null'));
    expect(trecho, contains('RemoteDropdownSearchDialog('));
    expect(trecho, contains('loadPage: remoteSearch'));
  });
}
