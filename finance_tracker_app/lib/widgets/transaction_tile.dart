import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_item.dart';

class TransactionTile extends StatelessWidget {
  final TransactionItem transaction;
  final VoidCallback? onDelete;

  const TransactionTile({
    Key? key,
    required this.transaction,
    this.onDelete,
  }) : super(key: key);

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'salary':
      case 'freelance':
      case 'investment':
        return Icons.account_balance_wallet;
      case 'food':
      case 'dining':
      case 'groceries':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_bag;
      case 'bills':
      case 'utilities':
        return Icons.receipt_long;
      case 'transport':
      case 'fuel':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'health':
      case 'medical':
        return Icons.medical_services;
      case 'card payment':
        return Icons.credit_score;
      default:
        return Icons.monetization_on_outlined;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'income':
        return Colors.green;
      case 'expense':
        return Colors.red;
      case 'card_expense':
        return Colors.deepOrange;
      case 'card_payment':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'income':
        return 'Income';
      case 'expense':
        return 'Cash/Bank';
      case 'card_expense':
        return 'Credit Card';
      case 'card_payment':
        return 'Card Repayment';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final isIncome = transaction.type == 'income';
    final isRepayment = transaction.type == 'card_payment';
    final sign = isIncome ? '+' : (isRepayment ? '↻' : '-');
    final amountColor = isIncome
        ? Colors.green.shade700
        : (isRepayment ? Colors.teal.shade700 : Colors.red.shade700);

    return Dismissible(
      key: Key('tx_${transaction.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        if (onDelete != null) onDelete!();
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(transaction.type).withOpacity(0.12),
          child: Icon(
            _getCategoryIcon(transaction.category),
            color: _getTypeColor(transaction.type),
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getTypeColor(transaction.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getTypeLabel(transaction.type),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getTypeColor(transaction.type),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              DateFormat('MMM dd, yyyy').format(transaction.date),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Text(
          '$sign ${currency.format(transaction.amount)}',
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
