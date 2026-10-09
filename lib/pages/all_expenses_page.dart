import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../database/database_helper.dart';
import '../theme/app_colors.dart';

class AllExpensesPage extends StatefulWidget {
  const AllExpensesPage({super.key});

  @override
  State<AllExpensesPage> createState() => _AllExpensesPageState();
}

class _AllExpensesPageState extends State<AllExpensesPage> {
  List<Expense> allExpenses = [];
  List<Map<String, dynamic>> categories = [];
  Map<int, String> groupNames = {};

  // Filters
  String searchQuery = '';
  String scope = 'all'; // 'all' | 'personal' | 'groups'
  int? selectedGroupId; // only when scope == 'groups'; null = all groups

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final expenseData = await DatabaseHelper.instance.getExpenses();
    final categoryData = await DatabaseHelper.instance.getCategories();
    final groupMap = await DatabaseHelper.instance.getGroupNames();

    if (!mounted) return;

    setState(() {
      allExpenses = expenseData.map((e) => Expense.fromMap(e)).toList();
      categories = categoryData;
      groupNames = groupMap;
    });
  }

  // --------------------------------------------------
  // FILTERED LIST
  // --------------------------------------------------

  List<Expense> get filteredExpenses {
    return allExpenses.where((expense) {
      switch (scope) {
        case 'personal':
          if (expense.groupId != null) return false;
          break;
        case 'groups':
          if (expense.groupId == null) return false;
          if (selectedGroupId != null && expense.groupId != selectedGroupId) {
            return false;
          }
          break;
      }

      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchesDescription = expense.description.toLowerCase().contains(
          q,
        );
        final matchesCategory = expense.category.toLowerCase().contains(q);
        if (!matchesDescription && !matchesCategory) return false;
      }

      return true;
    }).toList();
  }

  double get filteredIncome => filteredExpenses
      .where((e) => e.isIncome)
      .fold(0, (sum, e) => sum + e.amount);

  double get filteredExpense => filteredExpenses
      .where((e) => e.isExpense)
      .fold(0, (sum, e) => sum + e.amount);

  double get filteredNet => filteredIncome - filteredExpense;

  // --------------------------------------------------
  // GROUP BY DATE
  // --------------------------------------------------

  Map<String, List<Expense>> get groupedExpenses {
    final map = <String, List<Expense>>{};
    for (final expense in filteredExpenses) {
      final date = DateTime.parse(expense.date);
      final key = _dateKey(date);
      map.putIfAbsent(key, () => []).add(expense);
    }
    return map;
  }

  String _dateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return _formatFullDate(date);
  }

  String _formatFullDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // --------------------------------------------------
  // DELETE
  // --------------------------------------------------

  Future<bool> confirmDelete(Expense expense) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Expense?'),
          content: Text(
            'Delete "${expense.description}" of '
            '₹${expense.amount.toStringAsFixed(2)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.expense),
              ),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  Future<void> deleteExpense(Expense expense) async {
    if (expense.id == null) return;
    await DatabaseHelper.instance.deleteExpense(expense.id!);

    if (!mounted) return;

    setState(() {
      allExpenses.removeWhere((e) => e.id == expense.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${expense.description}"'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --------------------------------------------------
  // GROUP PICKER
  // --------------------------------------------------

  Future<void> showGroupPicker() async {
    final groups = groupNames.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));

    final result = await showModalBottomSheet<Object?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select Group',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                _groupOption(
                  label: 'All groups',
                  selected: selectedGroupId == null,
                  onTap: () => Navigator.pop(sheetContext, 'all'),
                ),

                ...groups.map(
                  (e) => _groupOption(
                    label: e.value,
                    selected: selectedGroupId == e.key,
                    onTap: () => Navigator.pop(sheetContext, e.key),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );

    if (result == null) return;

    setState(() {
      if (result == 'all') {
        selectedGroupId = null;
      } else if (result is int) {
        selectedGroupId = result;
      }
    });
  }

  Widget _groupOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }

  // --------------------------------------------------
  // CATEGORY HELPERS
  // --------------------------------------------------

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

  Color _categoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Transport':
        return Colors.blue;
      case 'Shopping':
        return Colors.pink;
      case 'Bills':
        return Colors.red;
      case 'Entertainment':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final grouped = groupedExpenses;
    final groupKeys = grouped.keys.toList();

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'All Expenses',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                _summaryCard(),
                const SizedBox(height: 14),

                // Search
                TextField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() => searchQuery = value.trim());
                  },
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search by description or category',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              searchController.clear();
                              setState(() => searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),

                const SizedBox(height: 12),

                // Scope chips row
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _scopeChip(
                        label: 'All',
                        selected: scope == 'all',
                        onTap: () {
                          setState(() {
                            scope = 'all';
                            selectedGroupId = null;
                          });
                        },
                      ),
                      _scopeChip(
                        label: 'Personal',
                        selected: scope == 'personal',
                        onTap: () {
                          setState(() {
                            scope = 'personal';
                            selectedGroupId = null;
                          });
                        },
                      ),
                      _scopeChip(
                        label: scope == 'groups'
                            ? (selectedGroupId != null
                                  ? (groupNames[selectedGroupId] ?? 'Group')
                                  : 'All groups')
                            : 'Groups',
                        selected: scope == 'groups',
                        icon: Icons.folder_rounded,
                        onTap: () async {
                          setState(() => scope = 'groups');
                          await showGroupPicker();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),
              ],
            ),
          ),

          // List
          Expanded(
            child: filteredExpenses.isEmpty
                ? _emptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: groupKeys.length,
                    itemBuilder: (context, index) {
                      final key = groupKeys[index];
                      final items = grouped[key]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  key,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '₹${items.fold<double>(0, (s, e) => s + e.amount).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...items.map(
                            (expense) => _swipeableExpenseCard(expense),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // SUMMARY CARD
  // --------------------------------------------------

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtered Total',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${filteredNet.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${filteredExpenses.length} ${filteredExpenses.length == 1 ? 'item' : 'items'}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _summarySub(
                  label: 'Income',
                  value: filteredIncome,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 28,
                color: Colors.white.withValues(alpha: 0.20),
              ),
              Expanded(
                child: _summarySub(
                  label: 'Expended',
                  value: filteredExpense,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summarySub({
    required String label,
    required double value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 12),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '₹${value.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // SCOPE CHIP
  // --------------------------------------------------

  Widget _scopeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected ? Colors.black : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.black : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (selected && icon != null) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Colors.black,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // EXPENSE CARD
  // --------------------------------------------------

  Widget _swipeableExpenseCard(Expense expense) {
    return Dismissible(
      key: ValueKey('see-all-expense-${expense.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => confirmDelete(expense),
      onDismissed: (_) => deleteExpense(expense),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
      ),
      child: _expenseCard(expense),
    );
  }

  Widget _expenseCard(Expense expense) {
    final color = expense.isIncome
        ? AppColors.income
        : _categoryColor(expense.category);

    final iconData = expense.isIncome
        ? Icons.arrow_downward_rounded
        : _categoryIcon(expense.category);

    final groupName = expense.groupId != null
        ? groupNames[expense.groupId]
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(iconData, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      expense.category,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (groupName != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          groupName,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${expense.isIncome ? '+' : '−'}₹${expense.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: expense.isIncome ? AppColors.income : AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // EMPTY STATE
  // --------------------------------------------------

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No matching expenses',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try changing your search or filter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
