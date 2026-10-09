class Expense {
  final int? id;
  final double amount;
  final String description;
  final String category;
  final String date;
  final int? groupId;
  final String type; // 'expense' or 'income'

  Expense({
    this.id,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    this.groupId,
    this.type = 'expense',
  });

  // Convenience
  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  // Convert Expense → Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'category': category,
      'date': date,
      'group_id': groupId,
      'type': type,
    };
  }

  // Convert Map → Expense
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      category: map['category'] as String,
      date: map['date'] as String,
      groupId: map['group_id'] as int?,
      type: (map['type'] as String?) ?? 'expense',
    );
  }

  Expense copyWith({
    int? id,
    double? amount,
    String? description,
    String? category,
    String? date,
    int? groupId,
    bool clearGroup = false,
    String? type,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      groupId: clearGroup ? null : (groupId ?? this.groupId),
      type: type ?? this.type,
    );
  }
}