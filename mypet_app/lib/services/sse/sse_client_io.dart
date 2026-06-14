import 'dart:convert';
import 'dart:io';

import 'sse_subscription.dart';

SseSubscription connectSse(String url, void Function(String data) onData) {
  final client = HttpClient();
  var closed = false;

  Future<void> loop() async {
    while (!closed) {
      try {
        final req = await client.getUrl(Uri.parse(url));
        req.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
        final res = await req.close();
        await for (final line in res
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          if (closed) return;
          if (line.startsWith('data: ')) onData(line.substring(6));
        }
      } catch (_) {
      }
      if (!closed) await Future.delayed(const Duration(seconds: 5));
    }
  }

  loop();
  return SseSubscription(() {
    closed = true;
    client.close(force: true);
  });
}
