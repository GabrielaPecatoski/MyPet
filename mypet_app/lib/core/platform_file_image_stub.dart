import 'package:flutter/material.dart';

ImageProvider? fileImageProvider(String? path) {
  if (path == null) return null;
  return NetworkImage(path);
}

Widget fileImageWidget({
  required String? path,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  required Widget fallback,
}) {
  if (path == null) return fallback;
  return Image.network(
    path,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) => fallback,
  );
}
