import "dart:io";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:image_picker/image_picker.dart";
import "../providers/chat_provider.dart";
import "../providers/settings_provider.dart";
import "../providers/bill_provider.dart";
import "../models/ai_role.dart";
import "../models/chat_message.dart";
import "../widgets/chat_bubble.dart";
import "../widgets/bill_stats_bar.dart";
import "../app_theme.dart";
import "settings_page.dart";
import "stats_detail_page.dart";

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String? _lastRoleId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.read<SettingsProvider>();
    context.read<ChatProvider>().syncFromSettings(
      apiKey: settings.apiKey,
      providerId: settings.providerId,
      customUrl: settings.customApiUrl,
      customModel: settings.customModel,
    );
    if (_lastRoleId != null && _lastRoleId != settings.roleId) {
      context.read<ChatProvider>().switchRole(settings.roleId);
    }
    _lastRoleId = settings.roleId;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chat = context.read<ChatProvider>();
      final bill = context.read<BillProvider>();
      final settings = context.read<SettingsProvider>();
      chat.setOnBillAdded(() => bill.loadBills());
      chat.init(
        roleId: settings.roleId,
        apiKey: settings.apiKey,
        providerId: settings.providerId,
        customUrl: settings.customApiUrl,
        customModel: settings.customModel,
      );
      bill.loadBills();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _scrollToBottom();
    final settings = context.read<SettingsProvider>();
    final bill = context.read<BillProvider>();
    await context.read<ChatProvider>().sendMessage(text, bill.stats, settings.dailyBudget, settings.budgetEnabled);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final currentRole = settings.currentRole;
    final bgUrl = settings.backgroundUrl;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(children: [
        if (bgUrl != null && bgUrl.isNotEmpty)
          Positioned.fill(child: bgUrl.startsWith("http") ? Image.network(bgUrl, fit: BoxFit.cover) : Image.file(File(bgUrl), fit: BoxFit.cover)),
        if (bgUrl != null && bgUrl.isNotEmpty) Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.25))),
        if (bgUrl == null || bgUrl.isEmpty) Container(decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient)),
        if (bgUrl == null || bgUrl.isEmpty) ...[
          Positioned(top: -100, left: -50, child: _glow(200, AppTheme.creamYellow, 0.6)),
          Positioned(bottom: 100, right: -80, child: _glow(280, AppTheme.softPink, 0.5)),
        ],
        SafeArea(
          child: Column(children: [
            _buildCompactHeader(currentRole, settings),
            Expanded(child: Consumer<ChatProvider>(builder: (ctx, chat, _) {
              if (chat.messages.isEmpty) return _welcomeCard(currentRole);
              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: chat.messages.length + (chat.isLoading ? 1 : 0),
                itemBuilder: (ctx, index) {
                  final actualIndex = chat.isLoading ? index - 1 : index;
                  if (chat.isLoading && index == 0) return _loading(currentRole);
                  return ChatBubble(message: chat.messages[chat.messages.length - 1 - actualIndex], role: currentRole);
                },
              );
            })),
            _inputBar(currentRole),
          ]),
        ),
      ]),
    );
  }

  Widget _glow(double size, Color color, double opacity) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)])));
  }

  Widget _buildCompactHeader(AIRole role, SettingsProvider settings) {
    final bill = context.watch<BillProvider>();
    final todayStats = bill.todayStats;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: AppTheme.glassDecoration(radius: AppTheme.radiusLarge),
      child: Column(children: [
        Row(children: [
          GestureDetector(onTap: () => _avatarSheet(true), child: Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.creamYellow, border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1)), child: ClipOval(child: (settings.aiAvatarUrl != null && settings.aiAvatarUrl!.isNotEmpty) ? Image.file(File(settings.aiAvatarUrl!), width: 32, height: 32, fit: BoxFit.cover, errorBuilder: (ctx, err, st) => Center(child: Text(role.emoji, style: const TextStyle(fontSize: 16)))) : Center(child: Text(role.emoji, style: const TextStyle(fontSize: 16)))))),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(role.name, style: AppTheme.headingMedium.copyWith(fontSize: 14)), Text("call me ${role.callUser}", style: AppTheme.caption.copyWith(fontSize: 10))])),
          _iconBtn(settings.userAvatarUrl, () => _avatarSheet(false)),
          const SizedBox(width: 6),
          _circleBtn(Icons.auto_awesome_rounded, () => _drawFortune(role)),
          const SizedBox(width: 6),
          _circleBtn(Icons.settings_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()))),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          _statItem("收入", (todayStats["todayIncome"] ?? 0).toStringAsFixed(0), AppTheme.incomeColor, "income"),
          const SizedBox(width: 8),
          _statItem("支出", (todayStats["todayExpense"] ?? 0).toStringAsFixed(0), AppTheme.expenseColor, "expense"),
          const SizedBox(width: 8),
          _statItem("结余", (todayStats["todayBalance"] ?? 0).toStringAsFixed(0), AppTheme.primaryBrown, "balance"),
        ]),
      ]),
    );
  }

  Widget _statItem(String label, String value, Color color, String type) {
    return Expanded(child: GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StatsDetailPage(type: type, role: context.read<SettingsProvider>().currentRole))), child: Container(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("$label ", style: AppTheme.caption.copyWith(fontSize: 10)), Flexible(child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color), maxLines: 1, overflow: TextOverflow.ellipsis))]))));
  }

  Widget _iconBtn(String? url, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.softPink, border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5)), child: Center(child: (url != null && url.isNotEmpty) ? ClipOval(child: Image.file(File(url), width: 24, height: 24, fit: BoxFit.cover)) : const Icon(Icons.person, color: AppTheme.textPrimary, size: 14))));
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.5), border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1)), child: Icon(icon, color: AppTheme.textPrimary, size: 14)));
  }

  Future<void> _drawFortune(AIRole role) async {
    final fortunes = [
      {"type": "上上签", "emoji": "🌟", "name": "紫微星高照", "desc": "今日运势极佳，贵人相助，诸事顺遂，财运亨通！"},
      {"type": "上签", "emoji": "✨", "name": "青云直上", "desc": "今日事业学业有进步，机会多多，宜把握时机！"},
      {"type": "中签", "emoji": "🍀", "name": "平稳过渡", "desc": "今日整体平稳，注意细节，小有收获，保守为宜。"},
      {"type": "下签", "emoji": "🌧️", "name": "乌云遮日", "desc": "今日运势略低，注意健康与情绪，遇事冷静应对。"},
      {"type": "下下签", "emoji": "🌩️", "name": "逆风而行", "desc": "今日挑战较大，冲动是魔鬼，宜守不宜攻，静心化解。"},
    ];
    // 概率权重（用户定制）：上上签 52.2% / 上签 47.5% / 中签 0.26% / 下签 0.05% / 下下签 0.005%
    // 用整数权重保持精度：上上签 99000, 上签 90000, 中签 500, 下签 100, 下下签 10
    final weights = [99000, 90000, 500, 100, 10];
    final total = 189610;
    final rand = DateTime.now().microsecondsSinceEpoch % total;
    int idx = 0;
    int cum = 0;
    for (int i = 0; i < weights.length; i++) { cum += weights[i]; if (rand < cum) { idx = i; break; } }
    final fortune = fortunes[idx];
    final fortuneText = "${fortune["emoji"]} 【${fortune["type"]}】${fortune["name"]}\n\n💫 签词：${fortune["desc"]}\n\n🧘 宜：静心 | 保守 | 观察\n⚠️ 忌：冲动 | 冒险 | 决策";
    final chat = context.read<ChatProvider>();
    await chat.addMessage(fortuneText, false);
    _scrollToBottom();
    final bill = context.read<BillProvider>();
    try {
      final aiResp = await chat.interpretFortune(fortune["type"] as String, fortune["name"] as String, bill.stats);
      await chat.addMessage(aiResp, false);
    } catch (e) {
      await chat.addMessage("运势解读稍后奉上，请稍候~", false);
    }
    _scrollToBottom();
  }

  Widget _welcomeCard(AIRole role) {
    return Container(margin: const EdgeInsets.all(20), child: Stack(children: [Container(decoration: AppTheme.glassDecoration(radius: AppTheme.radiusXLarge)), AppTheme.glassOverlay(radius: AppTheme.radiusXLarge), Padding(padding: const EdgeInsets.all(24), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.creamYellow, border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1)), child: Center(child: Text(role.emoji, style: const TextStyle(fontSize: 14)))), const SizedBox(width: 8), Text("${role.name} is waiting", style: AppTheme.headingMedium)]), const SizedBox(height: 20), Text(role.greeting, style: AppTheme.bodyLarge), const SizedBox(height: 16), Text("Just say it:", style: AppTheme.bodyLarge), const SizedBox(height: 8), _egItem("\"lunch 50 yuan\""), _egItem("\"salary 8000\""), _egItem("\"clothes 200\""), const SizedBox(height: 16), Text("${role.name} will record it!", style: AppTheme.bodyLarge)])))]));
  }

  Widget _egItem(String text) => Padding(padding: const EdgeInsets.only(left: 16, top: 4), child: Text(text, style: AppTheme.bodyMedium));

  Widget _loading(AIRole role) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), child: Row(children: [Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.creamYellow, border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1)), child: Center(child: Text(role.emoji, style: const TextStyle(fontSize: 14)))), const SizedBox(width: 12), Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), decoration: AppTheme.glassDecoration(radius: 20), child: Row(mainAxisSize: MainAxisSize.min, children: [Text("thinking...", style: AppTheme.bodyMedium), const SizedBox(width: 10), const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppTheme.primaryBrown)))]))]));
  }

  Widget _inputBar(AIRole role) {
    return Container(margin: const EdgeInsets.fromLTRB(20, 0, 20, 20), height: 64, child: Stack(children: [Container(decoration: AppTheme.glassDecoration(radius: 32)), AppTheme.glassOverlay(radius: 32), Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: TextField(controller: _controller, style: AppTheme.bodyLarge.copyWith(color: const Color(0xFF333333)), decoration: InputDecoration(hintText: "chat with ${role.name}...", hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textHint), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero), onSubmitted: (_) => _sendMessage()))), const SizedBox(width: 12), GestureDetector(onTap: _sendMessage, child: Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.yellowButton, border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5), boxShadow: [BoxShadow(color: AppTheme.lightBrown.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 4))]), child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18)))]))]));
  }

  void _avatarSheet(bool isAi) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx) => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFFFF), Color(0xFFFFF1D0)]), borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1), boxShadow: [BoxShadow(color: AppTheme.primaryBrown.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, -5))]), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.textHint.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))), const SizedBox(height: 20), Text(isAi ? "AI Avatar" : "My Avatar", style: AppTheme.headingMedium), const SizedBox(height: 20), _opt(Icons.photo_library_rounded, "Gallery", AppTheme.primaryBrown, () async { Navigator.pop(ctx); final picker = ImagePicker(); final picked = await picker.pickImage(source: ImageSource.gallery); if (picked != null) { final s = context.read<SettingsProvider>(); if (isAi) s.setAiAvatarUrl(picked.path); else s.setUserAvatarUrl(picked.path); } }), const SizedBox(height: 12), _opt(Icons.camera_alt_rounded, "Camera", AppTheme.lightBrown, () async { Navigator.pop(ctx); final picker = ImagePicker(); final picked = await picker.pickImage(source: ImageSource.camera); if (picked != null) { final s = context.read<SettingsProvider>(); if (isAi) s.setAiAvatarUrl(picked.path); else s.setUserAvatarUrl(picked.path); } }), const SizedBox(height: 12), _opt(Icons.refresh_rounded, "Reset", AppTheme.expenseColor, () { Navigator.pop(ctx); final s = context.read<SettingsProvider>(); if (isAi) s.setAiAvatarUrl(null); else s.setUserAvatarUrl(null); })])));
  }

  Widget _opt(IconData icon, String text, Color color, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1)), child: Row(children: [Icon(icon, color: color), const SizedBox(width: 12), Text(text, style: AppTheme.bodyLarge.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w500))])));
  }

  @override
  void dispose() { _controller.dispose(); _scrollController.dispose(); super.dispose(); }
}