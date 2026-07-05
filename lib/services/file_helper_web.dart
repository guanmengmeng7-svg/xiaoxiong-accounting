/// 文件操作助手 - 网页版（存 URL 原样，不做文件复制）
Future<String?> persistAvatarUrl(String url, String prefix) async {
  // On web, image_picker returns blob URLs that are already persisted
  // No need to copy files
  return url;
}
