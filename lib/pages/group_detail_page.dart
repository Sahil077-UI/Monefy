import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../models/expense_group.dart';
import '../database/database_helper.dart';
import '../theme/app_colors.dart';
import 'all_expenses_page.dart';

class GroupDetailPage extends StatefulWidget {
  final ExpenseGroup group;

  const GroupDetailPage({super.key, required this.group});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  List<Expense> expenses = [];
  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;

  double get totalSpent {
    // Only expenses — used for the budget comparison
    double total = 0;
    for (final e in expenses) {
      if (e.isExpense) total += e.amount;
    }
    return total;
  }

  double get totalIncome {
    double total = 0;
    for (final e in expenses) {
      if (e.isIncome) total += e.amount;
    }
    return total;
  }

  double get totalExpense => totalSpent; // alias for clarity

  double get netBalance => totalIncome - totalExpense;

  double get groupBudget => widget.group.budget ?? 0;

  bool get hasBudget => widget.group.hasBudget;

  bool get isOverBudget => hasBudget && totalSpent > groupBudget;

  double get budgetProgress {
    if (!hasBudget || groupBudget <= 0) return 0;
    return (totalSpent / groupBudget).clamp(0.0, 1.0);
  }

  /// Map of category → total amount, sorted descending.
  List<MapEntry<String, double>> get categoryBreakdown {
    final map = <String, double>{};
    for (final e in expenses) {
      if (e.isExpense) {
        // 👈 skip income
        map[e.category] = (map[e.category] ?? 0) + e.amount;
      }
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);

    final expenseData = await DatabaseHelper.instance.getExpensesByGroup(
      widget.group.id!,
    );
    final categoryData = await DatabaseHelper.instance.getCategories();

    if (!mounted) return;

    setState(() {
      expenses = expenseData.map((e) => Expense.fromMap(e)).toList();
      categories = categoryData;
      isLoading = false;
    });
  }

  // --------------------------------------------------
  // ADD EXPENSE (pre-tagged to this group)
  // --------------------------------------------------

