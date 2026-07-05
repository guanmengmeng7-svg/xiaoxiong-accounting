import "dart:io";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:intl/intl.dart";
import "../providers/bill_provider.dart";
import "../providers/settings_provider.dart";
import "../models/ai_role.dart";
import "../app_theme.dart";
import "../utils/rilakkuma_stickers.dart";

enum _DateFilter { all, year, month, day }

class StatsDetailPage extends StatefulWidget {
  final String type;
  final AIRole role;
  const StatsDetailPage({Key? key, required this.type, required this.role}) : super(key: key);
  @override
  State<StatsDetailPage> createState() => _StatsDetailPageState();
}

class _StatsDetailPageState extends State<StatsDetailPage> {
  _DateFilter _filter = _DateFilter.all;
  DateTime _selectedDate = DateTime.now();

  String get _title {
    switch (widget.type) {
      case "income": return "收入明细";
      case "expense": return "支出明细";
      default: return "收支明细";
    }
  }

  String get _emptyEmoji {
    switch (widget.type) {
      case "income": return "💰";
      case "expense": return "💸";
      default: return "🧸";
    }
  }

  String get _emptyHint {
    switch (widget.type) {
      case "income": return "还没有任何收入记录";
      case "expense": return "还没有任何支出记录";
      default: return "还没有任何记录";
    }
  }

