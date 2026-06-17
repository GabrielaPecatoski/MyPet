// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'sse_subscription.dart';

SseSubscription connectSse(String url, void Function(String data) onData) {
  final source = html.EventSource(url);
  final sub = source.onMessage.listen((event) {
    final data = event.data;
    if (data is String && data.isNotEmpty) onData(data);
  });
  return SseSubscription(() {
    sub.cancel();
    source.close();
  });
}
