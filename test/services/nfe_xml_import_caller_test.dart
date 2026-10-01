import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/services/nfe_xml_import_caller.dart';

/// Bug de produção: "Importar XML NF-e" falhava com
/// "Erro ao conectar: Unsupported operation: _Namespace" ao importar um XML
/// real de NF-e (modelo 55) pela versão Web.
///
/// Causa raiz: `NfeXmlImportCaller.preview`/`confirmar` recebiam o `filePath`
/// escolhido pelo FilePicker e reabriam o arquivo do disco via
/// `File(filePath).readAsBytes()` (dart:io). No Flutter Web, `dart:io` não
/// tem implementação real -- qualquer uso de `File` estoura
/// `UnsupportedError('Unsupported operation: _Namespace')` antes mesmo de
/// tentar a requisição HTTP. O FilePicker já é chamado com
/// `withData: true` e entrega os bytes prontos em `PlatformFile.bytes`;
/// esses testes garantem que o caller usa SOMENTE esses bytes, nunca
/// reabrindo nada do disco.
void main() {
  final xmlFalso = utf8.encode('<nfeProc><NFe>conteudo de teste</NFe></nfeProc>');

  group('NfeXmlImportCaller.preview', () {
    test('envia os bytes recebidos direto no multipart, sem tocar em disco',
        () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        // Bug de producao: apontava para '/api/fiscal/nfe-importacao/preview'
        // (404 -- rota nunca existiu). Rota real do backend
        // (NfeImportController) e '/api/nfe-import/importacao-xml/preview'.
        expect(request.url.path, contains('/api/nfe-import/importacao-xml/preview'));
        // MockClient finaliza o multipart e entrega o corpo já codificado
        // (boundary + headers de cada parte); o conteúdo do XML e o nome do
        // arquivo devem estar presentes ali -- prova de que os bytes vieram
        // só da memória (PlatformFile.bytes), nunca de leitura de disco.
        final corpo = latin1.decode(request.bodyBytes);
        expect(corpo, contains('nota-real.xml'));
        expect(corpo, contains(utf8.decode(xmlFalso)));
        // Bug de producao: o campo multipart era enviado como "file", mas
        // NfeImportController.preview espera @RequestParam("xml") -- o
        // backend nunca reconhecia o arquivo enviado.
        expect(corpo, contains('name="xml"'),
            reason: 'campo multipart deve se chamar "xml", igual ao '
                '@RequestParam("xml") do NfeImportController');
        return http.Response(jsonEncode({'chaveAcesso': '123'}), 200);
      });

      final result = await NfeXmlImportCaller.preview(
        Uint8List.fromList(xmlFalso),
        'nota-real.xml',
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

      final result = await NfeXmlImportCaller.preview(
        Uint8List.fromList(xmlFalso),
        'nota-real.xml',
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

  group('NfeXmlImportCaller.confirmar', () {
    test('também envia os bytes recebidos, sem exigir path de disco',
        () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'importado': true}), 201);
      });

      final result = await NfeXmlImportCaller.confirmar(
        Uint8List.fromList(xmlFalso),
        'nota-real.xml',
        client: client,
      );

      expect(result.success, isTrue);
    });
  });
}
