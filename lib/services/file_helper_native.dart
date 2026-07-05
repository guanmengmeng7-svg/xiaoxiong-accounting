import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

/// 文件操作助手 - 原生版（复制临时文件到应用目录）
Future<String?> persistAvatarUrl(String tempPath, String prefix) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final avatarDir = Directory('${dir.path}/avatars');
    if (!await avatarDir.exists()) {
      await avatarDir.create(recursive: true);
    }
    final ext = tempPath.split('.').last.toLowerCase();
    final safeExt = (ext.length <= 4) ? ext : 'jpg';
    final ts = DateTime.now().millisecondsSinceEpoch;
    final dest = File('${avatarDir.path}/${prefix}_$ts.$safeExt');
    await File(tempPath).copy(dest.path);
    return dest.path;
  } catch (e) {
    debugPrint('persistAvatarUrl error: $e');
    return null;
  }
}