  String get _filterLabel {
    switch (_filter) {
      case _DateFilter.all: return "全部";
      case _DateFilter.year: return DateFormat("yyyy年").format(_selectedDate);
      case _DateFilter.month: return DateFormat("yyyy年MM月").format(_selectedDate);
      case _DateFilter.day: return DateFormat("yyyy年MM月dd日").format(_selectedDate);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillProvider>().loadBills();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("收支统计", style: AppTheme.headingMedium),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppTheme.textPrimary),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Column(children: [
          _buildHeader(settings),
          _buildFilterBar(),
          Expanded(child: Consumer<BillProvider>(builder: (ctx, bill, _) {
            final filtered = _filterBills(_filterBillsByType(bill.bills));
            if (filtered.isEmpty) return _buildEmpty();
            return _buildBillList(filtered);
          })),
        ]),
      ),
    );
  }

  Widget _buildHeader(SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.softPink,
            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
          ),
          child: ClipOval(child: (settings.userAvatarUrl != null && settings.userAvatarUrl!.isNotEmpty) ? Image.file(File(settings.userAvatarUrl!), width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (ctx, err, st) => const Icon(Icons.person, color: AppTheme.textPrimary, size: 24)) : const Icon(Icons.person, color: AppTheme.textPrimary, size: 24)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_title, style: AppTheme.headingLarge),
          const SizedBox(height: 2),
          Text("👇 点击下方按钮切换日期", style: AppTheme.caption.copyWith(color: AppTheme.textHint, fontSize: 11)),
        ])),
      ]),
    );
  }

  /// 日历筛选条：全部 / 年 / 月 / 日
  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(children: [
        Expanded(child: _buildFilterChip("全部", _DateFilter.all)),
        const SizedBox(width: 6),
        Expanded(child: _buildFilterChip("按年", _DateFilter.year)),
        const SizedBox(width: 6),
        Expanded(child: _buildFilterChip("按月", _DateFilter.month)),
        const SizedBox(width: 6),
        Expanded(child: _buildFilterChip("按日", _DateFilter.day)),
        const SizedBox(width: 6),
        // 日历选择器按钮
        GestureDetector(
          onTap: _showDatePicker,
          child: Container(
            width: 40, height: 36,
            decoration: BoxDecoration(
              gradient: AppTheme.glassGradient,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1),
            ),
            child: const Icon(Icons.calendar_month_rounded, size: 18, color: AppTheme.primaryBrown),
          ),
        ),
      ]),
    );
  }

  Widget _buildFilterChip(String label, _DateFilter mode) {
    final isSelected = _filter == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filter = mode;
          if (mode == _DateFilter.year) _selectedDate = DateTime(_selectedDate.year);
          if (mode == _DateFilter.month) _selectedDate = DateTime(_selectedDate.year, _selectedDate.month);
          if (mode == _DateFilter.day) _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        });
      },
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          gradient: isSelected ? const LinearGradient(colors: [Color(0xFFFFE082), Color(0xFFFFB74D)]) : AppTheme.glassGradient,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppTheme.primaryBrown.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.8), width: 1),
          boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryBrown.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))] : null,
        ),
        child: Center(child: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppTheme.textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))),
      ),
    );
  }

  Future<void> _showDatePicker() async {
    int refYear = _selectedDate.year;
    int refMonth = _selectedDate.month;
    int refDay = _selectedDate.day;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFFFF), Color(0xFFFFF1D0)]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1),
            boxShadow: [BoxShadow(color: AppTheme.primaryBrown.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, -5))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.textHint.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text("选择日期", style: AppTheme.headingMedium),
            const SizedBox(height: 16),
            // 年/月/日 三组选择
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              _buildPickerColumn(
                title: "年",
                value: refYear,
                range: List.generate(11, (i) => 2020 + i),
                currentValue: refYear,
                onChanged: (v) => setSheetState(() => refYear = v),
              ),
              const SizedBox(width: 8),
              _buildPickerColumn(
                title: "月",
                value: refMonth,
                range: List.generate(12, (i) => i + 1),
                currentValue: refMonth,
                onChanged: (v) => setSheetState(() => refMonth = v),
              ),
              const SizedBox(width: 8),
              _buildPickerColumn(
                title: "日",
                value: refDay,
                range: List.generate(31, (i) => i + 1),
                currentValue: refDay,
                onChanged: (v) => setSheetState(() => refDay = v),
              ),
            ]),
            const SizedBox(height: 16),
            // 快速选择
            Wrap(spacing: 8, runSpacing: 8, children: [
              _quickChip("今天", () { final now = DateTime.now(); setSheetState(() { refYear = now.year; refMonth = now.month; refDay = now.day; }); }),
              _quickChip("本月", () { final now = DateTime.now(); setSheetState(() { refYear = now.year; refMonth = now.month; refDay = 1; }); }),
              _quickChip("今年", () { final now = DateTime.now(); setSheetState(() { refYear = now.year; refMonth = 1; refDay = 1; }); }),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text("取消", style: TextStyle(color: AppTheme.textHint)))),
              Expanded(child: Container(
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFE082), Color(0xFFFFB74D)]), borderRadius: BorderRadius.circular(12)),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime(refYear, refMonth, refDay);
                      _filter = _DateFilter.day;
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text("确定", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              )),
            ]),
          ]),
        );
      }),
    );
  }

  Widget _quickChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.primaryBrown.withValues(alpha: 0.3), width: 1)),
        child: Text(label, style: TextStyle(color: AppTheme.primaryBrown, fontSize: 12, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildPickerColumn({required String title, required int value, required List<int> range, required int currentValue, required ValueChanged<int> onChanged}) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTheme.caption.copyWith(color: AppTheme.textHint, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          height: 180,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1)),
          child: ListWheelScrollView.useDelegate(
            itemExtent: 36,
            perspective: 0.005,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            controller: FixedExtentScrollController(initialItem: range.indexOf(currentValue).clamp(0, range.length - 1)),
            onSelectedItemChanged: (idx) => onChanged(range[idx]),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: range.length,
              builder: (ctx, idx) {
                final v = range[idx];
                final isCurrent = v == currentValue;
                return Center(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: isCurrent ? BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFE082), Color(0xFFFFB74D)]), borderRadius: BorderRadius.circular(8)) : null,
                  child: Text(v.toString(), style: TextStyle(fontSize: isCurrent ? 16 : 13, color: isCurrent ? Colors.white : AppTheme.textPrimary, fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal)),
                ));
              },
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFFFFF1D0), Color(0xFFFFE4B5)]), boxShadow: [BoxShadow(color: AppTheme.primaryBrown.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))]),
            child: Center(child: Text(_emptyEmoji, style: const TextStyle(fontSize: 48))),
          ),
          const SizedBox(height: 16),
          Text(_filter == _DateFilter.all ? _emptyHint : "该时段$_emptyHint", style: AppTheme.headingMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text("试试切换其他日期看看～", style: AppTheme.bodyMedium.copyWith(color: AppTheme.textHint, fontSize: 13), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  List<Map<String, dynamic>> _filterBillsByType(List<Map<String, dynamic>> bills) {
    if (widget.type == "balance") return bills;
    return bills.where((b) => b["type"] == widget.type).toList();
  }

  List<Map<String, dynamic>> _filterBills(List<Map<String, dynamic>> bills) {
    if (_filter == _DateFilter.all) return bills;
    return bills.where((b) {
      final d = DateTime.fromMillisecondsSinceEpoch(b["created_at"] as int);
      switch (_filter) {
        case _DateFilter.year:
          return d.year == _selectedDate.year;
        case _DateFilter.month:
          return d.year == _selectedDate.year && d.month == _selectedDate.month;
        case _DateFilter.day:
          return d.year == _selectedDate.year && d.month == _selectedDate.month && d.day == _selectedDate.day;
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildBillList(List<Map<String, dynamic>> bills) {
    final (income, expense, _) = _calcGroup(bills);
    return Column(children: [
      // 顶部统计卡片
      Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppTheme.glassGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1),
          boxShadow: AppTheme.glassShadow,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _buildMiniStat("收入", income, AppTheme.incomeColor),
          Container(width: 1, height: 30, color: AppTheme.textHint.withValues(alpha: 0.2)),
          _buildMiniStat("支出", expense, AppTheme.expenseColor),
          Container(width: 1, height: 30, color: AppTheme.textHint.withValues(alpha: 0.2)),
          _buildMiniStat("结余", income - expense, AppTheme.primaryBrown),
        ]),
      ),
      // 当前筛选条件 + 提示
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Row(children: [
          Icon(Icons.swipe_left, size: 12, color: AppTheme.textHint.withValues(alpha: 0.6)),
          const SizedBox(width: 4),
          Text("左滑可删除 · $_filterLabel", style: AppTheme.caption.copyWith(color: AppTheme.textHint.withValues(alpha: 0.6), fontSize: 11)),
          const Spacer(),
          Text("共 ${bills.length} 笔", style: AppTheme.caption.copyWith(color: AppTheme.textHint.withValues(alpha: 0.6), fontSize: 11)),
        ]),
      ),
      const SizedBox(height: 6),
      // 账单列表
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: bills.length,
        itemBuilder: (ctx, index) => _buildDismissibleBill(bills[index], ctx),
      )),
    ]);
  }

  Widget _buildDismissibleBill(Map<String, dynamic> bill, BuildContext ctx) {
    final amount = (bill["amount"] as num).toDouble();
    final isIncome = bill["type"] == "income";
    final createdAt = DateTime.fromMillisecondsSinceEpoch(bill["created_at"] as int);
    final dateStr = DateFormat("yyyy-MM-dd").format(createdAt);
    final timeStr = DateFormat("HH:mm").format(createdAt);
    final weekDay = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"][createdAt.weekday - 1];
    final note = bill["note"]?.toString() ?? "";

    return Dismissible(
      key: ValueKey(bill["id"].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)]), borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.delete_rounded, color: Colors.white, size: 20), SizedBox(width: 6), Text("删除", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))]),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: ctx,
          builder: (ctx2) => AlertDialog(
            backgroundColor: AppTheme.backgroundCream,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(children: [const Text("🌸", style: TextStyle(fontSize: 22)), const SizedBox(width: 8), const Text("确认删除", style: AppTheme.headingMedium)]),
            content: Text("确定删除这条${isIncome ? "收入" : "支出"}记录吗？", style: AppTheme.bodyMedium),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx2, false), child: Text("取消", style: TextStyle(color: AppTheme.textHint))),
              TextButton(onPressed: () => Navigator.pop(ctx2, true), child: Text("删除", style: TextStyle(color: AppTheme.expenseColor, fontWeight: FontWeight.w600))),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) async {
        await context.read<BillProvider>().deleteBill(bill["id"].toString());
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text("${isIncome ? "收入" : "支出"} ${amount.toStringAsFixed(2)} 已删除"),
              backgroundColor: AppTheme.expenseColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: GestureDetector(
        onTap: () => _showBillDetail(bill),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: isIncome ? AppTheme.incomeColor.withValues(alpha: 0.12) : AppTheme.expenseColor.withValues(alpha: 0.12)),
              child: Center(child: Text(isIncome ? "↑" : "↓", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(bill["category"] ?? "其他", style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Row(children: [
                Icon(Icons.calendar_today_rounded, size: 10, color: AppTheme.textHint.withValues(alpha: 0.7)),
                const SizedBox(width: 3),
                Text(dateStr, style: AppTheme.caption.copyWith(fontSize: 11, color: AppTheme.textHint)),
                const SizedBox(width: 6),
                Container(width: 3, height: 3, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.textHint.withValues(alpha: 0.4))),
                const SizedBox(width: 6),
                Text("$timeStr · $weekDay", style: AppTheme.caption.copyWith(fontSize: 11, color: AppTheme.textHint)),
              ]),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(note, style: AppTheme.caption.copyWith(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ])),
            Text("${isIncome ? "+" : "-"}${_formatAmount(amount)}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor)),
          ]),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000000) return "${(amount / 100000000).toStringAsFixed(1)}亿";
    if (amount >= 10000) return "${(amount / 10000).toStringAsFixed(1)}万";
    return amount.toStringAsFixed(2);
  }

  void _showBillDetail(Map<String, dynamic> bill) {
    final amount = (bill["amount"] as num).toDouble();
    final isIncome = bill["type"] == "income";
    final createdAt = DateTime.fromMillisecondsSinceEpoch(bill["created_at"] as int);
    final fullDate = DateFormat("yyyy-MM-dd HH:mm:ss").format(createdAt);
    final weekDay = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"][createdAt.weekday - 1];
    final note = bill["note"]?.toString() ?? "";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFFFF), Color(0xFFFFF1D0)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1),
              boxShadow: [BoxShadow(color: AppTheme.primaryBrown.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, -5))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.textHint.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(shape: BoxShape.circle, color: isIncome ? AppTheme.incomeColor.withValues(alpha: 0.15) : AppTheme.expenseColor.withValues(alpha: 0.15)),
                child: Center(child: Text(isIncome ? "↑" : "↓", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor))),
              ),
              const SizedBox(height: 10),
              Text(bill["category"] ?? "其他", style: AppTheme.headingLarge),
              const SizedBox(height: 4),
              Text("${isIncome ? "+" : "-"}${amount.toStringAsFixed(2)}", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor)),
              const SizedBox(height: 16),
              _detailRow("📅 日期", fullDate),
              const SizedBox(height: 6),
              _detailRow("📆 星期", weekDay),
              const SizedBox(height: 6),
              _detailRow("🏷️ 类型", isIncome ? "收入" : "支出"),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 6),
                _detailRow("📝 备注", note),
              ],
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 60, child: Text(label, style: AppTheme.caption.copyWith(color: AppTheme.textHint, fontSize: 12))),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500, fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _buildMiniStat(String label, double value, Color color) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
      const SizedBox(height: 4),
      FittedBox(fit: BoxFit.scaleDown, child: Text(_formatAmount(value), style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1)),
    ]);
  }

  (double, double, double) _calcGroup(List<Map<String, dynamic>> bills) {
    double income = 0, expense = 0;
    for (var b in bills) {
      if (b["type"] == "income") income += (b["amount"] as num).toDouble();
      else if (b["type"] == "expense") expense += (b["amount"] as num).toDouble();
    }
    return (income, expense, income - expense);
  }
}