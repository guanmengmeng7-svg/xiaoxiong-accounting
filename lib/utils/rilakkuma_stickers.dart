/// 轻松熊主题贴纸资源统一管理
/// 把 6 张 PNG 放到 assets/stickers/ 即可自动生效
class RilakkumaStickers {
  RilakkumaStickers._();

  // ===== 贴纸资源路径 =====
  static const String welcome    = 'assets/stickers/rilakkuma_welcome.png';
  static const String billSearch = 'assets/stickers/rilakkuma_bill_search.png';
  static const String settings   = 'assets/stickers/rilakkuma_settings.png';
  static const String stats      = 'assets/stickers/rilakkuma_stats.png';
  static const String billWrite  = 'assets/stickers/rilakkuma_bill_write.png';
  static const String chat       = 'assets/stickers/rilakkuma_chat.png';

  // ===== 贴纸元信息（用于占位回退） =====
  static const Map<String, StickerMeta> metas = {
    welcome:    StickerMeta('🌈☁️🧸', '欢迎'),
    billSearch: StickerMeta('🔍💰🧸', '查账'),
    settings:   StickerMeta('🍩☕🧸', '设置'),
    stats:      StickerMeta('📊💰🧸', '统计'),
    billWrite:  StickerMeta('📝💰🧸', '记账'),
    chat:       StickerMeta('💬🎀🧸', '聊天'),
  };
}

class StickerMeta {
  final String emoji;
  final String label;
  const StickerMeta(this.emoji, this.label);
}
