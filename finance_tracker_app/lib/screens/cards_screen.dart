import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/credit_card.dart';
import '../models/transaction_item.dart';
import '../services/notification_service.dart';
import '../widgets/credit_card_widget.dart';
import 'add_card_screen.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({Key? key}) : super(key: key);

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<CreditCard> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    final cards = await DBHelper.instance.getAllCards();
    setState(() {
      _cards = cards;
      _isLoading = false;
    });
    // Check reminders automatically
    await NotificationService().checkAndAlertUpcomingDues(cards);
  }

  Future<void> _showPayDialog(CreditCard card) async {
    final amountController = TextEditingController(text: card.dueAmount.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pay Bill: ${card.cardName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Due: \$${card.dueAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Payment Amount',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final payAmount = double.tryParse(amountController.text.trim()) ?? 0.0;
              if (payAmount <= 0) return;

              // Insert repayment transaction
              await DBHelper.instance.insertTransaction(
                TransactionItem(
                  title: 'Bill Payment - ${card.bankName} ${card.cardName}',
                  amount: payAmount,
                  type: 'card_payment',
                  category: 'Card Payment',
                  date: DateTime.now(),
                  cardId: card.id,
                  note: 'Cleared due on ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                ),
              );

              if (mounted) {
                Navigator.pop(ctx);
                _loadCards();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.green.shade800,
                    content: Text('Paid \$${payAmount.toStringAsFixed(2)} successfully!'),
                  ),
                );
              }
            },
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }

  void _showCardActions(CreditCard card) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.green),
              title: const Text('Pay Credit Card Bill'),
              subtitle: Text('Due: \$${card.dueAmount.toStringAsFixed(2)}'),
              onTap: () {
                Navigator.pop(ctx);
                _showPayDialog(card);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active, color: Colors.amber),
              title: const Text('Trigger Test Due Alert'),
              subtitle: const Text('Send instant notification for this card'),
              onTap: () async {
                Navigator.pop(ctx);
                await NotificationService().showDuePaymentNotification(card: card);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sent payment reminder notification! Check your status bar.')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Card Details'),
              onTap: () async {
                Navigator.pop(ctx);
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddCardScreen(cardToEdit: card),
                  ),
                );
                if (updated == true) _loadCards();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Card'),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    title: const Text('Delete Card?'),
                    content: Text('Are you sure you want to delete ${card.cardName}?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && card.id != null) {
                  await DBHelper.instance.deleteCard(card.id!);
                  _loadCards();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Cards & Limits'),
        actions: [
          IconButton(
            tooltip: 'Send Test Alert Notification',
            icon: const Icon(Icons.notification_add),
            onPressed: () async {
              if (_cards.isEmpty) {
                await NotificationService().showInstantNotification(
                  title: '💳 SpendWise Alert',
                  body: 'Welcome! Add a credit card to track your available limit and due dates.',
                );
              } else {
                await NotificationService().checkAndAlertUpcomingDues(_cards);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification test triggered!')),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.credit_card_off_rounded, size: 72, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'No Credit Cards Added Yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add your credit cards to track credit limits, spent balance, and receive due date payment reminders.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final res = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(builder: (_) => const AddCardScreen()),
                            );
                            if (res == true) _loadCards();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Your First Card'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return CreditCardWidget(
                      card: card,
                      onTap: () => _showCardActions(card),
                      onPayPressed: () => _showPayDialog(card),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddCardScreen()),
          );
          if (res == true) _loadCards();
        },
        icon: const Icon(Icons.add_card),
        label: const Text('Add Card'),
      ),
    );
  }
}
