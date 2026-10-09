class ExpenseGroup {
  final int? id;
  final String name;
  final double? budget;
  final String createdAt;

  ExpenseGroup({
    this.id,
    required this.name,
    this.budget,
    required this.createdAt,
  });

  // Convert ExpenseGroup → Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'budget': budget,
      'created_at': createdAt,
    };
  }

  // Convert Map → ExpenseGroup
  factory ExpenseGroup.fromMap(Map<String, dynamic> map) {
    return ExpenseGroup(
      id: map['id'] as int?,
      name: map['name'] as String,
      budget: map['budget'] != null
          ? (map['budget'] as num).toDouble()
          : null,
      createdAt: map['created_at'] as String,
    );
  }

  // Handy helpers
  bool get hasBudget => budget != null && budget! > 0;

  ExpenseGroup copyWith({
    int? id,
    String? name,
    double? budget,
    bool clearBudget = false,
    String? createdAt,
  }) {
    return ExpenseGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      budget: clearBudget ? null : (budget ?? this.budget),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}