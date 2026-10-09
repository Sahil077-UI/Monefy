import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(databasePath, 'expense_monitor.db');

    return await openDatabase(
      path,

      // DATABASE VERSION
      version: 6,

      // ------------------------------------------------
      // CREATE NEW DATABASE
      // ------------------------------------------------
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL,
            description TEXT NOT NULL,
            category TEXT NOT NULL,
            date TEXT NOT NULL,
            group_id INTEGER,
            type TEXT NOT NULL DEFAULT 'expense'
          )
        ''');

        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            icon TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE groups (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            budget REAL,
            created_at TEXT NOT NULL
          )
        ''');

        // Default categories
        await db.insert('categories', {'name': 'Food', 'icon': 'restaurant'});
        await db.insert('categories', {
          'name': 'Transport',
          'icon': 'directions_car',
        });
        await db.insert('categories', {
          'name': 'Shopping',
          'icon': 'shopping_bag',
        });
        await db.insert('categories', {'name': 'Bills', 'icon': 'receipt'});
        await db.insert('categories', {
          'name': 'Entertainment',
          'icon': 'movie',
        });
        await db.insert('categories', {'name': 'Other', 'icon': 'category'});
      },

      // ------------------------------------------------
      // DATABASE MIGRATION
      // ------------------------------------------------
      onUpgrade: (db, oldVersion, newVersion) async {
        // Version 1 → Version 2
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE
            )
          ''');

          await db.insert('categories', {'name': 'Food'});
          await db.insert('categories', {'name': 'Transport'});
          await db.insert('categories', {'name': 'Shopping'});
          await db.insert('categories', {'name': 'Bills'});
          await db.insert('categories', {'name': 'Entertainment'});
          await db.insert('categories', {'name': 'Other'});
        }

        // Version 2 → Version 3
        if (oldVersion < 3) {
          await db.execute('''
            ALTER TABLE categories
            ADD COLUMN icon TEXT
            NOT NULL DEFAULT 'category'
          ''');

          await db.update(
            'categories',
            {'icon': 'restaurant'},
            where: 'name = ?',
            whereArgs: ['Food'],
          );
          await db.update(
            'categories',
            {'icon': 'directions_car'},
            where: 'name = ?',
            whereArgs: ['Transport'],
          );
          await db.update(
            'categories',
            {'icon': 'shopping_bag'},
            where: 'name = ?',
            whereArgs: ['Shopping'],
          );
          await db.update(
            'categories',
            {'icon': 'receipt'},
            where: 'name = ?',
            whereArgs: ['Bills'],
          );
          await db.update(
            'categories',
            {'icon': 'movie'},
            where: 'name = ?',
            whereArgs: ['Entertainment'],
          );
          await db.update(
            'categories',
            {'icon': 'category'},
            where: 'name = ?',
            whereArgs: ['Other'],
          );
        }

        // Version 3 → Version 4
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
        }

        // Version 4 → Version 5
        if (oldVersion < 5) {
          // Groups table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS groups (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              budget REAL,
              created_at TEXT NOT NULL
            )
          ''');

          // Add group_id to expenses (nullable)
          // Use try/catch since ALTER TABLE ADD COLUMN fails if it already exists
          try {
            await db.execute(
              'ALTER TABLE expenses ADD COLUMN group_id INTEGER',
            );
          } catch (_) {
            // Column already exists — fine
          }
        }

        // Version 5 → Version 6
        if (oldVersion < 6) {
          try {
            await db.execute(
              "ALTER TABLE expenses ADD COLUMN type TEXT NOT NULL DEFAULT 'expense'",
            );
          } catch (_) {
            // Column already exists — fine
          }
        }
      },
    );
  }

  // ==================================================
  // EXPENSE METHODS
  // ==================================================

  Future<int> insertExpense(Map<String, dynamic> expense) async {
    final db = await database;
    return await db.insert('expenses', expense);
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final db = await database;
    return await db.query('expenses', orderBy: 'id DESC');
  }

  /// Returns only expenses that are NOT part of any group.
  /// This is what Home uses (per design decision B).
  Future<List<Map<String, dynamic>>> getUngroupedExpenses() async {
    final db = await database;
    return await db.query(
      'expenses',
      where: 'group_id IS NULL',
      orderBy: 'id DESC',
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateExpense(int id, Map<String, dynamic> expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Ungrouped expenses for a specific month (used by Home).
  Future<List<Map<String, dynamic>>> getUngroupedExpensesByMonth(
    int year,
    int month,
  ) async {
    final db = await database;
    final monthString = month.toString().padLeft(2, '0');
    final prefix = '$year-$monthString';

    return await db.query(
      'expenses',
      where: 'group_id IS NULL AND date LIKE ?',
      whereArgs: ['$prefix%'],
      orderBy: 'date DESC',
    );
  }

  /// All expenses for a given month (used by See All page).
  Future<List<Map<String, dynamic>>> getExpensesByMonth(
    int year,
    int month,
  ) async {
    final db = await database;
    final monthString = month.toString().padLeft(2, '0');
    final prefix = '$year-$monthString';

    return await db.query(
      'expenses',
      where: 'date LIKE ?',
      whereArgs: ['$prefix%'],
      orderBy: 'date DESC',
    );
  }

  /// All expenses belonging to a specific group.
  Future<List<Map<String, dynamic>>> getExpensesByGroup(int groupId) async {
    final db = await database;
    return await db.query(
      'expenses',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'date DESC',
    );
  }

  // ==================================================
  // CATEGORY METHODS
  // ==================================================

  Future<int> insertCategory(String name, String icon) async {
    final db = await database;
    return await db.insert('categories', {
      'name': name,
      'icon': icon,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return await db.query('categories', orderBy: 'name ASC');
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ==================================================
  // SETTINGS METHODS
  // ==================================================

  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ==================================================
  // GROUP METHODS
  // ==================================================

  Future<int> insertGroup({required String name, double? budget}) async {
    final db = await database;
    return await db.insert('groups', {
      'name': name,
      'budget': budget,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getGroups() async {
    final db = await database;
    return await db.query('groups', orderBy: 'created_at DESC');
  }

  Future<int> updateGroup(
    int id, {
    required String name,
    double? budget,
  }) async {
    final db = await database;
    return await db.update(
      'groups',
      {'name': name, 'budget': budget},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteGroup(int id) async {
    final db = await database;

    // Detach expenses from this group first (set to NULL) so they
    // become personal expenses rather than being deleted.
    await db.update(
      'expenses',
      {'group_id': null},
      where: 'group_id = ?',
      whereArgs: [id],
    );

    return await db.delete('groups', where: 'id = ?', whereArgs: [id]);
  }

  /// Sum of all expenses in a group.
  Future<double> getGroupTotal(int groupId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE group_id = ?',
      [groupId],
    );
    final total = result.first['total'];
    return total == null ? 0.0 : (total as num).toDouble();
  }

  /// Count of expenses in a group.
  Future<int> getGroupExpenseCount(int groupId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM expenses WHERE group_id = ?',
      [groupId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// Returns a map of groupId → { income, expense, count } for all groups.
  Future<Map<int, Map<String, num>>> getGroupStatsDetailed() async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT group_id,
           COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS income,
           COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS expense,
           COUNT(*) AS count
    FROM expenses
    WHERE group_id IS NOT NULL
    GROUP BY group_id
  ''');

    final stats = <int, Map<String, num>>{};
    for (final row in result) {
      final id = row['group_id'] as int;
      stats[id] = {
        'income': (row['income'] as num?) ?? 0,
        'expense': (row['expense'] as num?) ?? 0,
        'count': (row['count'] as num?) ?? 0,
      };
    }
    return stats;
  }

  /// Expenses belonging to groups for a given month.
  /// If [groupId] is provided, only entries in that group are returned.
  Future<List<Map<String, dynamic>>> getGroupedExpensesByMonth(
    int year,
    int month, {
    int? groupId,
  }) async {
    final db = await database;
    final monthString = month.toString().padLeft(2, '0');
    final prefix = '$year-$monthString';

    final where = <String>['group_id IS NOT NULL', 'date LIKE ?'];
    final args = <Object?>['$prefix%'];

    if (groupId != null) {
      where.add('group_id = ?');
      args.add(groupId);
    }

    return await db.query(
      'expenses',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'date DESC',
    );
  }

  /// Map of groupId → group name, for badges and the picker.
  Future<Map<int, String>> getGroupNames() async {
    final db = await database;
    final rows = await db.query('groups', columns: ['id', 'name']);
    final map = <int, String>{};
    for (final r in rows) {
      map[r['id'] as int] = r['name'] as String;
    }
    return map;
  }
}
