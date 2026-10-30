import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/credit_card.dart';
import '../models/transaction_item.dart';
import '../services/notification_service.dart';
import '../widgets/credit_card_widget.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import 'add_card_screen.dart';
import 'cards_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  Map<String, double> _stats = {};
  List<CreditCard> _cards = [];
  List<TransactionItem> _transactions = [];
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final stats = await DBHelper.instance.getSummaryStats();
    final cards = await DBHelper.instance.getAllCards();
    final txs = await DBHelper.instance.getAllTransactions();

    setState(() {
      _stats = stats;
      _cards = cards;
      _transactions = txs;
      _isLoading = false;
    });

    // Run proactive due date check in background
    NotificationService().checkAndAlertUpcomingDues(cards);
  }

  List<TransactionItem> get _filteredTransactions {
    if (_selectedFilter == 'all') return _transactions;
    return _transactions.where((t) => t.type == _selectedFilter).toList();
  }

  List<CreditCard> get _urgentCards {
    return _cards.where((c) => c.dueAmount > 0 && (c.daysUntilDue <= 3 || c.isOverdue)).toList();
  }

  void _showAddActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Quick Action',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFDCFCE7),
                  child: Icon(Icons.arrow_downward, color: Colors.green),
                ),
                title: const Text('Add Income'),
                subtitle: const Text('Salary, Freelance, Investment, etc.'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final res = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen(initialType: 'income'),
                    ),
                  );
                  if (res == true) _refreshData();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFEE2E2),
                  child: Icon(Icons.arrow_upward, color: Colors.red),
                ),
                title: const Text('Add Cash / Bank Expense'),
                subtitle: const Text('Everyday spending not on credit card'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final res = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen(initialType: 'expense'),
                    ),
                  );
                  if (res == true) _refreshData();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFEDD5),
                  child: Icon(Icons.credit_card, color: Colors.deepOrange),
                ),
                title: const Text('Log Credit Card Expense'),
                subtitle: const Text('Deducts from Available Limit & increases Due'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final res = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen(initialType: 'card_expense'),
                    ),
                  );
                  if (res == true) _refreshData();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFCCFBF1),
                  child: Icon(Icons.credit_score, color: Colors.teal),
                ),
                title: const Text('Pay Credit Card Due'),
                subtitle: const Text('Settles due and restores available limit'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final res = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen(initialType: 'card_payment'),
                    ),
                  );
                  if (res == true) _refreshData();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEDE9FE),
                  child: Icon(Icons.add_card, color: Colors.deepPurple),
                ),
                title: const Text('Add New Credit Card'),
                subtitle: const Text('Setup a new credit limit and billing cycle'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final res = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const AddCardScreen()),
                  );
                  if (res == true) _refreshData();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urgent = _urgentCards;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SpendWise & Cards',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 90),
                children: [
                  // Urgent Due Payment Banner
                  if (urgent.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Action Required: Due Payment Alert!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade900,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${urgent.first.cardName} has \$${urgent.first.dueAmount.toStringAsFixed(2)} due ${urgent.first.isOverdue ? 'OVERDUE' : 'on ' + DateFormat('MMM dd').format(urgent.first.dueDate)}.',
                                  style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final res = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddTransactionScreen(
                                    initialType: 'card_payment',
                                    preselectedCardId: urgent.first.id,
                                  ),
                                ),
                              );
                              if (res == true) _refreshData();
                            },
                            child: const Text('PAY NOW'),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Financial Net Balance & Summary Card
                  SummaryCard(stats: _stats),

                  // Credit Cards Section Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Credit Cards',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CardsScreen()),
                            );
                            _refreshData();
                          },
                          child: const Text('Manage Cards'),
                        ),
                      ],
                    ),
                  ),

                  // Cards horizontal slider or Empty Card state
                  if (_cards.isEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.credit_card_outlined, size: 40, color: Colors.grey.shade600),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Track your credit card limits & dues',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Add your credit card to monitor available limits and receive due alerts.',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final res = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(builder: (_) => const AddCardScreen()),
                              );
                              if (res == true) _refreshData();
                            },
                            child: const Text('Add Card'),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 255,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _cards.length,
                        itemBuilder: (ctx, i) {
                          return SizedBox(
                            width: MediaQuery.of(context).size.width * 0.9,
                            child: CreditCardWidget(
                              card: _cards[i],
                              onPayPressed: () async {
                                final res = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddTransactionScreen(
                                      initialType: 'card_payment',
                                      preselectedCardId: _cards[i].id,
                                    ),
                                  ),
                                );
                                if (res == true) _refreshData();
                              },
                            ),
                          );
                        },
                      ),
                    ),

                  // Recent Transactions Header & Filter Chips
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_filteredTransactions.length} records',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildFilterChip('All', 'all'),
                        _buildFilterChip('Expenses', 'expense'),
                        _buildFilterChip('Income', 'income'),
                        _buildFilterChip('Card Spend', 'card_expense'),
                        _buildFilterChip('Repayments', 'card_payment'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Transactions List
                  if (_filteredTransactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            const Text('No transactions recorded for this filter.'),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._filteredTransactions.map((tx) {
                      return TransactionTile(
                        transaction: tx,
                        onDelete: () async {
                          if (tx.id != null) {
                            await DBHelper.instance.deleteTransaction(tx.id!);
                            _refreshData();
                          }
                        },
                      );
                    }).toList(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddActionSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) setState(() => _selectedFilter = value);
        },
      ),
    );
  }
}
