import 'package:flutter/material.dart';

import 'models/expense.dart';
import 'database/database_helper.dart';
import 'pages/all_expenses_page.dart';
import 'main_scaffold.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const ExpenseMonitorApp());
}

// --------------------------------------------------
// MAIN APP
// --------------------------------------------------

class ExpenseMonitorApp extends StatelessWidget {
  const ExpenseMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Monefy',

      // Force dark mode everywhere
      themeMode: ThemeMode.dark,

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        scaffoldBackgroundColor: AppColors.background,

        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          onPrimary: Colors.black,
          secondary: AppColors.primaryLight,
          onSecondary: Colors.black,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          surfaceContainerHighest: AppColors.surfaceElevated,
          error: AppColors.expense,
          onError: Colors.white,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),

        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
          contentTextStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),

        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceElevated,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixStyle: const TextStyle(color: AppColors.textPrimary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),

        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.18),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primary);
            }
            return const IconThemeData(color: AppColors.textSecondary);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              );
            }
            return const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }),
        ),

        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
        ),

        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textPrimary),
          bodySmall: TextStyle(color: AppColors.textSecondary),
          titleLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
          titleMedium: TextStyle(color: AppColors.textPrimary),
        ),

        iconTheme: const IconThemeData(color: AppColors.textSecondary),

        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary,
        ),
      ),

      home: const MainScaffold(),
    );
  }
}

