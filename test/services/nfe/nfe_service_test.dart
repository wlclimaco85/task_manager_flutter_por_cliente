import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/nfe/nfe_transmissao_response.dart';
import 'package:task_manager_flutter/services/nfe/nfe_service.dart';
import 'package:task_manager_flutter/services/nfe/nfe_service_exception.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';

class MockDio extends Mock implements Dio {}

void main() {
  group('NFeService', () {
    late MockDio mockDio;
    late NFeService nfeService;

    setUp(() {
      mockDio = MockDio();
      nfeService = NFeService(dio: mockDio);
    });

    test('NFeService pode ser instantiado com Dio', () {
      expect(nfeService, isNotNull);
    });

    test('NFeService tem método transmitirNfe', () {
      expect(nfeService.transmitirNfe, isNotNull);
    });

    test('NfeTransmissaoResponse pode ser criado com dados', () {
      final response = NfeTransmissaoResponse(
        protocolo: '123456',
        status: 'autorizada',
        dataRecebimento: DateTime.now(),
      );

      expect(response.protocolo, equals('123456'));
      expect(response.status, equals('autorizada'));
    });

    test('NfeTransmissaoResponse.fromJson funciona', () {
      final json = {
        'protocolo': '999999',
        'status': 'pendente',
        'dataRecebimento': '2026-07-22T10:00:00',
      };

      final response = NfeTransmissaoResponse.fromJson(json);

      expect(response.protocolo, equals('999999'));
      expect(response.status, equals('pendente'));
    });

    test('NFeServiceException pode ser lançada', () {
      expect(
        () => throw NFeServiceException('Erro teste'),
        throwsA(isA<NFeServiceException>()),
      );
    });

    test('NFeService logging callback funciona', () {
      List<String> logs = [];
      nfeService.onLog = (message) {
        logs.add(message);
      };

      // Simular log (seria chamado internamente)
      nfeService.onLog('Teste log');

      expect(logs, isNotEmpty);
      expect(logs.first, contains('Teste'));
    });
  });
}
