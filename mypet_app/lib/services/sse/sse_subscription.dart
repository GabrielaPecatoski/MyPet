class SseSubscription {
  final void Function() _close;
  SseSubscription(this._close);
  void close() => _close();
}
