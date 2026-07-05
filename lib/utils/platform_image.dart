import 'package:flutter/material.dart';

export 'platform_image_web.dart' if (dart.library.io) 'platform_image_native.dart';

Widget buildAvatarImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget? fallback,
}) {
  return fallback ?? const SizedBox.shrink();
}

ImageProvider buildImageProvider(String path) {
  return const AssetImage('assets/images/placeholder.png');
}
