import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mypet_app/widgets/app_image.dart';

void main() {
  const dataUrl =
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

  group('appImageProvider', () {
    test('retorna null para url nula ou vazia', () {
      expect(appImageProvider(null), isNull);
      expect(appImageProvider(''), isNull);
    });

    test('decodifica data URL base64 em MemoryImage', () {
      expect(appImageProvider(dataUrl), isA<MemoryImage>());
    });

    test('usa NetworkImage para URL de rede', () {
      expect(appImageProvider('https://x.com/foto.png'), isA<NetworkImage>());
    });

    test('retorna null para data URL base64 inválida', () {
      expect(appImageProvider('data:image/png;base64,@@@nao-base64@@@'), isNull);
    });
  });

  group('dataUrlFromBytes', () {
    test('gera data URL jpeg base64 reversível', () {
      final bytes = Uint8List.fromList([10, 20, 30, 40, 255]);
      final url = dataUrlFromBytes(bytes);
      expect(url, startsWith('data:image/jpeg;base64,'));
      final decoded = base64Decode(url.split(',').last);
      expect(decoded, equals(bytes));
    });
  });

  group('PhotoBox', () {
    Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

    testWidgets('mostra o fallback (ícone) quando não há foto', (tester) async {
      await tester.pumpWidget(wrap(const PhotoBox(
        url: null,
        size: 46,
        background: Colors.grey,
        fallback: Icon(Icons.person, key: Key('fallback-icon')),
      )));

      expect(find.byKey(const Key('fallback-icon')), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('mostra a foto (Image) quando há url, sem o fallback',
        (tester) async {
      await tester.pumpWidget(wrap(const PhotoBox(
        url: dataUrl,
        size: 46,
        background: Colors.grey,
        fallback: Icon(Icons.person, key: Key('fallback-icon')),
      )));

      expect(find.byType(Image), findsOneWidget);
      expect(find.byKey(const Key('fallback-icon')), findsNothing);
    });
  });
}
