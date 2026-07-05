import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/ai_role.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';

/// 账单更新回调
typedef OnBillAdded = void Function();

/// 聊天状态管理
class ChatProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final AIService _ai = AIService();
  final _uuid = const Uuid();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _currentRoleId;
  OnBillAdded? _onBillAdded;
  BillRecord? _lastFrontendBill;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  BillRecord? get lastFrontendBill => _lastFrontendBill;

  /// 设置账单添加回调
  void setOnBillAdded(OnBillAdded callback) {
    _onBillAdded = callback;
  }

  /// 初始化加载（传入完整配置）
  Future<void> init({
    required String roleId,
    required String? apiKey,
    required String providerId,
    String? customUrl,
    String? customModel,
  }) async {
    _currentRoleId = roleId;
    final role = AIRole.getById(roleId);
    _ai.setRole(role);
    _messages = await _db.getMessages(roleId);

    // 初始化AI服务 - 使用传入的配置
    _ai.setApiKey(apiKey ?? '');
    _ai.setProvider(providerId, customUrl: customUrl, customModel: customModel);

    // 如果没有历史消息，添加欢迎语
    if (_messages.isEmpty) {
      final welcomeText = role.getWelcomeMessage();
      final welcome = ChatMessage(
        id: _uuid.v4(),
        content: welcomeText,
        isUser: false,
        time: DateTime.now(),
      );
      _messages.add(welcome);
      await _db.saveMessage(welcome, roleId);
    }
    notifyListeners();
  }

  /// 切换角色
  Future<void> switchRole(String newRoleId) async {
    _currentRoleId = newRoleId;
    final role = AIRole.getById(newRoleId);
    _ai.setRole(role);
    _messages = await _db.getMessages(newRoleId);
    if (_messages.isEmpty) {
      final welcomeText = role.getWelcomeMessage();
      final welcome = ChatMessage(
        id: _uuid.v4(),
        content: welcomeText,
        isUser: false,
        time: DateTime.now(),
      );
      _messages.add(welcome);
      await _db.saveMessage(welcome, newRoleId);
    }
    notifyListeners();
  }

  /// 添加一条消息（用于求签等功能）
  Future<void> addMessage(String content, bool isUser, {BillRecord? record}) async {
    final msg = ChatMessage(
      id: _uuid.v4(),
      content: content,
      isUser: isUser,
      time: DateTime.now(),
      record: record,
    );
    _messages.add(msg);
    notifyListeners();
    if (_currentRoleId != null) {
      await _db.saveMessage(msg, _currentRoleId!);
    }
  }

  /// AI解读运势
  Future<String> interpretFortune(String fortuneType, String fortuneName, Map<String, double> stats) async {
    final history = _messages.map((m) => {
      'role': m.isUser ? 'user' : 'assistant',
      'content': m.content,
    }).toList();
    return await _ai.chat(
      '请用轻松的语气解读今日运势：$fortuneType - $fortuneName。结合用户今日账单：收入${(stats['income'] ?? 0).toStringAsFixed(2)}元，支出${(stats['expense'] ?? 0).toStringAsFixed(2)}元。给出简短有趣的运势分析和温馨提示（50字以内）。',
      history, stats, 0, false,
    );
  }

  /// 汉字数字转阿拉伯数字
  double? _parseChineseNumber(String text) {
    // 简单汉字数字映射
    final chineseMap = <String, double>{
      '零': 0, '一': 1, '二': 2, '两': 2, '三': 3, '四': 4, '五': 5,
      '六': 6, '七': 7, '八': 8, '九': 9, '十': 10, '百': 100,
      '千': 1000, '万': 10000, '亿': 100000000,
    };

    // 匹配纯汉字数字（如"五万"、"三千"、"一百二十"）
    final chineseRegex = RegExp(r'([零一二两三四五六七八九十百千万亿]+)');
    final match = chineseRegex.firstMatch(text);
    if (match == null) return null;

    String chinese = match.group(1)!;
    double result = 0;
    double temp = 0;

    for (int i = 0; i < chinese.length; i++) {
      String char = chinese[i];
      double? value = chineseMap[char];
      if (value == null) continue;

      if (value >= 10) {
        // 单位（十、百、千、万、亿）
        if (temp == 0) temp = 1;
        temp *= value;
        if (value >= 10000) {
          result += temp;
          temp = 0;
        }
      } else {
        // 数字
        temp = temp * 10 + value;
      }
    }
    result += temp;
    return result > 0 ? result : null;
  }

  /// 前端关键词解析（第一道防线）
  BillRecord? _parseBillFromUserText(String text) {
    // 支持阿拉伯数字和汉字数字
    final amountRegex = RegExp(r'([\d,]+\.?\d*)\s*(亿|万|两|元|块|块人民币)?');
    final expenseKeywords = ['亏', '亏损', '赔', '赔了', '花', '花了', '支出', '消费', '买', '买了', '支付', '丢了', '损失'];
    final incomeKeywords = ['赚', '赚了', '收入', '工资', '到账', '进账', '收到', '奖金', '分红', '利息'];

    String? type;
    double? amount;
    String category = '其他';

    for (var keyword in expenseKeywords) {
      if (text.contains(keyword)) { type = 'expense'; break; }
    }
    for (var keyword in incomeKeywords) {
      if (text.contains(keyword)) { type = 'income'; break; }
    }

    // 先尝试匹配阿拉伯数字
    final amountMatch = amountRegex.firstMatch(text);
    if (amountMatch != null) {
      final rawNum = amountMatch.group(1) ?? '0';
      amount = (double.tryParse(rawNum.replaceAll(',', '')) ?? 0);
      final unit = amountMatch.group(2) ?? '元';
      if (unit == '亿') amount = amount * 100000000;
      else if (unit == '万') amount = amount * 10000;
      else if (unit == '两') amount = amount * 50;
    } else {
      // 尝试匹配汉字数字
      amount = _parseChineseNumber(text);
      // 检查是否有"万"、"亿"等单位跟在汉字数字后面
      if (amount != null) {
        if (text.contains('亿')) amount *= 100000000;
        else if (text.contains('万')) amount *= 10000;
      }
    }

    if (type != null && amount != null && amount > 0) {
      if (text.contains('工资') || text.contains('到账')) category = '工资';
      else if (text.contains('奖金') || text.contains('分红')) category = '奖金';
      else if (text.contains('利息')) category = '利息';
      else if (text.contains('股票') || text.contains('炒股') || text.contains('投资')) category = '投资';
      else if (text.contains('买') || text.contains('消费') || text.contains('购物')) category = '购物';
      else if (text.contains('亏损') || text.contains('亏') || text.contains('赔')) category = '投资';

      return BillRecord(
        type: type,
        amount: amount,
        category: category,
        note: text.length > 50 ? text.substring(0, 50) : text,
      );
    }
    return null;
  }

  /// 发送消息
  Future<void> sendMessage(
    String text,
    Map<String, double> stats,
    double dailyBudget,
    bool budgetEnabled,
  ) async {
    if (text.trim().isEmpty || _isLoading) return;

    _lastFrontendBill = null;
    final frontendBill = _parseBillFromUserText(text);
    bool frontendRecorded = false;

    if (frontendBill != null) {
      _lastFrontendBill = frontendBill;
      await _db.addBill(frontendBill);
      _onBillAdded?.call();
      frontendRecorded = true;
    }

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      content: text,
      isUser: true,
      time: DateTime.now(),
      record: frontendBill,
    );
    _messages.add(userMsg);
    notifyListeners();
    await _db.saveMessage(userMsg, _currentRoleId);

    _isLoading = true;
    notifyListeners();

    final history = _messages
        .where((m) => m.id != userMsg.id)
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.content.split('【账单】')[0].split('【/账单】')[0].trim()
            })
        .toList();

    final aiResponse = await _ai.chat(text, history, stats, dailyBudget, budgetEnabled);

    // 防重复记账：只有用户消息中包含数字金额时才信任 AI 生成的账单
    final hasNumber = RegExp(r'\d').hasMatch(text);
    BillRecord? aiBill = hasNumber ? _ai.parseBill(aiResponse) : null;
    final aiMsg = ChatMessage(
      id: _uuid.v4(),
      content: aiResponse,
      isUser: false,
      time: DateTime.now(),
      record: aiBill,
    );
    _messages.add(aiMsg);
    _isLoading = false;
    notifyListeners();

    await _db.saveMessage(aiMsg, _currentRoleId);

    if (aiBill != null && !frontendRecorded) {
      await _db.addBill(aiBill);
      _onBillAdded?.call();
    }
  }

    /// 同步来自 SettingsProvider 的配置
  void syncFromSettings({
    required String? apiKey,
    required String providerId,
    String? customUrl,
    String? customModel,
  }) {
    _ai.setApiKey(apiKey ?? '');
    _ai.setProvider(providerId, customUrl: customUrl, customModel: customModel);
    debugPrint('syncFromSettings: apiKey=\${apiKey != null ? "***\${apiKey.substring(apiKey.length - 4)}" : "null"}, providerId=\$providerId');
  }

  /// 清空聊天
  Future<void> clearChat([String? roleId]) async {
    final rid = roleId ?? _currentRoleId ?? 'minister';
    _messages.clear();
    await _db.clearMessages(rid);
    final role = AIRole.getById(rid);
    final welcome = ChatMessage(
      id: _uuid.v4(),
      content: role.getWelcomeMessage(),
      isUser: false,
      time: DateTime.now(),
    );
    _messages.add(welcome);
    await _db.saveMessage(welcome, rid);
    notifyListeners();
  }
}
