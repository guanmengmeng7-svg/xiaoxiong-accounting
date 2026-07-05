import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

/// 网页版数据库服务 - 使用 SharedPreferences (localStorage)
class DatabaseService {
  static SharedPreferences? _prefs;

  Future<SharedPreferences> get _store async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ═══════════════════════════════════════
  // 账单
  // ═══════════════════════════════════════

  Future<List<Map<String, dynamic>>> _readBills() async {
    final p = await _store;
    final raw = p.getString('bills');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> _writeBills(List<Map<String, dynamic>> bills) async {
    final p = await _store;
    await p.setString('bills', jsonEncode(bills));
  }

  Future<void> addBill(BillRecord bill) async {
    final bills = await _readBills();
    bills.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': bill.type,
      'amount': bill.amount,
      'category': bill.category,
      'note': bill.note,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    await _writeBills(bills);
  }

  Future<List<Map<String, dynamic>>> getAllBills() async {
    return await _readBills();
  }

  Future<List<Map<String, dynamic>>> getMonthBills() async {
    final all = await _readBills();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59).millisecondsSinceEpoch;
    return all.where((b) {
      final t = b['created_at'] as int;
      return t >= start && t <= end;
    }).toList()..sort((a,b) => (b['created_at'] as int).compareTo(a['created_at'] as int));
  }

  Future<List<Map<String, dynamic>>> getTodayBills() async {
    final all = await _readBills();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;
    return all.where((b) {
      final t = b['created_at'] as int;
      return t >= start && t <= end;
    }).toList()..sort((a,b) => (b['created_at'] as int).compareTo(a['created_at'] as int));
  }

  Future<void> deleteBill(String id) async {
    final bills = await _readBills();
    bills.removeWhere((b) => b['id'] == id);
    await _writeBills(bills);
  }

  Future<Map<String, double>> getMonthStats() async {
    final bills = await getMonthBills();
    double income = 0, expense = 0;
    for (var b in bills) {
      if (b['type'] == 'income') income += (b['amount'] as num).toDouble();
      else expense += (b['amount'] as num).toDouble();
    }
    return {'monthIncome': income, 'monthExpense': expense, 'monthBalance': income - expense};
  }

  Future<Map<String, double>> getTodayStats() async {
    final bills = await getTodayBills();
    double income = 0, expense = 0;
    for (var b in bills) {
      if (b['type'] == 'income') income += (b['amount'] as num).toDouble();
      else expense += (b['amount'] as num).toDouble();
    }
    return {'todayIncome': income, 'todayExpense': expense, 'todayBalance': income - expense};
  }

  // ═══════════════════════════════════════
  // 聊天消息
  // ═══════════════════════════════════════

  Future<List<Map<String, dynamic>>> _readAllMessages() async {
    final p = await _store;
    final raw = p.getString('messages');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> _writeAllMessages(List<Map<String, dynamic>> msgs) async {
    final p = await _store;
    await p.setString('messages', jsonEncode(msgs));
  }

  Future<void> saveMessage(ChatMessage msg, [String? roleId]) async {
    final msgs = await _readAllMessages();
    msgs.add({
      'id': msg.id,
      'role_id': roleId ?? 'minister',
      'content': msg.content,
      'isUser': msg.isUser ? 1 : 0,
      'time': msg.time.millisecondsSinceEpoch,
    });
    await _writeAllMessages(msgs);
  }

  Future<List<ChatMessage>> getMessages([String? roleId]) async {
    final all = await _readAllMessages();
    final filtered = all.where((m) => m['role_id'] == (roleId ?? 'minister'));
    return filtered.map((m) => ChatMessage.fromMap(m)).toList()
      ..sort((a,b) => a.time.compareTo(b.time));
  }

  Future<void> clearMessages([String? roleId]) async {
    final all = await _readAllMessages();
    all.removeWhere((m) => m['role_id'] == (roleId ?? 'minister'));
    await _writeAllMessages(all);
  }
}
