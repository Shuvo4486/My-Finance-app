import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryCard extends StatelessWidget {
  final Map<String, double> stats;

  const SummaryCard({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final netBalance = stats['netBalance'] ?? 0.0;
    final income = stats['income'] ?? 0.0;
    final expense = stats['expense'] ?? 0.0;
    final cardAvailable = stats['cardTotalAvailable'] ?? 0.0;
    final cardDue = stats['cardTotalDue'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL NET BALANCE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currency.format(netBalance),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: netBalance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  context,
                  icon: Icons.arrow_downward_rounded,
                  iconColor: Colors.green,
                  label: 'Income',
                  value: currency.format(income),
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  context,
                  icon: Icons.arrow_upward_rounded,
                  iconColor: Colors.red,
                  label: 'Expenses',
                  value: currency.format(expense),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  context,
                  icon: Icons.credit_card_outlined,
                  iconColor: Colors.blueAccent,
                  label: 'Cards Avail. Limit',
                  value: currency.format(cardAvailable),
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  context,
                  icon: Icons.warning_amber_rounded,
                  iconColor: cardDue > 0 ? Colors.redAccent : Colors.grey,
                  label: 'Total Card Due',
                  value: currency.format(cardDue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
