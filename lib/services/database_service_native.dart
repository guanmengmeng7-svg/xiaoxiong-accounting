import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chat_message.dart';

/// 数据库服务
class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'chat_accounting.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE bills (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            note TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            role_id TEXT NOT NULL DEFAULT 'minister',
            content TEXT NOT NULL,
            isUser INTEGER NOT NULL,
            time INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE messages ADD COLUMN role_id TEXT NOT NULL DEFAULT "minister"');
        }
      },
    );
  }

  Future<void> addBill(BillRecord bill) async {
    final db = await database;
    await db.insert('bills', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': bill.type,
      'amount': bill.amount,
      'category': bill.category,
      'note': bill.note,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getAllBills() async {
    final db = await database;
    return await db.query('bills', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getMonthBills() async {
    final db = await database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    return await db.query(
      'bills',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [
        startOfMonth.millisecondsSinceEpoch,
        endOfMonth.millisecondsSinceEpoch,
      ],
      orderBy: 'created_at DESC',
    );
  }

  /// 获取今日账单
  Future<List<Map<String, dynamic>>> getTodayBills() async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return await db.query(
      'bills',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> deleteBill(String id) async {
    final db = await database;
    await db.delete('bills', where: 'id = ?', whereArgs: [id]);
  }

  /// 获取月度统计
  Future<Map<String, double>> getMonthStats() async {
    final bills = await getMonthBills();
    double income = 0;
    double expense = 0;
    
    for (var bill in bills) {
      if (bill['type'] == 'income') {
        income += bill['amount'];
      } else {
        expense += bill['amount'];
      }
    }
    
    return {
      'monthIncome': income,
      'monthExpense': expense,
      'monthBalance': income - expense,
    };
  }

  /// 获取今日统计
  Future<Map<String, double>> getTodayStats() async {
    final bills = await getTodayBills();
    double income = 0;
    double expense = 0;
    
    for (var bill in bills) {
      if (bill['type'] == 'income') {
        income += bill['amount'];
      } else {
        expense += bill['amount'];
      }
    }
    
    return {
      'todayIncome': income,
      'todayExpense': expense,
      'todayBalance': income - expense,
    };
  }

  /// 保存聊天记录（按角色分表）
  Future<void> saveMessage(ChatMessage msg, [String? roleId]) async {
    final db = await database;
    await db.insert('messages', {
      'id': msg.id,
      'role_id': roleId ?? 'minister',
      'content': msg.content,
      'isUser': msg.isUser ? 1 : 0,
      'time': msg.time.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ChatMessage>> getMessages([String? roleId]) async {
    final db = await database;
    final msgs = await db.query(
      'messages',
      where: 'role_id = ?',
      whereArgs: [roleId ?? 'minister'],
      orderBy: 'time ASC',
    );
    return msgs.map((m) => ChatMessage.fromMap(m)).toList();
  }

  Future<void> clearMessages([String? roleId]) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'role_id = ?',
      whereArgs: [roleId ?? 'minister'],
    );
  }
}