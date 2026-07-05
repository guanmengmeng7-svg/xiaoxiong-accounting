import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/ai_role.dart';

/// AI服务商配置
class AIProvider {
  final String id;
  final String name;
  final String baseUrl;
  final String defaultModel;

  const AIProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.defaultModel,
  });

  static const List<AIProvider> providers = [
    AIProvider(
      id: 'siliconflow',
      name: 'SiliconFlow',
      baseUrl: 'https://api.siliconflow.cn/v1',
      defaultModel: 'deepseek-ai/DeepSeek-V2.5',
    ),
    AIProvider(
      id: 'openai',
      name: 'OpenAI',
      baseUrl: 'https://api.openai.com/v1',
      defaultModel: 'gpt-3.5-turbo',
    ),
    AIProvider(
      id: 'deepseek',
      name: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com/v1',
      defaultModel: 'deepseek-chat',
    ),
    AIProvider(
      id: 'custom',
      name: 'Custom',
      baseUrl: '',
      defaultModel: '',
    ),
  ];

  static AIProvider getById(String id) {
    return providers.firstWhere(
      (p) => p.id == id,
      orElse: () => providers[0],
    );
  }
}

/// AI服务 - 完全依赖AI，不使用本地回复
class AIService {
  String? _apiKey;
  String _providerId = 'siliconflow';
  String _customUrl = '';
  String _customModel = '';
  AIRole _currentRole = AIRole.roles[0];

  void setApiKey(String key) {
    _apiKey = key;
  }

  void setProvider(String providerId, {String? customUrl, String? customModel}) {
    _providerId = providerId;
    if (customUrl != null) _customUrl = customUrl;
    if (customModel != null) _customModel = customModel;
  }

  void setRole(AIRole role) {
    _currentRole = role;
  }

  String get _baseUrl {
    if (_providerId == 'custom' && _customUrl.isNotEmpty) {
      String url = _customUrl;
      if (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }
      return url;
    }
    return AIProvider.getById(_providerId).baseUrl;
  }

  String get _model {
    if (_providerId == 'custom' && _customModel.isNotEmpty) {
      return _customModel;
    }
    return AIProvider.getById(_providerId).defaultModel;
  }

