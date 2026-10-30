import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/credit_card.dart';

class CreditCardWidget extends StatelessWidget {
  final CreditCard card;
  final VoidCallback? onPayPressed;
  final VoidCallback? onTap;

  const CreditCardWidget({
    Key? key,
    required this.card,
    this.onPayPressed,
    this.onTap,
  }) : super(key: key);

  Color _getUtilizationColor(double rate) {
    if (rate > 0.75) return Colors.redAccent;
    if (rate > 0.40) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final cardColor = Color(card.cardColorValue);
    final days = card.daysUntilDue;

    String dueBadgeText;
    Color dueBadgeBg;
    if (card.dueAmount <= 0) {
      dueBadgeText = '✓ All Paid';
      dueBadgeBg = Colors.green.shade800;
    } else if (card.isOverdue) {
      dueBadgeText = '⚠️ Overdue by ${days.abs()}d';
      dueBadgeBg = Colors.red.shade900;
    } else if (days == 0) {
      dueBadgeText = '⏰ Due Today';
      dueBadgeBg = Colors.deepOrange.shade800;
    } else {
      dueBadgeText = '⏳ Due in ${days}d';
      dueBadgeBg = Colors.amber.shade900;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              cardColor,
              cardColor.withOpacity(0.82),
              const Color(0xFF0F172A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Bank & Due status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.bankName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      card.cardName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: dueBadgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dueBadgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Card chip and masked number
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade300,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.amber.shade700, width: 1),
                  ),
                  child: Center(
                    child: Icon(Icons.credit_card, size: 20, color: Colors.amber.shade900),
                  ),
                ),
                Text(
                  '•••• •••• •••• ${card.lastFourDigits}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Available Limit Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AVAILABLE LIMIT',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      currency.format(card.availableLimit),
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'TOTAL LIMIT',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      currency.format(card.totalLimit),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Progress bar for credit utilization
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: card.utilizationRate,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getUtilizationColor(card.utilizationRate),
                ),
                minHeight: 6,
              ),
            ),

            const SizedBox(height: 14),

            // Bottom Row: Due Amount, Due Date & Pay Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DUE AMOUNT',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currency.format(card.dueAmount),
                      style: TextStyle(
                        color: card.dueAmount > 0 ? Colors.redAccent.shade100 : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Due: ${DateFormat('dd MMM yyyy').format(card.dueDate)}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                if (card.dueAmount > 0 && onPayPressed != null)
                  ElevatedButton.icon(
                    onPressed: onPayPressed,
                    icon: const Icon(Icons.payment, size: 16),
                    label: const Text('Pay Bill'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
