import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/services/extrato_import_caller.dart';

/// Bug de produção: confirmar a importação de um extrato bancário falhava
/// sempre com 500 "Required part 'arquivo' is not present." (reproduzido
/// com um PDF de extrato real via a tela "Importação de Extrato Bancário").
///
/// Causa raiz: ExtratoImportCaller.preview/confirmar enviavam o arquivo no
/// campo multipart "file", mas ExtratoImportacaoController espera
/// @RequestParam("arquivo") MultipartFile arquivo -- o backend nunca
/// reconhecia o arquivo enviado, em nenhuma das duas chamadas.
void main() {
  final pdfFalso = utf8.encode('conteudo de extrato de teste');
  final arquivo = PlatformFile(
    name: 'extrato.pdf',
    size: pdfFalso.length,
    bytes: Uint8List.fromList(pdfFalso),
  );

  group('ExtratoImportCaller.preview', () {
    test('envia o arquivo no campo multipart "arquivo", não "file"',
        () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        final corpo = latin1.decode(request.bodyBytes);
        expect(corpo, contains('extrato.pdf'));
        expect(corpo, contains('name="arquivo"'),
            reason: 'campo multipart deve se chamar "arquivo", igual ao '
                '@RequestParam("arquivo") do ExtratoImportacaoController '
                '-- "file" é o bug de produção que causava 500 "Required '
                'part \'arquivo\' is not present."');
        expect(corpo, isNot(contains('name="file"')));
        return http.Response(jsonEncode({'ok': true}), 200);
      });

      final result = await ExtratoImportCaller.preview(
        contaBancariaId: 1,
        arquivo: arquivo,
        client: client,
      );

      expect(result.success, isTrue);
    });
  });

  group('ExtratoImportCaller.confirmar', () {
    test('envia o arquivo no campo multipart "arquivo", não "file"',
        () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        final corpo = latin1.decode(request.bodyBytes);
        expect(corpo, contains('extrato.pdf'));
        expect(corpo, contains('name="arquivo"'),
            reason: 'bug de produção reportado: 500 "Required part '
                '\'arquivo\' is not present." em POST '
                '/api/financeiro/extrato-importacao/confirmar, causado '
                'pelo campo multipart errado ("file" em vez de "arquivo")');
        expect(corpo, isNot(contains('name="file"')));
        return http.Response(jsonEncode({'id': 1, 'status': 'CONFIRMADO'}), 200);
      });

      final result = await ExtratoImportCaller.confirmar(
        contaBancariaId: 1,
        arquivo: arquivo,
        client: client,
      );

      expect(result.success, isTrue,
          reason: 'confirmar deve funcionar assim que o backend reconhece '
              'o campo multipart "arquivo"');
    });

    test('erro do backend (500) é reportado com a mensagem real', () async {
      final client = MockClient((request) async {
        return http.Response(
            jsonEncode({'message': "Required part 'arquivo' is not present."}),
            500);
      });

      final result = await ExtratoImportCaller.confirmar(
        contaBancariaId: 1,
        arquivo: arquivo,
        client: client,
      );

      expect(result.success, isFalse);
      expect(result.message, contains("Required part 'arquivo'"));
    });
  });
}
