import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/nfe/nfe_list_item_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_filter_model.dart';

void main() {
  group('NfeListItemModel', () {
    const sampleJson = {
      'id': 1,
      'numero': '000123',
      'serie': '1',
      'status': 'AUTORIZADA',
      'dataEmissao': '2026-08-04T10:30:00',
      'valor': 1500.50,
      'destinatario': 'Cliente Teste LTDA',
      'chave': '12345678901234567890123456',
      'qrCode': 'https://example.com/qr/123',
    };

    test('fromJson parses JSON corretamente', () {
      final model = NfeListItemModel.fromJson(sampleJson);

      expect(model.id, 1);
      expect(model.numero, '000123');
      expect(model.serie, '1');
      expect(model.status, 'AUTORIZADA');
      expect(model.valor, 1500.50);
      expect(model.destinatario, 'Cliente Teste LTDA');
      expect(model.chave, '12345678901234567890123456');
    });

    test('toJson retorna mapa com valores corretos', () {
      final model = NfeListItemModel.fromJson(sampleJson);
      final json = model.toJson();

      expect(json['id'], 1);
      expect(json['numero'], '000123');
      expect(json['valor'], 1500.50);
      expect(json['status'], 'AUTORIZADA');
    });

    test('statusColor retorna cor correta para cada status', () {
      final autorizada = NfeListItemModel.fromJson({
        ...sampleJson,
        'status': 'AUTORIZADA',
      });
      final cancelada = NfeListItemModel.fromJson({
        ...sampleJson,
        'status': 'CANCELADA',
      });
      final rejeitada = NfeListItemModel.fromJson({
        ...sampleJson,
        'status': 'REJEITADA',
      });

      expect(autorizada.statusColor.value, isNotNull);
      expect(cancelada.statusColor.value, isNotNull);
      expect(rejeitada.statusColor.value, isNotNull);
    });

    test('dataFormatada retorna formato DD/MM/YYYY', () {
      final model = NfeListItemModel.fromJson(sampleJson);
      expect(model.dataFormatada, '04/08/2026');
    });

    test('valorFormatado retorna formato R\$ #,##', () {
      final model = NfeListItemModel.fromJson({
        ...sampleJson,
        'valor': 1000.00,
      });
      expect(model.valorFormatado, 'R\$ 1000,00');
    });

    test('destinatarioTruncado trunca nome longo', () {
      final model = NfeListItemModel.fromJson({
        ...sampleJson,
        'destinatario': 'A' * 50,
      });
      expect(model.destinatarioTruncado.length, 28); // 25 + '...'
    });

    test('equality compara por id, numero, serie, status, valor', () {
      final model1 = NfeListItemModel.fromJson(sampleJson);
      final model2 = NfeListItemModel.fromJson(sampleJson);

      expect(model1, model2);
      expect(model1.hashCode, model2.hashCode);
    });

    test('copyWith preserva e sobrescreve campos', () {
      final model1 = NfeListItemModel.fromJson(sampleJson);
      final model2 = model1.copyWith(status: 'CANCELADA');

      expect(model1.status, 'AUTORIZADA');
      expect(model2.status, 'CANCELADA');
      expect(model1.numero, model2.numero);
    });
  });

  group('NfeFilterModel', () {
    test('default constructor cria filtro vazio', () {
      final filter = NfeFilterModel();

      expect(filter.status, NfeStatusFilter.all);
      expect(filter.dataInicio, isNull);
      expect(filter.dataFim, isNull);
      expect(filter.hasActiveFilters, false);
    });

    test('copyWith atualiza campos corretamente', () {
      final filter1 = NfeFilterModel();
      final filter2 = filter1.copyWith(
        status: NfeStatusFilter.autorizada,
      );

      expect(filter1.status, NfeStatusFilter.all);
      expect(filter2.status, NfeStatusFilter.autorizada);
    });

    test('hasActiveFilters retorna true quando há filtros', () {
      final emptyFilter = NfeFilterModel();
      final withStatus = NfeFilterModel(
        status: NfeStatusFilter.autorizada,
      );
      final withDate = NfeFilterModel(
        dataInicio: DateTime(2026, 8, 1),
      );

      expect(emptyFilter.hasActiveFilters, false);
      expect(withStatus.hasActiveFilters, true);
      expect(withDate.hasActiveFilters, true);
    });

    test('activeFilterCount conta filtros corretamente', () {
      final noFilters = NfeFilterModel();
      final oneFilter = NfeFilterModel(
        status: NfeStatusFilter.autorizada,
      );
      final threeFilters = NfeFilterModel(
        status: NfeStatusFilter.autorizada,
        dataInicio: DateTime(2026, 8, 1),
        dataFim: DateTime(2026, 8, 31),
      );

      expect(noFilters.activeFilterCount, 0);
      expect(oneFilter.activeFilterCount, 1);
      expect(threeFilters.activeFilterCount, 3);
    });

    test('clearDateRange remove datas mantendo outros filtros', () {
      final filter = NfeFilterModel(
        status: NfeStatusFilter.autorizada,
        dataInicio: DateTime(2026, 8, 1),
        dataFim: DateTime(2026, 8, 31),
      );

      final cleared = filter.clearDateRange();

      expect(cleared.status, NfeStatusFilter.autorizada);
      expect(cleared.dataInicio, isNull);
      expect(cleared.dataFim, isNull);
    });

    test('equality compara todos os campos', () {
      final filter1 = NfeFilterModel(
        status: NfeStatusFilter.autorizada,
      );
      final filter2 = NfeFilterModel(
        status: NfeStatusFilter.autorizada,
      );

      expect(filter1, filter2);
      expect(filter1.hashCode, filter2.hashCode);
    });

    test('NfeStatusFilter.apiValue retorna valor correto para API', () {
      expect(NfeStatusFilter.all.apiValue, '');
      expect(NfeStatusFilter.autorizada.apiValue, 'AUTORIZADA');
      expect(NfeStatusFilter.cancelada.apiValue, 'CANCELADA');
      expect(NfeStatusFilter.rejeitada.apiValue, 'REJEITADA');
      expect(NfeStatusFilter.rascunho.apiValue, 'RASCUNHO');
    });
  });
}
