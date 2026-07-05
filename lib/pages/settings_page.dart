import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/settings_provider.dart';
import '../providers/chat_provider.dart';
import '../models/ai_role.dart';
import '../services/ai_service.dart';
import '../app_theme.dart';
import '../widgets/rilakkuma_decoration.dart';
import '../utils/rilakkuma_stickers.dart';

/// 设置页面 - 轻松熊奶冻果冻风格（稳定版）
class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _apiKeyController = TextEditingController();
  final _budgetController = TextEditingController();
  final _backgroundController = TextEditingController();
  final _customUrlController = TextEditingController();
  final _customModelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 使用 addPostFrameCallback 确保安全访问 context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      _apiKeyController.text = settings.apiKey ?? '';
      _budgetController.text = settings.dailyBudget.toStringAsFixed(0);
      _backgroundController.text = settings.backgroundUrl ?? '';
      _customUrlController.text = settings.customApiUrl ?? '';
      _customModelController.text = settings.customModel ?? '';
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _budgetController.dispose();
    _backgroundController.dispose();
    _customUrlController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('设置', style: AppTheme.headingMedium),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: AppTheme.textPrimary),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            // 装饰贴纸
            Positioned(
              right: -20,
              bottom: 60,
              child: RilakkumaDecoration(
                sticker: RilakkumaStickers.settings,
                size: 150,
                alignment: Alignment.bottomRight,
                opacity: 0.5,
              ),
            ),
            Consumer<SettingsProvider>(
              builder: (ctx, settings, _) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    // ===== 我的头像 =====
                    _buildUserAvatarCard(settings),
                    const SizedBox(height: 24),

                    // ===== 角色选择 =====
                    RilakkumaHeader(
                      sticker: RilakkumaStickers.chat,
                      title: '选择角色',
                      subtitle: '点击角色卡片可切换，点头像可换图',
                    ),
                    const SizedBox(height: 8),
                    ...AIRole.roles.map((role) => _buildRoleCard(role, settings)),
                    const SizedBox(height: 24),

                    // ===== 背景设置 =====
                    RilakkumaHeader(
                      sticker: RilakkumaStickers.welcome,
                      title: '聊天背景',
                      subtitle: '从相册选一张喜欢的图吧',
                    ),
                    const SizedBox(height: 12),
                    _buildGlassCard([
                      _buildPickerRow(
                          Icons.image_rounded, '从相册选择背景', AppTheme.primaryBrown,
                          () => _pickBackgroundImage(settings)),
                      if (settings.backgroundUrl != null && settings.backgroundUrl!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildPreviewImage(settings.backgroundUrl!),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => settings.setBackgroundUrl(null),
                          child: Text('清除背景',
                              style: TextStyle(color: AppTheme.expenseColor, fontSize: 13)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 24),

                    // ===== API 设置 =====
                    RilakkumaHeader(
                      sticker: RilakkumaStickers.billWrite,
                      title: 'API 设置',
                      subtitle: '配置你的 AI 服务',
                    ),
                    const SizedBox(height: 8),
                    _buildGlassCard([
                      _buildDropdownTile(
                        icon: Icons.cloud_rounded,
                        title: 'AI 提供商',
                        value: settings.providerId,
                        options: ['deepseek', 'openai', 'custom'],
                        onChanged: (v) => settings.setProvider(v!),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildTextFieldTile(
                        icon: Icons.key_rounded,
                        title: 'API Key',
                        controller: _apiKeyController,
                        hint: 'sk-...',
                        obscure: true,
                        onChanged: settings.setApiKey,
                      ),
                      if (settings.providerId == 'custom') ...[
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildTextFieldTile(
                          icon: Icons.link_rounded,
                          title: '自定义 URL',
                          controller: _customUrlController,
                          hint: 'https://api.example.com/v1',
                          onChanged: settings.setCustomApiUrl,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildTextFieldTile(
                          icon: Icons.smart_toy_rounded,
                          title: '模型名称',
                          controller: _customModelController,
                          hint: 'gpt-4',
                          onChanged: settings.setCustomModel,
                        ),
                      ],
                    ]),
                    const SizedBox(height: 24),

                    // ===== 预算 =====
                    RilakkumaHeader(
                      sticker: RilakkumaStickers.billWrite,
                      title: '每日预算',
                      subtitle: '超支时 ${settings.currentRole.name} 会提醒你',
                    ),
                    const SizedBox(height: 8),
                    _buildGlassCard([
                      SwitchListTile(
                        value: settings.budgetEnabled,
                        onChanged: (v) => settings.setBudgetEnabled(v),
                        title: Text('开启预算提醒', style: AppTheme.bodyLarge),
                        activeColor: AppTheme.accentCherry,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _budgetController,
                              style: AppTheme.bodyLarge,
                              keyboardType: TextInputType.number,
                              enabled: settings.budgetEnabled,
                              decoration: InputDecoration(
                                hintText: '每日预算',
                                hintStyle: AppTheme.bodyMedium.copyWith(
                                  color: settings.budgetEnabled
                                      ? AppTheme.textHint
                                      : AppTheme.textHint.withOpacity(0.3),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.4),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: Icon(Icons.attach_money,
                                    color: settings.budgetEnabled
                                        ? AppTheme.primaryBrown
                                        : AppTheme.textHint,
                                    size: 20),
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              onChanged: (v) {
                                final amount = double.tryParse(v) ?? 0;
                                settings.setDailyBudget(amount);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('${settings.currentRole.moneyName}/天',
                              style: AppTheme.bodyMedium),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 32),

                    // ===== 清空聊天 =====
                    Center(
                      child: GestureDetector(
                        onTap: () => _showClearConfirm(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.expenseColor.withOpacity(0.3), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  color: AppTheme.expenseColor, size: 18),
                              const SizedBox(width: 8),
                              Text('清空聊天记录',
                                  style: TextStyle(
                                      color: AppTheme.expenseColor,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===== 我的头像卡片 =====
  Widget _buildUserAvatarCard(SettingsProvider settings) {
    return GestureDetector(
      onTap: () => _showUserAvatarPicker(settings),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.glassGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
          boxShadow: AppTheme.glassShadow,
        ),
        child: Row(
          children: [
            // 头像
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.softPink,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBrown.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: _buildAvatarImage(settings.userAvatarUrl),
              ),
            ),
            const SizedBox(width: 16),
            // 文字
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('我的头像', style: AppTheme.headingMedium.copyWith(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('点击更换头像', style: AppTheme.caption),
                ],
              ),
            ),
            // 当前角色
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.creamYellow.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(settings.currentRole.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(settings.currentRole.name,
                      style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建头像图片（安全处理）
  Widget _buildAvatarImage(String? url) {
    if (url == null || url.isEmpty) {
      return const Icon(Icons.person, color: AppTheme.textPrimary, size: 28);
    }
    try {
      return Image.file(
        File(url),
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, st) =>
            const Icon(Icons.person, color: AppTheme.textPrimary, size: 28),
      );
    } catch (e) {
      return const Icon(Icons.person, color: AppTheme.textPrimary, size: 28);
    }
  }

  void _showUserAvatarPicker(SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFFFF1D0)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
          boxShadow: [
            BoxShadow(
                color: AppTheme.primaryBrown.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, -5))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.textHint.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('更换我的头像', style: AppTheme.headingMedium),
            const SizedBox(height: 20),
            _buildPickerOption(Icons.photo_library_rounded, '从相册选择', AppTheme.primaryBrown,
                () async {
              Navigator.pop(ctx);
              final picker = ImagePicker();
              final picked = await picker.pickImage(source: ImageSource.gallery);
              if (picked != null) {
                settings.setUserAvatarUrl(picked.path);
              }
            }),
            const SizedBox(height: 12),
            _buildPickerOption(Icons.camera_alt_rounded, '拍照', AppTheme.lightBrown,
                () async {
              Navigator.pop(ctx);
              final picker = ImagePicker();
              final picked = await picker.pickImage(source: ImageSource.camera);
              if (picked != null) {
                settings.setUserAvatarUrl(picked.path);
              }
            }),
            const SizedBox(height: 12),
            _buildPickerOption(Icons.refresh_rounded, '恢复默认', AppTheme.expenseColor,
                () {
              Navigator.pop(ctx);
              settings.setUserAvatarUrl(null);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(AIRole role, SettingsProvider settings) {
    final isSelected = settings.currentRole.id == role.id;
    final roleAvatar = settings.getRoleAvatar(role.id);

    return GestureDetector(
      onTap: () => settings.setRole(role.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppTheme.creamYellow.withOpacity(0.6), Colors.white.withOpacity(0.8)],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBrown.withOpacity(0.4) : Colors.white.withOpacity(0.6),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _showRoleAvatarPicker(role.id, settings),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.creamYellow,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: roleAvatar != null && roleAvatar.isNotEmpty
                      ? Image.file(File(roleAvatar), width: 48, height: 48, fit: BoxFit.cover)
                      : Center(child: Text(role.emoji, style: const TextStyle(fontSize: 24))),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role.name,
                      style: AppTheme.bodyLarge.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(role.personality,
                      style: AppTheme.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBrown,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  void _showRoleAvatarPicker(String roleId, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFFFF1D0)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
          boxShadow: [
            BoxShadow(
                color: AppTheme.primaryBrown.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, -5))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.textHint.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('设置角色头像', style: AppTheme.headingMedium),
            const SizedBox(height: 20),
            _buildPickerOption(Icons.photo_library_rounded, '从相册选择', AppTheme.primaryBrown,
                () async {
              Navigator.pop(ctx);
              final picker = ImagePicker();
              final picked = await picker.pickImage(source: ImageSource.gallery);
              if (picked != null) {
                settings.setRoleAvatar(roleId, picked.path);
              }
            }),
            const SizedBox(height: 12),
            _buildPickerOption(Icons.camera_alt_rounded, '拍照', AppTheme.lightBrown,
                () async {
              Navigator.pop(ctx);
              final picker = ImagePicker();
              final picked = await picker.pickImage(source: ImageSource.camera);
              if (picked != null) {
                settings.setRoleAvatar(roleId, picked.path);
              }
            }),
            const SizedBox(height: 12),
            _buildPickerOption(Icons.refresh_rounded, '恢复默认', AppTheme.expenseColor,
                () {
              Navigator.pop(ctx);
              settings.setRoleAvatar(roleId, null);
            }),
          ],
        ),
      ),
    );
  }

  void _pickBackgroundImage(SettingsProvider settings) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      settings.setBackgroundUrl(picked.path);
    }
  }

  Widget _buildPreviewImage(String path) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        image: DecorationImage(
          image: FileImage(File(path)),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  void _showClearConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text('清空聊天记录', style: TextStyle(color: AppTheme.textPrimary, fontSize: 17)),
        content: const Text('确定要清空当前角色的所有聊天记录吗？',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.expenseColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: GestureDetector(
              onTap: () {
                context.read<ChatProvider>().clearChat();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('聊天记录已清空'), duration: Duration(seconds: 2)),
                );
              },
              child: const Text('清空', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(radius: AppTheme.radiusMedium),
      child: Stack(children: [
        AppTheme.glassOverlay(radius: AppTheme.radiusMedium),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ]),
    );
  }

  Widget _buildPickerRow(IconData icon, String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(text, style: AppTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption(IconData icon, String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(text, style: AppTheme.bodyLarge.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.primaryBrown),
      title: Text(title, style: AppTheme.bodyLarge),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textHint),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o, style: AppTheme.bodyMedium)))
            .toList(),
        onChanged: onChanged,
      ));
  }

  Widget _buildTextFieldTile({
    required IconData icon,
    required String title,
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
    bool obscure = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.primaryBrown),
      title: Text(title, style: AppTheme.bodyLarge),
      subtitle: TextField(
        controller: controller,
        obscureText: obscure,
        style: AppTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.textHint.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(top: 4),
        ),
        onChanged: onChanged,
      ));
  }
}
