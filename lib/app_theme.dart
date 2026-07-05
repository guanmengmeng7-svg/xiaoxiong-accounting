import 'package:flutter/material.dart';

/// 全局主题配置 - 轻松熊奶冻果冻玻璃拟态风格
class AppTheme {
  // ===== 颜色定义 - 轻松熊奶油色系 =====
  static const Color primaryBrown = Color(0xFFB38B6D);
  static const Color lightBrown = Color(0xFFD9B38C);
  static const Color creamYellow = Color(0xFFFFF1D0);
  static const Color softPink = Color(0xFFFFD6E0);
  static const Color mintGreen = Color(0xFFC8E6C9);
  static const Color accentCherry = Color(0xFFFF8A9B);

  // 背景
  static const Color backgroundCream = Color(0xFFFFF8E7);
  static const Color cardCream = Color(0xFFFFFFFF);
  static const Color glassWhite = Color(0xFFFFFFFF);

  // 文字
  static const Color textPrimary = Color(0xFF6D4C41);
  static const Color textSecondary = Color(0xFF9E7B6A);
  static const Color textHint = Color(0xFFC4A799);

  // 收入/支出
  static const Color incomeColor = Color(0xFF81C784);
  static const Color expenseColor = Color(0xFFFF8A80);

  // 圆角
  static const double radiusSmall = 16.0;
  static const double radiusMedium = 24.0;
  static const double radiusLarge = 32.0;
  static const double radiusXLarge = 36.0;
  static const double radiusFull = 40.0;

  // ===== 渐变 - 奶冻果冻质感 =====
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF8E7), Color(0xFFFFF1D0), Color(0xFFFFE8CC)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xCCFFFFFF), Color(0x99FFFFFF)],
  );

  static const LinearGradient glassHighlight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x80FFFFFF), Color(0x1AFFFFFF), Color(0x4DFFFFFF)],
    stops: [0.0, 0.5, 1.0],
  );

  static const RadialGradient yellowButton = RadialGradient(
    center: Alignment(-0.3, -0.3),
    colors: [Color(0xFFFFE082), Color(0xFFFFB74D)],
  );

  static const RadialGradient pinkButton = RadialGradient(
    center: Alignment(-0.3, -0.3),
    colors: [Color(0xFFFFB2C2), Color(0xFFFF8A9B)],
  );

  static const LinearGradient userBubble = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD6E0), Color(0xFFFFB2C2)],
  );

  // ===== 阴影 =====
  static List<BoxShadow> glassShadow = [
    BoxShadow(color: Color(0xFFB38B6D).withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 8)),
    BoxShadow(color: Colors.white.withOpacity(0.6), blurRadius: 2, offset: const Offset(0, -1)),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0xFFB38B6D).withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 6)),
  ];

  // ===== 文字样式 =====
  static const TextStyle headingLarge = TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary);
  static const TextStyle headingMedium = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary);
  static const TextStyle bodyLarge = TextStyle(fontSize: 15, color: textPrimary);
  static const TextStyle bodyMedium = TextStyle(fontSize: 14, color: textSecondary);
  static const TextStyle caption = TextStyle(fontSize: 11, color: textHint);

  // ===== 装饰器 =====
  static BoxDecoration glassDecoration({double radius = radiusLarge}) {
    return BoxDecoration(
      gradient: glassGradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: glassShadow,
      border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
    );
  }

  static Widget glassOverlay({double radius = radiusLarge}) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(decoration: const BoxDecoration(gradient: glassHighlight)),
      ),
    );
  }

  static Widget glassCard({required Widget child, double radius = radiusLarge}) {
    return Stack(children: [
      Container(decoration: glassDecoration(radius: radius)),
      glassOverlay(radius: radius),
      Padding(padding: const EdgeInsets.all(16), child: child),
    ]);
  }
}
