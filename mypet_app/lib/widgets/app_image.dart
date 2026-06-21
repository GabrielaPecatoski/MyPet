import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Converte [bytes] de uma imagem em uma data URL base64
/// (`data:image/jpeg;base64,...`) — formato persistido no backend para fotos de
/// perfil (estabelecimento, veterinário e motorista) e que funciona no Web.
String dataUrlFromBytes(Uint8List bytes) =>
    'data:image/jpeg;base64,${base64Encode(bytes)}';

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
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

/// Caixa quadrada com cantos arredondados que exibe a foto de perfil de [url]
/// (data URL base64 ou URL de rede) cobrindo todo o espaço, ou [fallback]
/// (normalmente um ícone) quando não há foto ou o carregamento falha.
class PhotoBox extends StatelessWidget {
  final String? url;
  final double size;
  final double radius;
  final Color background;
  final Widget fallback;

  const PhotoBox({
    super.key,
    required this.url,
    required this.size,
    required this.background,
    required this.fallback,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: AppImage(
        url: url,
        fit: BoxFit.cover,
        fallback: Center(child: fallback),
      ),
    );
  }
}
