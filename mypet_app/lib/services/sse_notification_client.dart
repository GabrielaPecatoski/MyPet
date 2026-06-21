import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';

/// Cliente SSE com reconexão automática (5 s) para o stream de notificações.
/// No Flutter Web o SSE via dart:io não é suportado — usa-se o polling de
/// 60 s que já existe em MainNavigation como fallback.
class SseNotificationClient {
  bool _closed = true;
  HttpClient? _http;

  bool get isRunning => !_closed;

  void connect({
    required String userId,
    required String token,
    required void Function(Map<String, dynamic> event) onEvent,
  }) {
    if (kIsWeb) return;
    if (!_closed) return; // já conectado
    _closed = false;
    _loop(userId: userId, token: token, onEvent: onEvent);
  }

  Future<void> _loop({
    required String userId,
    required String token,
    required void Function(Map<String, dynamic> event) onEvent,
  }) async {
    while (!_closed) {
      try {
        _http = HttpClient()
          ..connectionTimeout = const Duration(seconds: 10)
          ..idleTimeout = const Duration(seconds: 90);

        final uri = Uri.parse(
          '${ApiConstants.baseUrl}/notifications/stream/$userId?token=$token',
        );
        final req = await _http!.getUrl(uri);
        req.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
        req.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
        final res = await req.close();

        await for (final line in res
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          if (_closed) return;
          if (line.startsWith('data: ')) {
            try {
              final parsed = jsonDecode(line.substring(6));
              if (parsed is Map<String, dynamic>) onEvent(parsed);
            } catch (_) {}
          }
        }
      } catch (_) {
        _http?.close(force: true);
        _http = null;
      }
      if (!_closed) await Future.delayed(const Duration(seconds: 5));
    }
  }

  void close() {
    _closed = true;
    _http?.close(force: true);
    _http = null;
  }
}