  Future<void> addExpense() async {
    final Expense? newExpense = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AddGroupExpensePage(
          groupId: widget.group.id!,
          categories: categories,
        ),
      ),
    );

    if (newExpense == null) return;

    await DatabaseHelper.instance.insertExpense(newExpense.toMap());
    await loadData();
  }

  // --------------------------------------------------
  // EDIT EXPENSE (pre-tagged to this group)
  // --------------------------------------------------

  Future<void> editExpense(Expense expense) async {
    final Expense? updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AddGroupExpensePage(
          groupId: widget.group.id!,
          categories: categories,
          existing: expense,
        ),
      ),
    );

    if (updated == null) return;

    await DatabaseHelper.instance.updateExpense(updated.id!, updated.toMap());

    await loadData();
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
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
    await loadData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${expense.description}"'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --------------------------------------------------
  // CATEGORY HELPERS (same as elsewhere)
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          widget.group.name,
          style: const TextStyle(
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
              backgroundColor: AppColors.surface,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _totalCard(),
                    const SizedBox(height: 20),

                    if (expenses.isNotEmpty) ...[
                      const Text(
                        'Category Breakdown',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _categoryBreakdownCard(),
                      const SizedBox(height: 24),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Expenses',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AllExpensesPage(),
                              ),
                            );
                            await loadData();
                          },
                          child: const Text(
                            'See all',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (expenses.isEmpty)
                      _emptyExpenses()
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: expenses.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _expenseRow(expenses[index]);
                        },
                      ),
                  ],
                ),
              ),
            ),

      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'group_add_expense',
        onPressed: addExpense,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Expense',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // TOTAL CARD
  // --------------------------------------------------

  Widget _totalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isOverBudget
            ? AppColors.expenseGradient
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: (isOverBudget ? AppColors.expense : AppColors.primary)
                .withValues(alpha: 0.25),
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
                'Net Balance',
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
                  Icons.folder_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹${netBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            netBalance >= 0 ? 'Available balance' : 'Over balance',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 18),

          // Income / Expended inline row
          Row(
            children: [
              Expanded(
                child: _inlineStat(
                  label: 'Income',
                  value: totalIncome,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withValues(alpha: 0.20),
              ),
              Expanded(
                child: _inlineStat(
                  label: 'Expended',
                  value: totalExpense,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),

          if (hasBudget) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Group budget',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  '₹${groupBudget.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: budgetProgress,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.20),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isOverBudget
                  ? '₹${(totalExpense - groupBudget).toStringAsFixed(0)} over budget'
                  : '₹${(groupBudget - totalExpense).toStringAsFixed(0)} remaining',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------
  // INLINE STAT WIDGET
  // --------------------------------------------------

  Widget _inlineStat({
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
          const SizedBox(height: 4),
          Text(
            '₹${value.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // CATEGORY BREAKDOWN
  // --------------------------------------------------

  Widget _categoryBreakdownCard() {
    final breakdown = categoryBreakdown;
    final total = totalSpent;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: breakdown.map((entry) {
          final category = entry.key;
          final amount = entry.value;
          final percent = total > 0 ? amount / total : 0.0;
          final color = _categoryColor(category);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _categoryIcon(category),
                        size: 18,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${(percent * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // --------------------------------------------------
  // EXPENSE ROW
  // --------------------------------------------------

  Widget _expenseRow(Expense expense) {
    final color = expense.isIncome
        ? AppColors.income
        : _categoryColor(expense.category);

    return Dismissible(
      key: ValueKey('group-expense-${expense.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => confirmDelete(expense),
      onDismissed: (_) => deleteExpense(expense),
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
      ),
      child: GestureDetector(
        onTap: () => editExpense(expense),
        child: Container(
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
                child: Icon(
                  expense.isIncome
                      ? Icons.arrow_downward_rounded
                      : _categoryIcon(expense.category),
                  color: color,
                ),
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
                    Text(
                      expense.category,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${expense.isIncome ? '+' : '−'}₹${expense.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: expense.isIncome
                      ? AppColors.income
                      : AppColors.expense,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // EMPTY STATE
  // --------------------------------------------------

  Widget _emptyExpenses() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No expenses in this group yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap "Add Expense" to start tracking.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ==================================================
// SIMPLE ADD-EXPENSE-FOR-GROUP PAGE
// ==================================================

class _AddGroupExpensePage extends StatefulWidget {
  final int groupId;
  final List<Map<String, dynamic>> categories;
  final Expense? existing;

  const _AddGroupExpensePage({
    required this.groupId,
    required this.categories,
    this.existing,
  });

  @override
  State<_AddGroupExpensePage> createState() => _AddGroupExpensePageState();
}

class _AddGroupExpensePageState extends State<_AddGroupExpensePage> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  String selectedType = 'expense';
  String selectedCategory = 'Food';
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;

    if (existing != null) {
      amountController.text = existing.amount.toStringAsFixed(2);
      descriptionController.text = existing.description;
      selectedCategory = existing.category;
      selectedDate = DateTime.parse(existing.date);
      selectedType = existing.type;
    } else if (widget.categories.isNotEmpty) {
      selectedCategory = widget.categories.first['name'] as String;
    }
  }

  IconData _iconFor(String icon) {
    switch (icon) {
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

  String _formatDate(DateTime date) {
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _typeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _typeToggleOption(
              label: 'Expense',
              icon: Icons.arrow_upward_rounded,
              selected: selectedType == 'expense',
              selectedColor: const Color(0xFFE53935),
              onTap: () {
                setState(() => selectedType = 'expense');
              },
            ),
          ),
          Expanded(
            child: _typeToggleOption(
              label: 'Income',
              icon: Icons.arrow_downward_rounded,
              selected: selectedType == 'income',
              selectedColor: AppColors.income,
              onTap: () {
                setState(() => selectedType = 'income');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeToggleOption({
    required String label,
    required IconData icon,
    required bool selected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void save() {
    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    if (descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description.')),
      );
      return;
    }

    final existing = widget.existing;

    final expense = Expense(
      id: existing?.id,
      amount: amount,
      description: descriptionController.text.trim(),
      category: selectedCategory,
      date: selectedDate.toIso8601String(),
      groupId: widget.groupId,
      type: selectedType,
    );

    Navigator.pop(context, expense);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          widget.existing == null
              ? 'Add Expense'
              : (selectedType == 'income' ? 'Edit Income' : 'Edit Expense'),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _typeToggle(),
            const SizedBox(height: 20),

            const Text(
              'Amount',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                hintText: '0.00',
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(18),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Description',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                hintText: 'e.g. Taxi, Hotel',
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(18),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Date',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(now.year - 5),
                  lastDate: now,
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: AppColors.primary,
                        onPrimary: Colors.black,
                        surface: AppColors.surface,
                        onSurface: AppColors.textPrimary,
                        surfaceContainerHighest: AppColors.surfaceElevated,
                        onSurfaceVariant: AppColors.textSecondary,
                        outline: AppColors.divider,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formatDate(selectedDate),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue:
                  widget.categories.any((c) => c['name'] == selectedCategory)
                  ? selectedCategory
                  : null,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 6,
                ),
              ),
              items: widget.categories.map((c) {
                final name = c['name'] as String;
                final icon = c['icon'] as String;
                return DropdownMenuItem<String>(
                  value: name,
                  child: Row(
                    children: [
                      Icon(_iconFor(icon), size: 22, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedCategory = value);
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: save,
                icon: Icon(
                  selectedType == 'income'
                      ? Icons.arrow_downward_rounded
                      : Icons.check_rounded,
                ),
                label: Text(
                  widget.existing == null
                      ? (selectedType == 'income'
                            ? 'Save Income'
                            : 'Save Expense')
                      : (selectedType == 'income'
                            ? 'Update Income'
                            : 'Update Expense'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedType == 'income'
                      ? AppColors.income
                      : AppColors.expense,
                  foregroundColor: selectedType == 'income'
                      ? Colors.white
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
