import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/asset_loader.dart';

void main() {
  test('AssetLoader mantem o caminho original do asset', () {
    expect(
      AssetLoader.correctAssetPath('assets/images/logo_contabilidade.jpg'),
      'assets/images/logo_contabilidade.jpg',
    );
  });

  test('AssetLoader remove prefixos duplicados de assets', () {
    expect(
      AssetLoader.correctAssetPath(
        'assets/assets/assets/images/logo_contabilidade.jpg',
      ),
      'assets/images/logo_contabilidade.jpg',
    );
  });

  testWidgets('AssetLoader fallback cabe em logo pequeno', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: AssetLoader.loadImage(
            'assets/images/asset-inexistente.png',
            width: 30,
            height: 30,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.broken_image), findsOneWidget);
  });
}
