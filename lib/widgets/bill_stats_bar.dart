import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/bill_provider.dart';
import '../providers/settings_provider.dart';
import '../models/ai_role.dart';
import '../pages/stats_detail_page.dart';

/// 顶部统计栏 - 今日收入/支出/总结余
class BillStatsBar extends StatelessWidget {
  const BillStatsBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bill = context.watch<BillProvider>();
    final settings = context.watch<SettingsProvider>();
    final todayStats = bill.todayStats;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCard(
            context,
            '今日收入',
            (todayStats['todayIncome'] ?? 0).toStringAsFixed(2),
            AppTheme.incomeColor,
            '↑',
            'income',
            settings.currentRole,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context,
            '今日支出',
            (todayStats['todayExpense'] ?? 0).toStringAsFixed(2),
            AppTheme.expenseColor,
            '↓',
            'expense',
            settings.currentRole,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context,
            '总结余',
            (todayStats['todayBalance'] ?? 0).toStringAsFixed(2),
            AppTheme.primaryBrown,
            '=',
            'balance',
            settings.currentRole,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    String arrow,
    String type,
    AIRole role,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StatsDetailPage(type: type, role: role),
            ),
          );
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: AppTheme.glassShadow,
          ),
          child: Stack(
            children: [
              Container(
                decoration: AppTheme.glassDecoration(radius: AppTheme.radiusLarge),
              ),
              AppTheme.glassOverlay(radius: AppTheme.radiusLarge),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: AppTheme.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$arrow $value',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}