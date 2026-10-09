import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/database_helper.dart';
import '../main.dart';
import '../utils/csv_exporter.dart';
import '../theme/app_colors.dart';

DateTime? exportFrom;
DateTime? exportTo;
int? exportGroupId;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController budgetController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadBudget();
  }

  Future<void> loadBudget() async {
    final value = await DatabaseHelper.instance.getSetting('monthly_budget');

    if (!mounted) return;

    setState(() {
      budgetController.text = value ?? '20000';
      isLoading = false;
    });
  }

  Future<void> saveBudget() async {
    final parsed = double.tryParse(budgetController.text.trim());

    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await DatabaseHelper.instance.setSetting(
      'monthly_budget',
      parsed.toString(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Budget saved'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showExportSheet() async {
    // Reset filters each time
    exportFrom = null;
    exportTo = null;
    exportGroupId = null;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
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
                            'Export as CSV',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Filter by date range or group, then pick what to export.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Filter card ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Filters',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Date range
                              Row(
                                children: [
                                  Expanded(
                                    child: _filterChip(
                                      label: exportFrom == null
                                          ? 'From'
                                          : _shortDate(exportFrom!),
                                      active: exportFrom != null,
                                      onTap: () async {
                                        final now = DateTime.now();
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: exportFrom ?? now,
                                          firstDate: DateTime(now.year - 5),
                                          lastDate: now,
                                          builder: (context, child) => Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: ColorScheme.dark(
                                                primary: AppColors.primary,
                                                onPrimary: Colors.black,
                                                surface: AppColors.surface,
                                                onSurface:
                                                    AppColors.textPrimary,
                                              ),
                                            ),
                                            child: child!,
                                          ),
                                        );
                                        if (picked != null) {
                                          setSheetState(() {
                                            exportFrom = picked;
                                            // ensure to >= from
                                            if (exportTo != null &&
                                                exportTo!.isBefore(picked)) {
                                              exportTo = picked;
                                            }
                                          });
                                        }
                                      },
                                      onClear: () {
                                        setSheetState(() => exportFrom = null);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _filterChip(
                                      label: exportTo == null
                                          ? 'To'
                                          : _shortDate(exportTo!),
                                      active: exportTo != null,
                                      onTap: () async {
                                        final now = DateTime.now();
                                        final firstAllowed =
                                            exportFrom ??
                                            DateTime(now.year - 5);
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: exportTo ?? now,
                                          firstDate: firstAllowed,
                                          lastDate: now,
                                          builder: (context, child) => Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: ColorScheme.dark(
                                                primary: AppColors.primary,
                                                onPrimary: Colors.black,
                                                surface: AppColors.surface,
                                                onSurface:
                                                    AppColors.textPrimary,
                                              ),
                                            ),
                                            child: child!,
                                          ),
                                        );
                                        if (picked != null) {
                                          setSheetState(
                                            () => exportTo = picked,
                                          );
                                        }
                                      },
                                      onClear: () {
                                        setSheetState(() => exportTo = null);
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Group picker
                              FutureBuilder<List<Map<String, dynamic>>>(
                                future: DatabaseHelper.instance.getGroups(),
                                builder: (context, snapshot) {
                                  final groups = snapshot.data ?? [];
                                  if (groups.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return _groupPicker(
                                    groups: groups,
                                    selectedId: exportGroupId,
                                    onChanged: (id) {
                                      setSheetState(() => exportGroupId = id);
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Export options
                      _exportOption(
                        context: sheetContext,
                        icon: Icons.person_rounded,
                        title: 'Personal Expenses',
                        subtitle: exportGroupId != null
                            ? 'Group filter ignored for personal'
                            : 'Ungrouped expenses only',
                        onTap: () => CsvExporter.exportPersonalExpenses(
                          from: exportFrom,
                          to: exportTo,
                        ),
                      ),

                      _exportOption(
                        context: sheetContext,
                        icon: Icons.folder_rounded,
                        title: 'Group Expenses',
                        subtitle: exportGroupId == null
                            ? 'All groups'
                            : 'Selected group only',
                        onTap: () => CsvExporter.exportGroupExpenses(
                          from: exportFrom,
                          to: exportTo,
                          groupId: exportGroupId,
                        ),
                      ),

                      _exportOption(
                        context: sheetContext,
                        icon: Icons.inventory_2_rounded,
                        title: 'Both',
                        subtitle: 'Two separate CSV files',
                        onTap: () => CsvExporter.exportAll(
                          from: exportFrom,
                          to: exportTo,
                          groupId: exportGroupId,
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: active ? Colors.black : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.black : AppColors.textPrimary,
                ),
              ),
            ),
            if (active)
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.black,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _groupPicker({
    required List<Map<String, dynamic>> groups,
    required int? selectedId,
    required ValueChanged<int?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: selectedId,
          isExpanded: true,
          dropdownColor: AppColors.surfaceElevated,
          hint: const Text(
            'All groups',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textPrimary),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text(
                'All groups',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ...groups.map((g) {
              return DropdownMenuItem<int?>(
                value: g['id'] as int,
                child: Text(
                  g['name'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _exportOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Future<void> Function() onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      onTap: () async {
        Navigator.pop(context);

        try {
          await onTap();
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFFB00020),
            ),
          );
        }
      },
    );
  }

  String _shortDate(DateTime d) {
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
    return '${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Settings',
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Budget',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Set your monthly spending limit.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Monthly Budget',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: budgetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
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

                  const SizedBox(height: 12),

                  // Quick-pick chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _quickPick('5,000', 5000),
                      _quickPick('10,000', 10000),
                      _quickPick('20,000', 20000),
                      _quickPick('50,000', 50000),
                    ],
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: saveBudget,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text(
                        'Save Budget',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  const Text(
                    'Other',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoriesPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.category_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Manage Categories',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Add or delete expense categories',
                                  style: TextStyle(
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
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Export Data tile
                  GestureDetector(
                    onTap: () => _showExportSheet(),
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.download_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Export Data',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Download expenses as CSV',
                                  style: TextStyle(
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
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _quickPick(String label, double value) {
    return GestureDetector(
      onTap: () {
        budgetController.text = value.toStringAsFixed(0);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Text(
          '₹$label',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    budgetController.dispose();
    super.dispose();
  }
}
