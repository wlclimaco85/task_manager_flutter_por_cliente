import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/mobile/screens/transporte_motorista_screen.dart';
import 'package:task_manager_flutter/mobile/screens/transporte_veiculo_screen.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import 'package:task_manager_flutter/web/screens/transporte_motorista_grid_screen.dart';
import 'package:task_manager_flutter/web/screens/transporte_veiculo_grid_screen.dart';

/// Os campos precisam bater com os records de TransporteRequests (backend),
/// e Web/Windows e Mobile precisam expor os mesmos campos (paridade).
void main() {
  const camposVeiculo = [
    'placa', 'renavam', 'taraKg', 'capacidadeKg', 'tipoRodado',
    'tipoCarroceria', 'ufPlaca', 'ativo',
  ];
  const camposMotorista = ['nome', 'cpf', 'ativo'];

  test('veiculo: campos do form batem com o backend em Web e Mobile', () {
    expect(WebTransporteVeiculoGridScreen.fieldConfigs.map((f) => f.fieldName),
        camposVeiculo);
    expect(MobileTransporteVeiculoScreen.fieldConfigs.map((f) => f.fieldName),
        camposVeiculo);
  });

  test('motorista: campos do form batem com o backend em Web e Mobile', () {
    expect(
        WebTransporteMotoristaGridScreen.fieldConfigs.map((f) => f.fieldName),
        camposMotorista);
    expect(
        MobileTransporteMotoristaScreen.fieldConfigs.map((f) => f.fieldName),
        camposMotorista);
  });

  test('opcoes de rodado/carroceria seguem o esquema do MDF-e', () {
    expect(kTransporteTiposRodado.map((o) => o['value']),
        ['01', '02', '03', '04', '05', '06']);
    expect(kTransporteTiposCarroceria.map((o) => o['value']),
        ['00', '01', '02', '03', '04', '05']);
    expect(kTransporteUfs.length, 27);
  });

  test('endpoints apontam para /api/transporte', () {
    expect(ApiLinks.allTransporteVeiculos, endsWith('/api/transporte/veiculos'));
    expect(ApiLinks.transporteVeiculo(':id'),
        endsWith('/api/transporte/veiculos/:id'));
    expect(ApiLinks.allTransporteMotoristas,
        endsWith('/api/transporte/motoristas'));
    expect(ApiLinks.transporteMotorista(':id'),
        endsWith('/api/transporte/motoristas/:id'));
  });
}
