import 'package:flutter/material.dart';

import '../models/expense_group.dart';
import '../database/database_helper.dart';
import 'group_detail_page.dart';
import '../theme/app_colors.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  List<ExpenseGroup> groups = [];
  Map<int, double> groupIncome = {};
  Map<int, double> groupExpense = {};
  Map<int, int> groupCounts = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadGroups();
  }

  Future<void> loadGroups() async {
    setState(() => isLoading = true);

    final data = await DatabaseHelper.instance.getGroups();
    final loadedGroups = data
        .map((item) => ExpenseGroup.fromMap(item))
        .toList();

    // One query for all groups
    final stats = await DatabaseHelper.instance.getGroupStatsDetailed();

    final incomes = <int, double>{};
    final expenses = <int, double>{};
    final counts = <int, int>{};

    for (final group in loadedGroups) {
      if (group.id == null) continue;
      final s = stats[group.id!];
      incomes[group.id!] = (s?['income'] ?? 0).toDouble();
      expenses[group.id!] = (s?['expense'] ?? 0).toDouble();
      counts[group.id!] = (s?['count'] ?? 0).toInt();
    }

    if (!mounted) return;

    setState(() {
      groups = loadedGroups;
      groupIncome = incomes;
      groupExpense = expenses;
      groupCounts = counts;
      isLoading = false;
    });
  }

  // --------------------------------------------------
  // ADD GROUP
  // --------------------------------------------------

  Future<void> showAddGroupDialog() async {
    final nameController = TextEditingController();
    final budgetController = TextEditingController();
    bool hasBudget = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'New Group',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Name',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'e.g. Goa Trip 2026',
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Toggle budget
                    Row(
                      children: [
                        Checkbox(
                          value: hasBudget,
                          activeColor: AppColors.primary,
                          onChanged: (v) {
                            setDialogState(() {
                              hasBudget = v ?? false;
                            });
                          },
                        ),
                        const Text(
                          'Set a budget',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),

                    if (hasBudget) ...[
                      const SizedBox(height: 4),
                      TextField(
                        controller: budgetController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          prefixText: '₹ ',
                          hintText: '0.00',
                          filled: true,
                          fillColor: AppColors.surfaceElevated,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    double? budget;
                    if (hasBudget) {
                      budget = double.tryParse(budgetController.text.trim());
                      if (budget == null || budget <= 0) {
                        return;
                      }
                    }

                    await DatabaseHelper.instance.insertGroup(
                      name: name,
                      budget: budget,
                    );

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    await loadGroups();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --------------------------------------------------
  // EDIT GROUP
  // --------------------------------------------------

  Future<void> editGroup(ExpenseGroup group) async {
    final nameController = TextEditingController(text: group.name);
    final budgetController = TextEditingController(
      text: group.budget?.toStringAsFixed(0) ?? '',
    );
    bool hasBudget = group.hasBudget;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Edit Group',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Name',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: hasBudget,
                          activeColor: AppColors.primary,
                          onChanged: (v) {
                            setDialogState(() => hasBudget = v ?? false);
                          },
                        ),
                        const Text(
                          'Set a budget',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (hasBudget) ...[
                      const SizedBox(height: 4),
                      TextField(
                        controller: budgetController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          prefixText: '₹ ',
                          hintText: '0.00',
                          filled: true,
                          fillColor: AppColors.surfaceElevated,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    double? budget;
                    if (hasBudget) {
                      budget = double.tryParse(budgetController.text.trim());
                      if (budget == null || budget <= 0) return;
                    }

                    await DatabaseHelper.instance.updateGroup(
                      group.id!,
                      name: name,
                      budget: budget,
                    );

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    await loadGroups();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --------------------------------------------------
  // DELETE GROUP
  // --------------------------------------------------

  Future<void> confirmDeleteGroup(ExpenseGroup group) async {
    final count = groupCounts[group.id] ?? 0;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Group?'),
          content: Text(
            count > 0
                ? 'Delete "${group.name}"?\n\nThe $count entr${count == 1 ? 'y' : 'ies'} inside will '
                      'become personal entries (not deleted).'
                : 'Delete "${group.name}"?',
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

    if (shouldDelete != true) return;

    await DatabaseHelper.instance.deleteGroup(group.id!);
    await loadGroups();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${group.name}"'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --------------------------------------------------
  // OPEN GROUP
  // --------------------------------------------------

  Future<void> openGroup(ExpenseGroup group) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GroupDetailPage(group: group)),
    );
    await loadGroups();
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
          'Groups',
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
          : groups.isEmpty
          ? _emptyState()
          : RefreshIndicator(
              onRefresh: loadGroups,
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: groups.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _groupCard(groups[index]);
                },
              ),
            ),

      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new_group',
        onPressed: showAddGroupDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Group',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // WIDGETS
  // --------------------------------------------------

  Widget _groupCard(ExpenseGroup group) {
    final income = groupIncome[group.id] ?? 0;
    final expense = groupExpense[group.id] ?? 0;
    final net = income - expense;
    final count = groupCounts[group.id] ?? 0;

    final hasBudget = group.hasBudget;
    final budget = group.budget ?? 0;

    final ratio = hasBudget && budget > 0
        ? (expense / budget).clamp(0.0, 1.0)
        : 0.0;

    final isOver = hasBudget && expense > budget;

    return GestureDetector(
      onTap: () => openGroup(group),
      onLongPress: () => _showGroupActions(group),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.folder_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$count ${count == 1 ? 'entry' : 'entries'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Net balance
            Text(
              '₹${net.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isOver ? AppColors.expense : AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 4),

            // Income / Expense sub-row
            Row(
              children: [
                Icon(
                  Icons.arrow_downward_rounded,
                  size: 12,
                  color: AppColors.income,
                ),
                const SizedBox(width: 4),
                Text(
                  '₹${income.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.income,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_upward_rounded,
                  size: 12,
                  color: AppColors.expense,
                ),
                const SizedBox(width: 4),
                Text(
                  '₹${expense.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.expense,
                  ),
                ),
              ],
            ),

            if (hasBudget) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOver ? AppColors.expense : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isOver
                    ? 'Over by ₹${(expense - budget).toStringAsFixed(0)}'
                    : '₹${(budget - expense).toStringAsFixed(0)} of budget left',
                style: TextStyle(
                  fontSize: 12,
                  color: isOver ? AppColors.expense : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showGroupActions(ExpenseGroup group) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(
                    Icons.edit_rounded,
                    color: AppColors.textPrimary,
                  ),
                  title: const Text(
                    'Edit',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    editGroup(group);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.expense,
                  ),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: AppColors.expense),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    confirmDeleteGroup(group);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No groups yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a group to track expenses for a trip,\n'
              'event, or project — all in one place.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: showAddGroupDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create your first group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
