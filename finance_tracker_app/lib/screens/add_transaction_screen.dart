import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/transaction_item.dart';
import '../models/credit_card.dart';

class AddTransactionScreen extends StatefulWidget {
  final String? initialType;
  final int? preselectedCardId;

  const AddTransactionScreen({
    Key? key,
    this.initialType,
    this.preselectedCardId,
  }) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late String _selectedType;
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  int? _selectedCardId;
  List<CreditCard> _cards = [];
  bool _isLoading = true;

  final List<String> _incomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Bonus',
    'Gift',
    'Other Income',
  ];

  final List<String> _expenseCategories = [
    'Food',
    'Groceries',
    'Shopping',
    'Bills & Utilities',
    'Transport',
    'Entertainment',
    'Health',
    'Education',
    'Other Expense',
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? 'expense';
    _selectedCardId = widget.preselectedCardId;
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await DBHelper.instance.getAllCards();
    setState(() {
      _cards = cards;
      if (_selectedCardId == null && cards.isNotEmpty) {
        _selectedCardId = cards.first.id;
      }
      _isLoading = false;
    });
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than 0')),
      );
      return;
    }

    final isCardOperation = _selectedType == 'card_expense' || _selectedType == 'card_payment';
    if (isCardOperation && (_selectedCardId == null || _cards.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add or select a credit card first')),
      );
      return;
    }

    final item = TransactionItem(
      title: _titleController.text.trim(),
      amount: amount,
      type: _selectedType,
      category: _selectedType == 'card_payment' ? 'Card Payment' : _selectedCategory,
      date: _selectedDate,
      cardId: isCardOperation ? _selectedCardId : null,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    await DBHelper.instance.insertTransaction(item);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Segmented Type Selector
                    Center(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'expense',
                            label: Text('Expense'),
                            icon: Icon(Icons.arrow_upward, size: 16),
                          ),
                          ButtonSegment(
                            value: 'income',
                            label: Text('Income'),
                            icon: Icon(Icons.arrow_downward, size: 16),
                          ),
                          ButtonSegment(
                            value: 'card_expense',
                            label: Text('Card Spend'),
                            icon: Icon(Icons.credit_card, size: 16),
                          ),
                          ButtonSegment(
                            value: 'card_payment',
                            label: Text('Pay Bill'),
                            icon: Icon(Icons.credit_score, size: 16),
                          ),
                        ],
                        selected: {_selectedType},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _selectedType = newSelection.first;
                            if (_selectedType == 'income') {
                              _selectedCategory = _incomeCategories.first;
                            } else if (_selectedType == 'card_payment') {
                              _selectedCategory = 'Card Payment';
                            } else {
                              _selectedCategory = _expenseCategories.first;
                            }
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Amount input
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '\$ ',
                        prefixStyle: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter amount';
                        if (double.tryParse(val.trim()) == null) return 'Invalid number';
                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    // Title input
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: _selectedType == 'card_payment'
                            ? 'Payment Description (e.g., May Bill Settlement)'
                            : 'Title / Description (e.g., Grocery Shopping)',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Enter a description' : null,
                    ),

                    const SizedBox(height: 18),

                    // Card selector if card operation
                    if (_selectedType == 'card_expense' || _selectedType == 'card_payment') ...[
                      if (_cards.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No credit cards found. Please add a card first from the Cards tab.',
                                  style: TextStyle(color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<int>(
                          value: _selectedCardId,
                          decoration: InputDecoration(
                            labelText: _selectedType == 'card_payment'
                                ? 'Select Card to Repay'
                                : 'Select Credit Card Used',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.credit_card),
                          ),
                          items: _cards.map((card) {
                            return DropdownMenuItem<int>(
                              value: card.id,
                              child: Text(
                                '${card.bankName} - ${card.cardName} (•••• ${card.lastFourDigits})',
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedCardId = val;
                            });
                          },
                        ),
                      const SizedBox(height: 18),
                    ],

                    // Category Selector (hidden for card payment)
                    if (_selectedType != 'card_payment') ...[
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: (_selectedType == 'income'
                                ? _incomeCategories
                                : _expenseCategories)
                            .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Date Picker
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Transaction Date'),
                      subtitle: Text(DateFormat('MMMM dd, yyyy').format(_selectedDate)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                    ),

                    const SizedBox(height: 18),

                    // Optional Notes
                    TextFormField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _saveTransaction,
                        icon: const Icon(Icons.check),
                        label: const Text(
                          'Save Transaction',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
