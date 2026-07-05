/// 聊天消息模型
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;  // true=用户, false=AI
  final DateTime time;
  final BillRecord? record;  // 如果解析出账单记录

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.time,
    this.record,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser ? 1 : 0,
      'time': time.millisecondsSinceEpoch,
      'record': record?.toMap(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      content: map['content'],
      isUser: map['isUser'] == 1,
      time: DateTime.fromMillisecondsSinceEpoch(map['time']),
      record: map['record'] != null ? BillRecord.fromMap(map['record']) : null,
    );
  }
}

/// 账单记录
class BillRecord {
  final String type;      // 'expense' 支出, 'income' 收入
  final double amount;    // 金额
  final String category;  // 分类：餐饮/购物/工资/营收等
  final String? note;     // 备注

  BillRecord({
    required this.type,
    required this.amount,
    required this.category,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'amount': amount,
      'category': category,
      'note': note,
    };
  }

  factory BillRecord.fromMap(Map<String, dynamic> map) {
    return BillRecord(
      type: map['type'],
      amount: map['amount'].toDouble(),
      category: map['category'],
      note: map['note'],
    );
  }
}