  /// 聊天对话 - 完全依赖AI
  Future<String> chat(
    String userMessage,
    List<Map<String, String>> history,
    Map<String, double> stats,
    double dailyBudget,
    bool budgetEnabled,
  ) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      return _buildWelcomeMessage();
    }

    // 构建系统提示 - 强化角色人设，让回复有趣且符合角色
    String statusInfo = '';
    if (stats['monthIncome'] != null || stats['monthExpense'] != null) {
      statusInfo = '本月记账统计 - 收入: ${stats['monthIncome']?.toStringAsFixed(2) ?? "0"} ${_currentRole.moneyName}，支出: ${stats['monthExpense']?.toStringAsFixed(2) ?? "0"} ${_currentRole.moneyName}，结余: ${((stats['monthIncome'] ?? 0) - (stats['monthExpense'] ?? 0)).toStringAsFixed(2)} ${_currentRole.moneyName}';
      if (budgetEnabled && dailyBudget > 0) {
        final dailyExpense = (stats['monthExpense'] ?? 0) / DateTime.now().day;
        final remaining = dailyBudget - dailyExpense;
        statusInfo += '，今日剩余预算: ${remaining.toStringAsFixed(2)} ${_currentRole.moneyName}';
        if (remaining < 0) {
          statusInfo = '⚠️ ${_currentRole.name} 提醒：${_currentRole.callUser}，今日预算已超支 ${(-remaining).toStringAsFixed(2)} ${_currentRole.moneyName}了！请注意理性消费哦～\n' + statusInfo;
        }
      }
    }

    String systemPrompt = '''${_currentRole.systemPrompt}

当前状态信息：$statusInfo

CRITICAL: When user mentions money, add this tag at the end:
【账单】类型：收入/支出，金额：数字，分类：根据内容自由确定，备注：描述具体事项【/账单】

Examples:
- "炒股赚了5000" → 【账单】类型：收入，金额：5000，分类：炒股，备注：炒股赚的【/账单】
- "给女朋友买了礼物花了2000" → 【账单】类型：支出，金额：2000，分类：礼物，备注：给女朋友买礼物【/账单】
- "吃饭花了50" → 【账单】类型：支出，金额：50，分类：吃饭，备注：吃饭【/账单】
- "工资到账10000" → 【账单】类型：收入，金额：10000，分类：工资，备注：月薪到账【/账单】

Rules:
1. Always stay in character as ${_currentRole.name}
2. Be fun and playful - NEVER use fixed templates
3. If user chats without money, just chat back in character
4. Take the content of the bill to dynamically mark the classification
5. Note should describe the specific items''';

    List<Map<String, String>> messages = [
      {'role': 'system', 'content': systemPrompt}
    ];

    // 添加历史（去掉账单标记，只保留对话内容）
    for (var m in history) {
      String content = m['content'] ?? '';
      // 去掉账单标记，保持对话简洁
      content = content.replaceAll(RegExp(r'【账单】.*?【/账单】', dotAll: true), '[账单已记录]');
      messages.add({
        'role': m['role']!,
        'content': content,
      });
    }

    // 添加当前消息
    messages.add({'role': 'user', 'content': userMessage});

    try {
      final url = '$_baseUrl/chat/completions';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.9,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else if (response.statusCode == 401) {
        return 'Hmm... ${_currentRole.name} cant reach the server right now.\n\n${_currentRole.callUser}, please check the API Key in settings!';
      } else if (response.statusCode == 429) {
        return '${_currentRole.name} says: ${_currentRole.callUser} slow down! Too many requests...';
      } else {
        return 'Oops! Something went wrong (${response.statusCode}). ${_currentRole.callUser} please try again.';
      }
    } catch (e) {
      return 'Network error! ${_currentRole.name} cant hear you... ${_currentRole.callUser} check your connection!';
    }
  }

  String _buildWelcomeMessage() {
    return '''${_currentRole.greeting}

No API Key configured yet!

Please:
1. Go to Settings
2. Choose an AI provider (SiliconFlow is free)
3. Paste your API Key

Current role: ${_currentRole.name} (call you ${_currentRole.callUser})''';
  }

  /// 解析账单 - 从AI回复中提取账单信息，支持自由分类
  BillRecord? parseBill(String aiResponse) {
    if (!aiResponse.contains('【账单】') || !aiResponse.contains('【/账单】')) {
      return null;
    }

    try {
      final billMatch = RegExp(r'【账单】(.*?)【/账单】', dotAll: true).firstMatch(aiResponse);
      if (billMatch == null) return null;

      final billText = billMatch.group(1) ?? '';
      
      // 确定类型
      String type = 'expense';
      if (billText.contains('收入') || billText.contains('赚')) {
        type = 'income';
      }
      
      double amount = 0;
      
      // 提取金额
      final amountMatch = RegExp(r'([0-9,]+)').firstMatch(billText);
      if (amountMatch != null) {
        String amtStr = amountMatch.group(1)?.replaceAll(',', '') ?? '0';
        amount = double.tryParse(amtStr) ?? 0;
      }

      // 直接从AI的标签提取分类（AI自由决定）
      String category = '其他';
      final categoryMatch = RegExp(r'分类[：:](.+?)(?:，|,|\n|$)').firstMatch(billText);
      if (categoryMatch != null) {
        String cat = categoryMatch.group(1)?.trim() ?? '';
        if (cat.isNotEmpty) {
          category = cat;
        }
      }

      // 提取备注
      String? note;
      final noteMatch = RegExp(r'备注[：:](.+?)(?:，|,|\n|$)').firstMatch(billText);
      if (noteMatch != null) {
        String n = noteMatch.group(1)?.trim() ?? '';
        if (n.isNotEmpty) {
          note = n;
        }
      }

      if (amount > 0) {
        return BillRecord(
          type: type,
          amount: amount,
          category: category,
          note: note,
        );
      }
    } catch (e) {
      // ignore
    }
    return null;
  }
}
