import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../models/chat_message.dart';

/// 账单状态管理
class BillProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<Map<String, dynamic>> _bills = [];
  Map<String, double> _monthStats = {'monthIncome': 0.0, 'monthExpense': 0.0, 'monthBalance': 0.0};
  Map<String, double> _todayStats = {'todayIncome': 0.0, 'todayExpense': 0.0, 'todayBalance': 0.0};

  List<Map<String, dynamic>> get bills => _bills;
  Map<String, double> get monthStats => _monthStats;
  Map<String, double> get todayStats => _todayStats;
  
  /// 兼容旧的 stats getter
  Map<String, double> get stats => _monthStats;

  Future<void> loadBills() async {
    _bills = await _db.getAllBills();
    _monthStats = await _db.getMonthStats();
    _todayStats = await _db.getTodayStats();
    notifyListeners();
  }

  Future<void> deleteBill(String id) async {
    await _db.deleteBill(id);
    await loadBills();
  }

  /// 获取今日收入
  double get todayIncome => _todayStats['todayIncome'] ?? 0;

  /// 获取今日支出
  double get todayExpense => _todayStats['todayExpense'] ?? 0;

  /// 获取今日结余
  double get todayBalance => _todayStats['todayBalance'] ?? 0;

  /// 获取本月收入
  double get monthIncome => _monthStats['monthIncome'] ?? 0;

  /// 获取本月支出
  double get monthExpense => _monthStats['monthExpense'] ?? 0;

  /// 获取本月结余
  double get monthBalance => _monthStats['monthBalance'] ?? 0;
}