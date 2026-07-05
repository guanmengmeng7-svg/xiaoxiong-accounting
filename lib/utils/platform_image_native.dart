import 'dart:io';
import 'package:flutter/material.dart';

Widget buildAvatarImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget? fallback,
}) {
  final file = File(path);
  if (!file.existsSync()) {
    return fallback ?? const SizedBox.shrink();
  }
  return Image.file(file, width: width, height: height, fit: fit);
}

ImageProvider buildImageProvider(String path) {
  return FileImage(File(path));
}
