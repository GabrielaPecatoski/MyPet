import 'dart:convert';
import 'package:flutter/material.dart';

/// Retorna o [ImageProvider] adequado para [url], que pode ser tanto uma data
/// URL base64 (`data:image/...;base64,...`, padrão de upload do app) quanto uma
/// URL de rede comum. Retorna `null` quando não há imagem.
ImageProvider? appImageProvider(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('data:')) {
    try {
      return MemoryImage(base64Decode(url.split(',').last));
    } catch (_) {
      return null;
    }
  }
  return NetworkImage(url);
}

/// Exibe uma imagem a partir de [url] (data URL base64 ou URL de rede), com um
/// [fallback] quando não há imagem ou o decode/carregamento falha.
class AppImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final Widget fallback;

  const AppImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final provider = appImageProvider(url);
    if (provider == null) return fallback;
    return Image(
      image: provider,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
