import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';

class CsvExporter {
  /// Export personal (ungrouped) expenses, optionally filtered by date range.
  static Future<void> exportPersonalExpenses({
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final where = <String>['group_id IS NULL'];
    final args = <Object?>[];

    _applyDateFilter(where, args, from, to, 'date');

    final data = await db.query(
      'expenses',
      where: where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC',
    );

    final rows = <List<String>>[
      ['Date', 'Description', 'Category', 'Amount'],
    ];

    for (final row in data) {
      rows.add([
        _formatDate(row['date'] as String),
        row['description'] as String,
        row['category'] as String,
        (row['amount'] as num).toStringAsFixed(2),
      ]);
    }

    if (rows.length == 1) {
      throw Exception('No personal expenses matched the filter.');
    }

    await _shareCsv(
      rows: rows,
      fileName: 'monefy_personal_${_timestamp()}.csv',
      subject: 'Monefy — Personal Expenses',
      emptyMessage: 'No personal expenses matched the filter.',
    );
  }

  /// Export group expenses, optionally filtered by date range and/or group.
  static Future<void> exportGroupExpenses({
    DateTime? from,
    DateTime? to,
    int? groupId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final where = <String>['e.group_id IS NOT NULL'];
    final args = <Object?>[];

    if (groupId != null) {
      where.add('e.group_id = ?');
      args.add(groupId);
    }

    _applyDateFilter(where, args, from, to, 'e.date');

    final data = await db.rawQuery('''
      SELECT e.date, e.description, e.category, e.amount,
             g.name AS group_name
      FROM expenses e
      INNER JOIN groups g ON e.group_id = g.id
      WHERE ${where.join(' AND ')}
      ORDER BY g.name ASC, e.date DESC
    ''', args.isEmpty ? null : args);

    final rows = <List<String>>[
      ['Date', 'Description', 'Category', 'Amount', 'Group'],
    ];

    for (final row in data) {
      rows.add([
        _formatDate(row['date'] as String),
        row['description'] as String,
        row['category'] as String,
        (row['amount'] as num).toStringAsFixed(2),
        row['group_name'] as String,
      ]);
    }

    if (rows.length == 1) {
      throw Exception('No group expenses matched the filter.');
    }

    await _shareCsv(
      rows: rows,
      fileName: 'monefy_group_${_timestamp()}.csv',
      subject: 'Monefy — Group Expenses',
      emptyMessage: 'No group expenses matched the filter.',
    );
  }

  /// Export both personal and group files at once with the same filter.
  static Future<void> exportAll({
    DateTime? from,
    DateTime? to,
    int? groupId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    // Personal
    final pWhere = <String>['group_id IS NULL'];
    final pArgs = <Object?>[];
    _applyDateFilter(pWhere, pArgs, from, to, 'date');

    final personal = await db.query(
      'expenses',
      where: pWhere.join(' AND '),
      whereArgs: pArgs.isEmpty ? null : pArgs,
      orderBy: 'date DESC',
    );

    final personalRows = <List<String>>[
      ['Date', 'Description', 'Category', 'Amount'],
    ];
    for (final row in personal) {
      personalRows.add([
        _formatDate(row['date'] as String),
        row['description'] as String,
        row['category'] as String,
        (row['amount'] as num).toStringAsFixed(2),
      ]);
    }

    // Group
    final gWhere = <String>['e.group_id IS NOT NULL'];
    final gArgs = <Object?>[];
    if (groupId != null) {
      gWhere.add('e.group_id = ?');
      gArgs.add(groupId);
    }
    _applyDateFilter(gWhere, gArgs, from, to, 'e.date');

    final grouped = await db.rawQuery('''
      SELECT e.date, e.description, e.category, e.amount,
             g.name AS group_name
      FROM expenses e
      INNER JOIN groups g ON e.group_id = g.id
      WHERE ${gWhere.join(' AND ')}
      ORDER BY g.name ASC, e.date DESC
    ''', gArgs.isEmpty ? null : gArgs);

    final groupRows = <List<String>>[
      ['Date', 'Description', 'Category', 'Amount', 'Group'],
    ];
    for (final row in grouped) {
      groupRows.add([
        _formatDate(row['date'] as String),
        row['description'] as String,
        row['category'] as String,
        (row['amount'] as num).toStringAsFixed(2),
        row['group_name'] as String,
      ]);
    }

    if (personalRows.length == 1 && groupRows.length == 1) {
      throw Exception('No expenses matched the filter.');
    }

    final files = <XFile>[];

    if (personalRows.length > 1) {
      final pFile = await _writeCsvFile(
        rows: personalRows,
        fileName: 'monefy_personal_${_timestamp()}.csv',
      );
      files.add(XFile(pFile.path));
    }

    if (groupRows.length > 1) {
      final gFile = await _writeCsvFile(
        rows: groupRows,
        fileName: 'monefy_group_${_timestamp()}.csv',
      );
      files.add(XFile(gFile.path));
    }

    await SharePlus.instance.share(
      ShareParams(
        files: files,
        subject: 'Monefy — Expense Export',
        text: 'Your Monefy expense data.',
      ),
    );
  }

  // --------------------------------------------------
  // HELPERS
  // --------------------------------------------------

  /// Builds a WHERE clause fragment for a date range on a given column.
  /// `from` is inclusive (start of day), `to` is inclusive (end of day).
  static void _applyDateFilter(
    List<String> where,
    List<Object?> args,
    DateTime? from,
    DateTime? to,
    String column,
  ) {
    if (from != null) {
      final start = DateTime(from.year, from.month, from.day, 0, 0, 0);
      where.add('$column >= ?');
      args.add(start.toIso8601String());
    }
    if (to != null) {
      final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
      where.add('$column <= ?');
      args.add(end.toIso8601String());
    }
  }

  static Future<void> _shareCsv({
    required List<List<String>> rows,
    required String fileName,
    required String subject,
    required String emptyMessage,
  }) async {
    if (rows.length <= 1) {
      throw Exception(emptyMessage);
    }

    final file = await _writeCsvFile(rows: rows, fileName: fileName);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: subject,
        text: 'Your Monefy expense data.',
      ),
    );
  }

  static Future<File> _writeCsvFile({
    required List<List<String>> rows,
    required String fileName,
  }) async {
    final csvString = _toCsv(rows);

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');

    await file.writeAsString(csvString);

    return file;
  }

  static String _toCsv(List<List<String>> rows) {
    final buffer = StringBuffer();

    for (final row in rows) {
      final escaped = row.map(_escapeField).join(',');
      buffer.writeln(escaped);
    }

    return buffer.toString();
  }

  static String _escapeField(String value) {
    final needsQuoting = value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');

    if (!needsQuoting) return value;

    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  static String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      final yyyy = d.year.toString().padLeft(4, '0');
      final mm = d.month.toString().padLeft(2, '0');
      final dd = d.day.toString().padLeft(2, '0');
      return '$yyyy-$mm-$dd';
    } catch (_) {
      return iso;
    }
  }

  static String _timestamp() {
    final now = DateTime.now();
    final y = now.year.toString();
    final mo = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final mi = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    return '$y$mo${d}_$h$mi$s';
  }
}