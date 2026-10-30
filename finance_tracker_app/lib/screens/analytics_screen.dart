import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/credit_card.dart';
import '../models/transaction_item.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  List<TransactionItem> _transactions = [];
  List<CreditCard> _cards = [];
  Map<String, double> _categoryTotals = {};
  double _totalExpenses = 0.0;

  final List<Color> _chartColors = [
    Colors.blue,
    Colors.redAccent,
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.pink,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final txs = await DBHelper.instance.getAllTransactions();
    final cards = await DBHelper.instance.getAllCards();

    final Map<String, double> catMap = {};
    double totalExp = 0.0;

    for (final tx in txs) {
      if (tx.type == 'expense' || tx.type == 'card_expense') {
        catMap[tx.category] = (catMap[tx.category] ?? 0) + tx.amount;
        totalExp += tx.amount;
      }
    }

    setState(() {
      _transactions = txs;
      _cards = cards;
      _categoryTotals = catMap;
      _totalExpenses = totalExp;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Analytics & Insights'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Expense Breakdown Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Spending by Category',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total Outflow: ${currency.format(_totalExpenses)}',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          if (_categoryTotals.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(30.0),
                                child: Text('No expenses recorded yet.'),
                              ),
                            )
                          else ...[
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                  sections: _buildPieSections(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ..._buildCategoryLegend(currency),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Credit Card Health & Utilization
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.credit_score, color: Colors.indigo),
                              SizedBox(width: 8),
                              Text(
                                'Credit Card Utilization',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Financial tip: Keeping your credit utilization under 30% protects your credit score.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          if (_cards.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text('No cards configured yet.'),
                              ),
                            )
                          else
                            ..._cards.map((card) {
                              final rate = (card.utilizationRate * 100).toStringAsFixed(1);
                              final color = card.utilizationRate > 0.7
                                  ? Colors.red
                                  : (card.utilizationRate > 0.3 ? Colors.orange : Colors.green);

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${card.bankName} - ${card.cardName}',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          '$rate% Used',
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: card.utilizationRate,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor: AlwaysStoppedAnimation<Color>(color),
                                        minHeight: 8,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Spent: ${currency.format(card.spentAmount)}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                        Text(
                                          'Avail: ${currency.format(card.availableLimit)}',
                                          style: const TextStyle(fontSize: 11, color: Colors.green),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    int idx = 0;
    return _categoryTotals.entries.map((entry) {
      final color = _chartColors[idx % _chartColors.length];
      idx++;
      final pct = _totalExpenses > 0 ? (entry.value / _totalExpenses) * 100 : 0.0;

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${pct.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _buildCategoryLegend(NumberFormat currency) {
    int idx = 0;
    return _categoryTotals.entries.map((entry) {
      final color = _chartColors[idx % _chartColors.length];
      idx++;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(width: 12, height: 12, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 13))),
            Text(
              currency.format(entry.value),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      );
    }).toList();
  }
}
