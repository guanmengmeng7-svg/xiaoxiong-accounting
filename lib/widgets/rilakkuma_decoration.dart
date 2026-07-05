import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../utils/rilakkuma_stickers.dart';

/// 贴纸装饰（用于页面角落、卡片背景）
class RilakkumaDecoration extends StatelessWidget {
  final String sticker;
  final double size;
  final Alignment alignment;
  final double opacity;

  const RilakkumaDecoration({
    Key? key,
    required this.sticker,
    this.size = 120,
    this.alignment = Alignment.topRight,
    this.opacity = 0.85,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Opacity(
        opacity: opacity,
        child: _buildSticker(),
      ),
    );
  }

  Widget _buildSticker() {
    final meta = RilakkumaStickers.metas[sticker];
    return Image.asset(
      sticker,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _buildPlaceholder(meta),
    );
  }

  Widget _buildPlaceholder(StickerMeta? meta) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.creamYellow.withOpacity(0.3),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primaryBrown.withOpacity(0.2), width: 2),
      ),
      child: Center(
        child: Text(
          meta?.emoji ?? '🧸',
          style: TextStyle(fontSize: size * 0.35),
        ),
      ),
    );
  }
}

/// 贴纸 + 标题组合（用于列表头部、卡片头部）
class RilakkumaHeader extends StatelessWidget {
  final String sticker;
  final String title;
  final String? subtitle;
  final double stickerSize;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const RilakkumaHeader({
    Key? key,
    required this.sticker,
    required this.title,
    this.subtitle,
    this.stickerSize = 48,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStickerIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.headingMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTheme.bodyMedium.copyWith(fontSize: 12)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }

  Widget _buildStickerIcon() {
    return Image.asset(
      sticker,
      width: stickerSize,
      height: stickerSize,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        final meta = RilakkumaStickers.metas[sticker];
        return Container(
          width: stickerSize,
          height: stickerSize,
          decoration: BoxDecoration(
            color: AppTheme.creamYellow.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryBrown.withOpacity(0.2), width: 1.5),
          ),
          child: Center(
            child: Text(meta?.emoji ?? '🧸', style: TextStyle(fontSize: stickerSize * 0.4)),
          ),
        );
      },
    );
  }
}

/// 空状态贴纸组合
class RilakkumaEmpty extends StatelessWidget {
  final String sticker;
  final String message;
  final String? hint;
  final VoidCallback? onAction;
  final String? actionLabel;

  const RilakkumaEmpty({
    Key? key,
    required this.sticker,
    required this.message,
    this.hint,
    this.onAction,
    this.actionLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMainSticker(),
            const SizedBox(height: 20),
            Text(message, style: AppTheme.headingMedium, textAlign: TextAlign.center),
            if (hint != null) ...[
              const SizedBox(height: 10),
              Text(hint!, style: AppTheme.bodyMedium, textAlign: TextAlign.center),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              _buildActionButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainSticker() {
    return Image.asset(
      sticker,
      width: 150,
      height: 150,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        final meta = RilakkumaStickers.metas[sticker];
        return Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            gradient: AppTheme.glassGradient,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryBrown.withOpacity(0.3), width: 2),
            boxShadow: AppTheme.glassShadow,
          ),
          child: Center(
            child: Text(meta?.emoji ?? '🧸', style: const TextStyle(fontSize: 56)),
          ),
        );
      },
    );
  }

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: onAction,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            center: Alignment(-0.3, -0.3),
            colors: [Color(0xFFFFE082), Color(0xFFFFB74D)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(
            color: AppTheme.primaryBrown.withOpacity(0.2),
            blurRadius: 12, offset: const Offset(0, 4),
          )],
        ),
        child: Text(actionLabel!, style: const TextStyle(
          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600,
        )),
      ),
    );
  }
}

/// 浮动动画贴纸（会上下轻微弹跳）
class FloatingSticker extends StatefulWidget {
  final String sticker;
  final double size;
  final double floatHeight;

  const FloatingSticker({
    Key? key,
    required this.sticker,
    this.size = 100,
    this.floatHeight = 6,
  }) : super(key: key);

  @override
  State<FloatingSticker> createState() => _FloatingStickerState();
}

class _FloatingStickerState extends State<FloatingSticker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, -widget.floatHeight * _anim.value),
        child: Image.asset(
          widget.sticker,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            final meta = RilakkumaStickers.metas[widget.sticker];
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: AppTheme.creamYellow.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(meta?.emoji ?? '🧸', style: TextStyle(fontSize: widget.size * 0.35)),
              ),
            );
          },
        ),
      ),
    );
  }
}
