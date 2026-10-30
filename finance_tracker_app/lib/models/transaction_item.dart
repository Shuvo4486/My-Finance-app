class TransactionItem {
  final int? id;
  final String title;
  final double amount;
  final String type; // 'income', 'expense', 'card_expense', 'card_payment'
  final String category;
  final DateTime date;
  final int? cardId;
  final String? note;

  TransactionItem({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.cardId,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date.toIso8601String(),
      'cardId': cardId,
      'note': note,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      cardId: map['cardId'] as int?,
      note: map['note'] as String?,
    );
  }
}
