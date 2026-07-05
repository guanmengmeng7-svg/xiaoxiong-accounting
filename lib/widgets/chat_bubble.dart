import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/ai_role.dart';
import '../providers/settings_provider.dart';
import '../app_theme.dart';

/// 聊天气泡组件 - 轻松熊奶冻果冻风格
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final AIRole role;
  const ChatBubble({Key? key, required this.message, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    if (isUser) return _buildUserBubble(context);
    return _buildAiBubble(context);
  }

  Widget _buildAiBubble(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final avatarUrl = settings.getRoleAvatar(role.id);
    final Widget avatarWidget = (avatarUrl != null && avatarUrl.isNotEmpty)
        ? ClipOval(child: Image.file(File(avatarUrl), width: 28, height: 28, fit: BoxFit.cover, errorBuilder: (ctx, err, st) => Center(child: Text(role.emoji, style: const TextStyle(fontSize: 16)))))
        : Center(child: Text(role.emoji, style: const TextStyle(fontSize: 16)));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.creamYellow,
              border: Border.all(color: AppTheme.lightBrown.withOpacity(0.5), width: 1.5),
            ),
            child: Center(child: avatarWidget),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppTheme.glassGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                ),
                border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBrown.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(message.content, style: AppTheme.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBubble(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppTheme.userBubble,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(4),
                ),
                border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentCherry.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(message.content,
                  style: AppTheme.bodyLarge.copyWith(color: AppTheme.textPrimary)),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.softPink,
              border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
            ),
            child: Center(
              child: (settings.userAvatarUrl != null &&
                      settings.userAvatarUrl!.isNotEmpty)
                  ? ClipOval(
                      child: Image.file(File(settings.userAvatarUrl!),
                          width: 28, height: 28, fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => const Icon(Icons.person, color: AppTheme.textPrimary, size: 16)))
                  : const Icon(Icons.person, color: AppTheme.textPrimary, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