// --------------------------------------------------
// HOME PAGE
// --------------------------------------------------

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Expense> expenses = [];
  List<Map<String, dynamic>> categories = [];
  DateTime selectedDate = DateTime.now();
  double monthlySpending = 0;
  DateTime selectedMonth = DateTime.now();
  int lastNotifiedStatus = 0;

  double monthlyBudget = 20000;

  @override
  void initState() {
    super.initState();
    loadExpenses();
    loadCategories();
    loadBudget();
  }

  // --------------------------------------------------
  // LOAD EXPENSES
  // --------------------------------------------------

  Future<void> loadExpenses() async {
    final data = await DatabaseHelper.instance.getUngroupedExpensesByMonth(
      selectedMonth.year,
      selectedMonth.month,
    );

    final loadedExpenses = data.map((item) => Expense.fromMap(item)).toList();

    double total = 0;
    for (final expense in loadedExpenses) {
      if (expense.isExpense) {
        total += expense.amount;
      }
    }

    if (!mounted) return;

    setState(() {
      expenses = loadedExpenses;
      monthlySpending = total;
    });
  }

  // --------------------------------------------------
  // LOAD CATEGORIES
  // --------------------------------------------------

  Future<void> loadCategories() async {
    final data = await DatabaseHelper.instance.getCategories();

    if (!mounted) return;

    setState(() {
      categories = data;
    });
  }

  // --------------------------------------------------
  // TOTAL SPENDING
  // --------------------------------------------------

  double get totalSpent {
    double total = 0;

    for (final expense in expenses) {
      total += expense.amount;
    }

    return total;
  }

  // --------------------------------------------------
  // MONTHLY INCOME
  // --------------------------------------------------

  double get monthlyIncome {
    double total = 0;
    for (final e in expenses) {
      if (e.isIncome) total += e.amount;
    }
    return total;
  }

  // --------------------------------------------------
  // MONTHLY EXPENSE
  // --------------------------------------------------

  double get monthlyExpense {
    double total = 0;
    for (final e in expenses) {
      if (e.isExpense) total += e.amount;
    }
    return total;
  }

  double get netBalance => monthlyIncome - monthlyExpense;

  int get transactionCount => expenses.length;

  // --------------------------------------------------
  // REMAINING BUDGET
  // --------------------------------------------------

  double get remainingBudget {
    final remaining = monthlyBudget - monthlySpending;
    return remaining < 0 ? 0 : remaining;
  }

  double get budgetProgress =>
      (monthlySpending / monthlyBudget).clamp(0.0, 1.0);

  // --------------------------------------------------
  // ADD EXPENSE
  // --------------------------------------------------

  Future<void> addExpense(Expense expense) async {
    final id = await DatabaseHelper.instance.insertExpense(expense.toMap());

    final savedExpense = Expense(
      id: id,
      amount: expense.amount,
      description: expense.description,
      category: expense.category,
      date: expense.date,
    );

    setState(() {
      expenses.insert(0, savedExpense);
    });
  }

  // --------------------------------------------------
  // EDIT EXPENSE
  // --------------------------------------------------

  Future<void> _editExpense(Expense expense) async {
    final Expense? updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddExpensePage(expense: expense)),
    );

    if (updated == null) return;

    // Save to DB
    await DatabaseHelper.instance.updateExpense(updated.id!, updated.toMap());

    // Reload from DB so totals recompute
    await loadExpenses();
  }

  // --------------------------------------------------
  // HANDLE REFRESH
  // --------------------------------------------------

  Future<void> _handleRefresh() async {
    await Future.wait([loadExpenses(), loadCategories(), loadBudget()]);

    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshed'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --------------------------------------------------
  // BUDGET STATUS BANNER
  // --------------------------------------------------

  Widget _budgetStatusBanner() {
    final status = budgetStatus;

    // Don't show anything if safe
    if (status == 0) return const SizedBox.shrink();

    final ratio = (budgetUsedRatio * 100).clamp(0, 999).toStringAsFixed(0);

    late Color bg;
    late Color fg;
    late IconData icon;
    late String title;
    late String subtitle;

    switch (status) {
      case 1:
        bg = const Color(0xFFFFF3CD);
        fg = const Color(0xFF8A6D3B);
        icon = Icons.warning_amber_rounded;
        title = 'Heads up';
        subtitle = 'You\'ve used $ratio% of your monthly budget.';
        break;
      case 2:
        bg = const Color(0xFFFFE0B2);
        fg = const Color(0xFFB45309);
        icon = Icons.error_outline_rounded;
        title = 'Almost there';
        subtitle = '$ratio% used — spending is running high.';
        break;
      default:
        bg = const Color(0xFFFFD6D6);
        fg = const Color(0xFFB00020);
        icon = Icons.block_rounded;
        title = 'Budget exceeded';
        subtitle =
            'You are ₹${budgetOverspend.toStringAsFixed(0)} over your budget.';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: fg.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // CHECK BUDGET AND NOTIFY
  // --------------------------------------------------

  void _checkBudgetAndNotify() {
    final status = budgetStatus;

    // Only notify when a *new* higher status is reached
    if (status <= lastNotifiedStatus) return;
    if (status == 0) return;

    lastNotifiedStatus = status;

    late String message;
    late Color bg;

    switch (status) {
      case 1:
        message = '75% of your monthly budget used.';
        bg = const Color(0xFF8A6D3B);
        break;
      case 2:
        message = '90% of your monthly budget used!';
        bg = const Color(0xFFB45309);
        break;
      default:
        message = 'Budget exceeded!';
        bg = const Color(0xFFB00020);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --------------------------------------------------
  // PREVIOUS / NEXT MONTH
  // --------------------------------------------------

  Future<void> previousMonth() async {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
      lastNotifiedStatus = 0;
    });
    await loadExpenses();
  }

  Future<void> nextMonth() async {
    if (isCurrentMonth) return;

    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    });
    await loadExpenses();
  }

  // --------------------------------------------------
  // DELETE EXPENSE
  // --------------------------------------------------

  Future<bool> _confirmDelete(Expense expense) async {
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

  Future<void> _deleteExpense(Expense expense) async {
    if (expense.id == null) return;

    await DatabaseHelper.instance.deleteExpense(expense.id!);
    await loadExpenses();

    if (!mounted) return;

    setState(() {
      expenses.removeWhere((e) => e.id == expense.id);

      // Recalculate monthly spending so the top card stays accurate
      final now = DateTime.now();
      double total = 0;
      for (final e in expenses) {
        final date = DateTime.parse(e.date);
        if (date.year == now.year && date.month == now.month) {
          total += e.amount;
        }
      }
      monthlySpending = total;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${expense.description}"'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --------------------------------------------------
  // LOAD BUDGET
  // --------------------------------------------------

  Future<void> loadBudget() async {
    final value = await DatabaseHelper.instance.getSetting('monthly_budget');

    if (!mounted) return;

    setState(() {
      monthlyBudget = value != null ? double.tryParse(value) ?? 20000 : 20000;
    });
  }

  // --------------------------------------------------
  // BUDGET STATUS
  // --------------------------------------------------

  double get budgetUsedRatio {
    if (monthlyBudget <= 0) return 0;
    return monthlySpending / monthlyBudget;
  }

  // Returns: 0 = safe, 1 = warning (>=75%), 2 = critical (>=90%), 3 = over (>=100%)
  int get budgetStatus {
    final ratio = budgetUsedRatio;
    if (ratio >= 1.0) return 3;
    if (ratio >= 0.90) return 2;
    if (ratio >= 0.75) return 1;
    return 0;
  }

  double get budgetRemaining {
    final remaining = monthlyBudget - monthlySpending;
    return remaining < 0 ? 0 : remaining;
  }

  double get budgetOverspend {
    final over = monthlySpending - monthlyBudget;
    return over < 0 ? 0 : over;
  }

  // --------------------------------------------------
  // MONTH NAME
  // --------------------------------------------------

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

  bool get isCurrentMonth {
    final now = DateTime.now();
    return selectedMonth.year == now.year && selectedMonth.month == now.month;
  }

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
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ------------------------------------------------
      // APP BAR
      // ------------------------------------------------

      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monefy',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Manage your money better',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),

      // ------------------------------------------------
      // BODY
      // ------------------------------------------------
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          displacement: 60,

          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),

            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // Budget banner
                if (isCurrentMonth) _budgetStatusBanner(),

                // ------------------------------------------
                // MONTH
                // ------------------------------------------
                FadeSlideIn(
                  delay: const Duration(milliseconds: 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous month arrow
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
                          tooltip: 'Previous month',
                        ),
                      ),

                      // Month label
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

                      // Next month arrow (disabled on current month)
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
                          tooltip: 'Next month',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ------------------------------------------
                // TOTAL SPENDING CARD
                // ------------------------------------------
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: Container(
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
                              'Total Amount',
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
                                Icons.account_balance_wallet_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        TweenAnimationBuilder<double>(
                          key: ValueKey(netBalance),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutBack,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: 0.9 + (value * 0.1),
                              child: Opacity(
                                opacity: value.clamp(0.0, 1.0),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            '₹${netBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          netBalance >= 0
                              ? 'Available balance'
                              : 'Over balance',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Income / Expended inline row inside the card
                        Row(
                          children: [
                            Expanded(
                              child: _inlineStat(
                                label: 'Income',
                                value: monthlyIncome,
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
                                value: monthlyExpense,
                                icon: Icons.arrow_upward_rounded,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Monthly budget',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '₹${monthlyBudget.toStringAsFixed(0)}',
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
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: budgetProgress),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) {
                              return LinearProgressIndicator(
                                value: value,
                                minHeight: 8,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.20,
                                ),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          '₹${remainingBudget.toStringAsFixed(2)} remaining',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ------------------------------------------
                // QUICK STATS
                // ------------------------------------------
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          icon: Icons.arrow_downward_rounded,
                          title: 'Income',
                          value: '₹${monthlyIncome.toStringAsFixed(0)}',
                          accentColor: const Color(0xFF2E7D32),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _statCard(
                          icon: Icons.arrow_upward_rounded,
                          title: 'Expended',
                          value: '₹${monthlyExpense.toStringAsFixed(0)}',
                          accentColor: const Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ------------------------------------------
                // RECENT EXPENSES HEADER
                // ------------------------------------------
                FadeSlideIn(
                  delay: const Duration(milliseconds: 240),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      const Text(
                        'Recent Expenses',
                        style: TextStyle(
                          fontSize: 21,
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

                          await loadExpenses();
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
                ),

                const SizedBox(height: 8),

                // ------------------------------------------
                // EMPTY STATE / LIST
                // ------------------------------------------
                if (expenses.isEmpty)
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 320),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 45,
                        horizontal: 20,
                      ),

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

                          Text(
                            isCurrentMonth
                                ? 'No expenses yet'
                                : 'No expenses this month',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            isCurrentMonth
                                ? 'Start tracking your spending today.'
                                : 'Nothing was recorded in $currentMonth ${selectedMonth.year}.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),

                    itemCount: expenses.length > 5 ? 5 : expenses.length,

                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),

                    itemBuilder: (context, index) {
                      final expense = expenses[index];

                      return FadeSlideIn(
                        delay: Duration(milliseconds: 320 + (60 * index)),
                        offsetY: 10,

                        child: Dismissible(
                          key: ValueKey('home-expense-${expense.id}'),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) => _confirmDelete(expense),
                          onDismissed: (_) => _deleteExpense(expense),
                          background: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.delete_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () => _editExpense(expense),
                            child: _expenseCard(expense),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),

      // ------------------------------------------------
      // ADD BUTTON
      // ------------------------------------------------
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home_add_expense',
        onPressed: () async {
          final Expense? newExpense = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddExpensePage(
                initialDate: isCurrentMonth ? null : selectedMonth,
              ),
            ),
          );

          if (newExpense == null) return;

          await DatabaseHelper.instance.insertExpense(newExpense.toMap());
          await loadExpenses();

          if (!mounted) return;
          _checkBudgetAndNotify();
        },

        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        elevation: 5,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Expense',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // STAT CARD
  // --------------------------------------------------

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    Color accentColor = AppColors.primary,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // EXPENSE CARD
  // --------------------------------------------------

  Widget _expenseCard(Expense expense) {
    final categoryColor = expense.isIncome
        ? const Color(0xFF2E7D32)
        : _categoryColor(expense.category);

    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: AppColors.surface,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: AppColors.divider),
      ),

      child: Row(
        children: [
          // ICON

          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.20),

              borderRadius: BorderRadius.circular(15),
            ),

            child: Icon(
              expense.isIncome
                  ? Icons.arrow_downward_rounded
                  : _categoryIcon(expense.category),
              color: categoryColor,
            ),
          ),

          const SizedBox(width: 14),

          // DESCRIPTION
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

          // AMOUNT
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
  // CATEGORY ICON
  // --------------------------------------------------

  IconData _categoryIcon(String category) {
    final matchingCategory = categories.firstWhere(
      (item) => item['name'] == category,
      orElse: () => {},
    );

    if (matchingCategory.isEmpty) {
      return Icons.category_rounded;
    }

    final icon = matchingCategory['icon'] as String;

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
      case 'category':
        return Icons.category_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  // --------------------------------------------------
  // CATEGORY COLOR
  // --------------------------------------------------

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
}

// ==================================================
// ADD EXPENSE PAGE
// ==================================================

class AddExpensePage extends StatefulWidget {
  final Expense? expense;
  final DateTime? initialDate;

  const AddExpensePage({super.key, this.expense, this.initialDate});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

// ==================================================
// ADD CATEGORY PAGE
// ==================================================

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    final data = await DatabaseHelper.instance.getCategories();

    setState(() {
      categories = data;
    });
  }

  Future<void> addCategory(String name, String icon) async {
    await DatabaseHelper.instance.insertCategory(name, icon);

    await loadCategories();
  }

  IconData getIcon(String icon) {
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

  Future<void> showAddCategoryDialog() async {
    final nameController = TextEditingController();

    String selectedIcon = 'category';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Add Category',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category name',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: nameController,

                      decoration: InputDecoration(
                        hintText: 'e.g. Medical',

                        filled: true,

                        fillColor: AppColors.surface,

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Choose icon',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _iconChoice(
                          icon: 'category',
                          iconData: Icons.category_rounded,
                          selected: selectedIcon == 'category',
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = 'category';
                            });
                          },
                        ),

                        _iconChoice(
                          icon: 'home',
                          iconData: Icons.home_rounded,
                          selected: selectedIcon == 'home',
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = 'home';
                            });
                          },
                        ),

                        _iconChoice(
                          icon: 'medical',
                          iconData: Icons.medical_services_rounded,
                          selected: selectedIcon == 'medical',
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = 'medical';
                            });
                          },
                        ),

                        _iconChoice(
                          icon: 'school',
                          iconData: Icons.school_rounded,
                          selected: selectedIcon == 'school',
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = 'school';
                            });
                          },
                        ),

                        _iconChoice(
                          icon: 'flight',
                          iconData: Icons.flight_rounded,
                          selected: selectedIcon == 'flight',
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = 'flight';
                            });
                          },
                        ),

                        _iconChoice(
                          icon: 'work',
                          iconData: Icons.work_rounded,
                          selected: selectedIcon == 'work',
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = 'work';
                            });
                          },
                        ),

                        _iconChoice(
                          icon: 'shopping_bag',
                          iconData: Icons.shopping_bag_rounded,
                          selected: selectedIcon == 'shopping_bag',
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = 'shopping_bag';
                            });
                          },
                        ),

                        _iconChoice(
                          icon: 'restaurant',
                          iconData: Icons.restaurant_rounded,
                          selected: selectedIcon == 'restaurant',
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = 'restaurant';
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();

                    if (name.isEmpty) {
                      return;
                    }

                    await DatabaseHelper.instance.insertCategory(
                      name,
                      selectedIcon,
                    );

                    if (!context.mounted) return;

                    Navigator.pop(context);

                    await loadCategories();
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                  ),

                  child: const Text('Add Category'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _iconChoice({
    required String icon,
    required IconData iconData,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: 48,
        height: 48,

        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,

          borderRadius: BorderRadius.circular(14),
        ),

        child: Icon(iconData, color: selected ? AppColors.textPrimary : Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,

        title: const Text(
          'Categories',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      body: categories.isEmpty
          ? const Center(
              child: Text(
                'No categories yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),

              itemCount: categories.length,

              separatorBuilder: (context, index) => const SizedBox(height: 10),

              itemBuilder: (context, index) {
                final category = categories[index];

                final name = category['name'] as String;

                final icon = category['icon'] as String;

                return Container(
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: AppColors.surface,

                    borderRadius: BorderRadius.circular(18),
                  ),

                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,

                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),

                        child: Icon(getIcon(icon), color: AppColors.primary),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Text(
                          name,

                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      // Don't allow deletion
                      // of default categories.
                      if (![
                        'Food',
                        'Transport',
                        'Shopping',
                        'Bills',
                        'Entertainment',
                        'Other',
                      ].contains(category['name']))
                        IconButton(
                          onPressed: () async {
                            final shouldDelete = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Delete Category?'),
                                  content: Text(
                                    'Are you sure you want to delete "${category['name']}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context, false);
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context, true);
                                      },
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (shouldDelete != true) {
                              return;
                            }

                            await DatabaseHelper.instance.deleteCategory(
                              category['id'],
                            );

                            await loadCategories();
                          },

                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home_category_add',
        onPressed: showAddCategoryDialog,

        backgroundColor: AppColors.primary,

        foregroundColor: AppColors.textPrimary,

        icon: const Icon(Icons.add_rounded),

        label: const Text(
          'Add Category',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _AddExpensePageState extends State<AddExpensePage> {
  DateTime selectedDate = DateTime.now();
  final TextEditingController amountController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  String selectedCategory = 'Food';
  String selectedType = 'expense'; // or 'income'

  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();

    final existing = widget.expense;

    if (existing != null) {
      amountController.text = existing.amount.toStringAsFixed(2);
      descriptionController.text = existing.description;
      selectedCategory = existing.category;
      selectedDate = DateTime.parse(existing.date);
      selectedType = existing.type; // 👈 add this
    } else if (widget.initialDate != null) {
      final d = widget.initialDate!;
      final now = DateTime.now();
      final candidate = DateTime(d.year, d.month, 1);
      selectedDate = candidate.isAfter(now) ? now : candidate;
    }

    loadCategories();
  }

  Future<void> loadCategories() async {
    final data = await DatabaseHelper.instance.getCategories();

    if (!mounted) return;

    setState(() {
      categories = data;

      // Only auto-select first category when adding a new expense
      if (widget.expense == null && categories.isNotEmpty) {
        selectedCategory = categories.first['name'] as String;
      }
    });
  }

  IconData getCategoryIcon(String icon) {
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

      case 'category':
        return Icons.category_rounded;

      default:
        return Icons.category_rounded;
    }
  }

  // --------------------------------------------------
  // SAVE
  // --------------------------------------------------

  void saveExpense() {
    final double? amount = double.tryParse(amountController.text);

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

    final existing = widget.expense;

    final Expense expense = Expense(
      id: existing?.id,
      amount: amount,
      description: descriptionController.text.trim(),
      category: selectedCategory,
      date: existing?.date ?? selectedDate.toIso8601String(),
      type: selectedType,
    );

    Navigator.pop(context, expense);
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

  // --------------------------------------------------
  // UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          widget.expense == null
              ? (selectedType == 'income' ? 'Add Income' : 'Add Expense')
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

            Text(
              widget.expense == null
                  ? (selectedType == 'income'
                        ? 'Add income'
                        : 'Track your spending')
                  : (selectedType == 'income'
                        ? 'Update income'
                        : 'Update expense'),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              widget.expense == null
                  ? (selectedType == 'income'
                        ? 'Log money you received.'
                        : 'Add a new expense to your records.')
                  : 'Edit the details below and save.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 28),

            // ------------------------------------------
            // AMOUNT
            // ------------------------------------------
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

            // ------------------------------------------
            // DESCRIPTION
            // ------------------------------------------
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: descriptionController,

              decoration: InputDecoration(
                hintText: 'e.g. Dinner, Uber, Groceries',

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

            const SizedBox(height: 20),

            // ------------------------------------------
            // DATE
            // ------------------------------------------
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
                  lastDate: now, // prevent future dates
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.primary,
                          onPrimary: Colors.black,
                          surface: AppColors.surface,
                          onSurface: AppColors.textPrimary,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );

                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
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
                        ),
                      ),
                    ),

                    const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ------------------------------------------
            // CATEGORY
            // ------------------------------------------
            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue:
                  categories.any(
                    (category) => category['name'] == selectedCategory,
                  )
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

              items: categories.map((category) {
                final name = category['name'] as String;

                final icon = category['icon'] as String;

                return DropdownMenuItem<String>(
                  value: name,

                  child: Row(
                    children: [
                      Icon(
                        getCategoryIcon(icon),
                        size: 22,
                        color: AppColors.primary,
                      ),

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

                setState(() {
                  selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 32),

            // ------------------------------------------
            // SAVE BUTTON
            // ------------------------------------------
            SizedBox(
              width: double.infinity,
              height: 56,

              child: ElevatedButton.icon(
                onPressed: saveExpense,

                icon: const Icon(Icons.check_rounded),

                label: Text(
                  widget.expense == null
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
                      : AppColors.textPrimary,

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

// ==================================================
// FADE + SLIDE ANIMATION WIDGET
// ==================================================

class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double offsetY;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 20,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _slide = Tween<Offset>(
      begin: Offset(0, widget.offsetY / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(0, _slide.value.dy * 100),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
