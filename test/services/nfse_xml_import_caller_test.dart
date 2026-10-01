import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/services/nfse_xml_import_caller.dart';

/// Bug real (2026-09-18, ver bugs.md): "Importar XML NFS-e" falhava com
/// "Erro ao conectar: Unsupported operation: _Namespace" ao importar um XML
/// real de NFS-e pela versão Web -- mesma classe de bug já corrigida (e
/// depois regredida por um commit não relacionado) em NfeXmlImportCaller.
///
/// Causa raiz: `NfseXmlImportCaller.preview`/`confirmar` reabriam o arquivo
/// via `File(filePath).readAsBytes()` (dart:io), que não tem implementação
/// real no Flutter Web. A tela já carrega os bytes via
/// `FilePicker.pickFiles(withData: true)` -- estes testes garantem que o
/// caller usa SOMENTE `PlatformFile.bytes`, nunca reabrindo nada do disco.
void main() {
  final xmlFalso = utf8.encode('<CompNfse><Nfse>conteudo de teste</Nfse></CompNfse>');

  group('NfseXmlImportCaller.preview', () {
    test('envia os bytes recebidos direto no multipart, sem tocar em disco',
        () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path,
            contains('/api/nfse-import/importacao-xml/preview'));
        final corpo = latin1.decode(request.bodyBytes);
        expect(corpo, contains('nfse-real.xml'));
        expect(corpo, contains(utf8.decode(xmlFalso)));
        // Campo multipart deve se chamar "xml", igual ao
        // @RequestParam("xml") do NfseImportController.
        expect(corpo, contains('name="xml"'));
        return http.Response(jsonEncode({'chaveAcesso': '123'}), 200);
      });

      final result = await NfseXmlImportCaller.preview(
        Uint8List.fromList(xmlFalso),
        'nfse-real.xml',
        client: client,
      );

      expect(result.success, isTrue,
          reason: 'preview deve funcionar só com bytes em memória, sem '
              'depender de um arquivo existente em disco (cenário Web real)');
    });

    test('erro de rede vira "Erro ao conectar: ..." sem UnsupportedError',
        () async {
      final client = MockClient((request) async {
        throw http.ClientException('falha de conexao simulada');
      });

      final result = await NfseXmlImportCaller.preview(
        Uint8List.fromList(xmlFalso),
        'nfse-real.xml',
        client: client,
      );

      expect(result.success, isFalse);
      expect(result.message, contains('Erro ao conectar'));
      expect(result.message, isNot(contains('_Namespace')),
          reason: 'reprodução do bug real: com o File(filePath) antigo, '
              'essa mensagem virava "Erro ao conectar: Unsupported '
              'operation: _Namespace" no Flutter Web');
    });
  });

  group('NfseXmlImportCaller.confirmar', () {
    test('também envia os bytes recebidos, sem exigir path de disco',
        () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'importado': true}), 201);
      });

      final result = await NfseXmlImportCaller.confirmar(
        Uint8List.fromList(xmlFalso),
        'nfse-real.xml',
        client: client,
      );

      expect(result.success, isTrue);
    });

    test('envia o campo conciliacao quando produtoId ou criarNovoProduto informados',
        () async {
      final client = MockClient((request) async {
        final corpo = latin1.decode(request.bodyBytes);
        expect(corpo, contains('conciliacao'));
        expect(corpo, contains('criarNovoProduto'));
        return http.Response(jsonEncode({'importado': true}), 201);
      });

      final result = await NfseXmlImportCaller.confirmar(
        Uint8List.fromList(xmlFalso),
        'nfse-real.xml',
        criarNovoProduto: true,
        client: client,
      );

      expect(result.success, isTrue);
    });
  });
}
