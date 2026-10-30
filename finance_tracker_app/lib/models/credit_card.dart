class CreditCard {
  final int? id;
  final String cardName;
  final String bankName;
  final String lastFourDigits;
  final double totalLimit;
  final double spentAmount;
  final double dueAmount;
  final DateTime dueDate;
  final DateTime? lastPaymentDate;
  final double? lastPaymentAmount;
  final int cardColorValue;

  CreditCard({
    this.id,
    required this.cardName,
    required this.bankName,
    required this.lastFourDigits,
    required this.totalLimit,
    required this.spentAmount,
    required this.dueAmount,
    required this.dueDate,
    this.lastPaymentDate,
    this.lastPaymentAmount,
    this.cardColorValue = 0xFF1E293B,
  });

  double get availableLimit {
    final remaining = totalLimit - spentAmount;
    return remaining < 0 ? 0 : remaining;
  }

  double get utilizationRate {
    if (totalLimit <= 0) return 0;
    return (spentAmount / totalLimit).clamp(0.0, 1.0);
  }

  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return target.difference(today).inDays;
  }

  bool get isOverdue => daysUntilDue < 0 && dueAmount > 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cardName': cardName,
      'bankName': bankName,
      'lastFourDigits': lastFourDigits,
      'totalLimit': totalLimit,
      'spentAmount': spentAmount,
      'dueAmount': dueAmount,
      'dueDate': dueDate.toIso8601String(),
      'lastPaymentDate': lastPaymentDate?.toIso8601String(),
      'lastPaymentAmount': lastPaymentAmount,
      'cardColorValue': cardColorValue,
    };
  }

  factory CreditCard.fromMap(Map<String, dynamic> map) {
    return CreditCard(
      id: map['id'] as int?,
      cardName: map['cardName'] as String,
      bankName: map['bankName'] as String,
      lastFourDigits: map['lastFourDigits'] as String,
      totalLimit: (map['totalLimit'] as num).toDouble(),
      spentAmount: (map['spentAmount'] as num).toDouble(),
      dueAmount: (map['dueAmount'] as num).toDouble(),
      dueDate: DateTime.parse(map['dueDate'] as String),
      lastPaymentDate: map['lastPaymentDate'] != null
          ? DateTime.parse(map['lastPaymentDate'] as String)
          : null,
      lastPaymentAmount: map['lastPaymentAmount'] != null
          ? (map['lastPaymentAmount'] as num).toDouble()
          : null,
      cardColorValue: map['cardColorValue'] as int? ?? 0xFF1E293B,
    );
  }

  CreditCard copyWith({
    int? id,
    String? cardName,
    String? bankName,
    String? lastFourDigits,
    double? totalLimit,
    double? spentAmount,
    double? dueAmount,
    DateTime? dueDate,
    DateTime? lastPaymentDate,
    double? lastPaymentAmount,
    int? cardColorValue,
  }) {
    return CreditCard(
      id: id ?? this.id,
      cardName: cardName ?? this.cardName,
      bankName: bankName ?? this.bankName,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      totalLimit: totalLimit ?? this.totalLimit,
      spentAmount: spentAmount ?? this.spentAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      dueDate: dueDate ?? this.dueDate,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      lastPaymentAmount: lastPaymentAmount ?? this.lastPaymentAmount,
      cardColorValue: cardColorValue ?? this.cardColorValue,
    );
  }
}
