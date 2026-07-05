import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../app_theme.dart';

/// UI设置页面 - 可视化调整界面
class UISettingsPage extends StatefulWidget {
  const UISettingsPage({Key? key}) : super(key: key);

  @override
  State<UISettingsPage> createState() => _UISettingsPageState();
}

class _UISettingsPageState extends State<UISettingsPage> {
  // 预设主题色
  final List<Color> _themeColors = [
    const Color(0xFF34C759), // 绿色（默认）
    const Color(0xFF007AFF), // 蓝色
    const Color(0xFFFF9500), // 橙色
    const Color(0xFFFF2D55), // 红色
    const Color(0xFFAF52DE), // 紫色
    const Color(0xFFFFD60A), // 黄色
    const Color(0xFF00C7BE), // 青色
  ];

  // 预设背景样式
  final List<Map<String, dynamic>> _backgroundStyles = [
    {'name': '纯白', 'color': Color(0xFFFFFFFF)},
    {'name': '浅灰', 'color': Color(0xFFF5F7FA)},
    {'name': '深灰', 'color': Color(0xFF1A1A2E)},
    {'name': '黑色', 'color': Color(0xFF000000)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: AppTheme.glassDecoration(radius: 10),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('UI设置', style: AppTheme.headingMedium),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 主题颜色
            _buildSectionHeader('🎨 主题颜色'),
            const SizedBox(height: 12),
            _buildColorPicker(),
            
            const SizedBox(height: 28),
            
            // 背景样式
            _buildSectionHeader('🖼️ 背景样式'),
            const SizedBox(height: 12),
            _buildBackgroundPicker(),
            
            const SizedBox(height: 28),
            
            // 圆角大小
            _buildSectionHeader('📐 圆角大小'),
            const SizedBox(height: 12),
            _buildRadiusSlider(),
            
            const SizedBox(height: 28),
            
            // 暗色模式
            _buildSectionHeader('🌙 暗色模式'),
            const SizedBox(height: 12),
            _buildDarkModeToggle(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: AppTheme.headingMedium);
  }

  Widget _buildColorPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('选择主题色', style: AppTheme.bodyMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _themeColors.map((color) {
              final isSelected = color == const Color(0xFF34C759); // TODO: 从设置读取
              return GestureDetector(
                onTap: () {
                  // TODO: 保存到设置
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已选择颜色：${color.toString()}')),
                  );
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('选择背景色', style: AppTheme.bodyMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _backgroundStyles.map((style) {
              final color = style['color'] as Color;
              final name = style['name'] as String;
              return GestureDetector(
                onTap: () {
                  // TODO: 保存到设置
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已选择背景：$name')),
                  );
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      name,
                      style: TextStyle(
                        color: color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('圆角大小', style: AppTheme.bodyMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('16px', style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: 16,
            min: 0,
            max: 30,
            divisions: 6,
            label: '16px',
            activeColor: AppTheme.primaryGreen,
            onChanged: (value) {
              // TODO: 保存到设置并实时预览
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('方形', style: AppTheme.caption),
              Text('圆形', style: AppTheme.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDarkModeToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('暗色模式', style: AppTheme.bodyLarge),
                const SizedBox(height: 4),
                Text('开启后界面变为深色', style: AppTheme.caption),
              ],
            ),
          ),
          Switch(
            value: false, // TODO: 从设置读取
            onChanged: (value) {
              // TODO: 保存到设置并切换主题
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(value ? '已开启暗色模式' : '已关闭暗色模式')),
              );
            },
            activeColor: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }
}
