import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/expense.dart';
import '../database/database_helper.dart';
import '../theme/app_colors.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  DateTime selectedMonth = DateTime.now();
  List<Expense> expenses = [];
  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // --------------------------------------------------
  // LOAD
  // --------------------------------------------------

  Future<void> loadData() async {
    setState(() => isLoading = true);

    final data = await DatabaseHelper.instance.getUngroupedExpensesByMonth(
      selectedMonth.year,
      selectedMonth.month,
    );
    final cats = await DatabaseHelper.instance.getCategories();

    if (!mounted) return;

    setState(() {
      expenses = data.map((item) => Expense.fromMap(item)).toList();
      categories = cats;
      isLoading = false;
    });
  }

  Future<void> previousMonth() async {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    });
    await loadData();
  }

  Future<void> nextMonth() async {
    if (isCurrentMonth) return;
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    });
    await loadData();
  }

  // --------------------------------------------------
  // DERIVED DATA
  // --------------------------------------------------

  double get totalSpent {
    double total = 0;
    for (final e in expenses) {
      if (e.isExpense) total += e.amount;
    }
    return total;
  }

  int get transactionCount => expenses.length;

  bool get isCurrentMonth {
    final now = DateTime.now();
    return selectedMonth.year == now.year && selectedMonth.month == now.month;
  }

  String get currentMonth {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[selectedMonth.month - 1];
  }

  /// Map of category → total, sorted descending.
  List<MapEntry<String, double>> get categoryBreakdown {
    final map = <String, double>{};
    for (final e in expenses) {
      if (e.isExpense) {
        map[e.category] = (map[e.category] ?? 0) + e.amount;
      }
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Day of month → total spent that day (only for the selected month).
  Map<int, double> get dailyTotals {
    final map = <int, double>{};
    for (final e in expenses) {
      if (e.isExpense) {
        final d = DateTime.parse(e.date);
        final day = d.day;
        map[day] = (map[day] ?? 0) + e.amount;
      }
    }
    return map;
  }

  double get dailyAverage {
    if (expenses.isEmpty) return 0;
    final daysInMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;
    // If current month, average over days elapsed so far
    final today = DateTime.now();
    int divisor = daysInMonth;
    if (selectedMonth.year == today.year &&
        selectedMonth.month == today.month) {
      divisor = today.day;
    }
    if (divisor == 0) return 0;
    return totalSpent / divisor;
  }

  MapEntry<String, double>? get topCategory {
    final b = categoryBreakdown;
    if (b.isEmpty) return null;
    return b.first;
  }

  // --------------------------------------------------
  // COLORS & ICONS
  // --------------------------------------------------

  Color _categoryColor(String category) {
    const palette = AppColors.chartPalette;
    final index = category.hashCode.abs() % palette.length;
    return palette[index];
  }

  IconData _categoryIcon(String category) {
    final match = categories.firstWhere(
      (c) => c['name'] == category,
      orElse: () => {},
    );
    if (match.isEmpty) return Icons.category_rounded;
    switch (match['icon'] as String) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'receipt':
        return Icons.receipt_long_rounded;
      case 'movie':
        return Icons.movie_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'medical':
        return Icons.medical_services_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'flight':
        return Icons.flight_rounded;
      case 'work':
        return Icons.work_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Insights',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: loadData,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceElevated,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _monthSelector(),
                    const SizedBox(height: 16),

                    if (expenses.isEmpty)
                      _emptyState()
                    else ...[
                      _summaryCard(),
                      const SizedBox(height: 14),
                      _quickStatsRow(),
                      const SizedBox(height: 24),
                      _sectionTitle('Category Breakdown'),
                      const SizedBox(height: 12),
                      _pieChartCard(),
                      const SizedBox(height: 24),
                      _sectionTitle('Daily Spending'),
                      const SizedBox(height: 12),
                      _barChartCard(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  // --------------------------------------------------
  // MONTH SELECTOR
  // --------------------------------------------------

  Widget _monthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            iconSize: 20,
            onPressed: previousMonth,
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.primary,
          ),
        ),
        Column(
          children: [
            Text(
              currentMonth,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${selectedMonth.year}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            iconSize: 20,
            onPressed: isCurrentMonth ? null : nextMonth,
            icon: const Icon(Icons.chevron_right_rounded),
            color: isCurrentMonth
                ? AppColors.textMuted.withValues(alpha: 0.4)
                : AppColors.primary,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // SUMMARY CARD
  // --------------------------------------------------

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Spent',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹${totalSpent.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$transactionCount ${transactionCount == 1 ? 'transaction' : 'transactions'}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // QUICK STATS ROW
  // --------------------------------------------------

  Widget _quickStatsRow() {
    final top = topCategory;
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: top != null ? _categoryIcon(top.key) : Icons.star_rounded,
            title: 'Top Category',
            value: top?.key ?? '—',
            subtitle: top != null ? '₹${top.value.toStringAsFixed(0)}' : '',
            accent: top != null
                ? _categoryColor(top.key)
                : AppColors.primary.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: Icons.calendar_today_rounded,
            title: 'Daily Avg',
            value: '₹${dailyAverage.toStringAsFixed(0)}',
            subtitle: 'per day',
            accent: AppColors.primary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // PIE CHART
  // --------------------------------------------------

  Widget _pieChartCard() {
    final breakdown = categoryBreakdown;
    final total = totalSpent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Pie
          SizedBox(
            width: 140,
            height: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 34,
                startDegreeOffset: -90,
                sections: breakdown.asMap().entries.map((e) {
                  final index = e.key;
                  final entry = e.value;
                  final percent = total > 0 ? (entry.value / total) * 100 : 0.0;
                  return PieChartSectionData(
                    color: AppColors
                        .chartPalette[index % AppColors.chartPalette.length],
                    value: entry.value,
                    title: percent >= 8 ? '${percent.toStringAsFixed(0)}%' : '',
                    radius: 28,
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Legend
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: breakdown.asMap().entries.take(5).map((e) {
                final index = e.key;
                final entry = e.value;
                final color = AppColors
                    .chartPalette[index % AppColors.chartPalette.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '₹${entry.value.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // BAR CHART
  // --------------------------------------------------

  Widget _barChartCard() {
    final daily = dailyTotals;
    if (daily.isEmpty) {
      return const SizedBox.shrink();
    }

    final daysInMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;

    final maxY = daily.values.fold<double>(0, (prev, v) => v > prev ? v : prev);
    // Add headroom
    final chartMaxY = maxY > 0 ? maxY * 1.2 : 100.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: chartMaxY,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final day = group.x.toInt();
                  final amount = rod.toY;
                  return BarTooltipItem(
                    'Day $day\n₹${amount.toStringAsFixed(0)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: chartMaxY / 3,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    return Text(
                      '₹${value.toInt()}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  getTitlesWidget: (value, meta) {
                    final day = value.toInt();
                    // Show every 5th day to avoid clutter
                    if (day == 1 || day % 5 == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '$day',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: chartMaxY / 3,
              getDrawingHorizontalLine: (value) {
                return FlLine(color: AppColors.divider, strokeWidth: 1);
              },
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(daysInMonth, (i) {
              final day = i + 1;
              final amount = daily[day] ?? 0;
              return BarChartGroupData(
                x: day,
                barRods: [
                  BarChartRodData(
                    toY: amount,
                    width: 6,
                    color: amount > 0
                        ? AppColors.primary
                        : AppColors.surfaceElevated,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // SECTION TITLE
  // --------------------------------------------------

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }

  // --------------------------------------------------
  // EMPTY STATE
  // --------------------------------------------------

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.insights_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isCurrentMonth
                ? 'No data yet this month'
                : 'No data for $currentMonth ${selectedMonth.year}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add some expenses and come back to see\nyour spending insights.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}
