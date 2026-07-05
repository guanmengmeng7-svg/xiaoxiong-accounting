import 'package:flutter/material.dart';

Widget buildAvatarImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget? fallback,
}) {
  if (path.startsWith('blob:') || path.startsWith('http')) {
    return Image.network(path, width: width, height: height, fit: fit);
  }
  // Local file path on web is not supported, show fallback
  return fallback ?? const SizedBox.shrink();
}

ImageProvider buildImageProvider(String path) {
  if (path.startsWith('blob:') || path.startsWith('http')) {
    return NetworkImage(path);
  }
  return const AssetImage('assets/images/placeholder.png');
}
