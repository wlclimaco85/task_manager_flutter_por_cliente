import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:task_manager_flutter/models/nfe/nfe_draft_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_draft_status.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nfe_draft_model_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(41)) {
      Hive.registerAdapter(NfeDraftModelAdapter());
    }
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('typeId do adapter é 41 (não colide com typeId 40 já usado no projeto)',
      () {
    expect(NfeDraftModelAdapter().typeId, 41);
  });

  test('round-trip real via Hive box preserva todos os campos, incluindo Map aninhado',
      () async {
    final box = await Hive.openBox<NfeDraftModel>('roundtrip_test');
    final original = NfeDraftModel(
      id: 'abc123',
      nfeIdReferencia: '999',
      dadosFormulario: {
        'numero': '42',
        'tomador': {'razaoSocial': 'Cliente Teste'},
      },
      acao: 'emitir',
      status: NfeDraftStatus.rascunho,
      criadoEm: DateTime(2026, 8, 11, 10, 0),
      atualizadoEm: DateTime(2026, 8, 11, 10, 0),
    );

    await box.put(original.id, original);
    await box.close();

    final reopened = await Hive.openBox<NfeDraftModel>('roundtrip_test');
    final lido = reopened.get('abc123')!;

    expect(lido.id, original.id);
    expect(lido.nfeIdReferencia, original.nfeIdReferencia);
    expect(lido.acao, 'emitir');
    expect(lido.status, NfeDraftStatus.rascunho);
    expect(lido.dadosFormulario['numero'], '42');
    expect(
      (lido.dadosFormulario['tomador'] as Map)['razaoSocial'],
      'Cliente Teste',
    );

    await reopened.deleteFromDisk();
  });

  test('NfeDraftStatus.fromCode mapeia corretamente e usa rascunho como fallback',
      () {
    expect(NfeDraftStatus.fromCode('ENVIADO'), NfeDraftStatus.enviado);
    expect(NfeDraftStatus.fromCode('conflito'), NfeDraftStatus.conflito);
    expect(NfeDraftStatus.fromCode('algo-invalido'), NfeDraftStatus.rascunho);
    expect(NfeDraftStatus.fromCode(null), NfeDraftStatus.rascunho);
  });
}
