import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/credit_card.dart';

class AddCardScreen extends StatefulWidget {
  final CreditCard? cardToEdit;

  const AddCardScreen({Key? key, this.cardToEdit}) : super(key: key);

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _digitsController = TextEditingController();
  final _limitController = TextEditingController();
  final _spentController = TextEditingController();
  final _dueController = TextEditingController();

  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 15));
  int _selectedColorValue = 0xFF1E293B; // Default slate navy

  final List<int> _cardColors = [
    0xFF1E293B, // Slate Navy
    0xFF064E3B, // Emerald Pine
    0xFF4C1D95, // Deep Violet
    0xFF831843, // Ruby Crimson
    0xFF7C2D12, // Burnt Amber
    0xFF111827, // Jet Onyx
  ];

  @override
  void initState() {
    super.initState();
    if (widget.cardToEdit != null) {
      final c = widget.cardToEdit!;
      _bankController.text = c.bankName;
      _cardNameController.text = c.cardName;
      _digitsController.text = c.lastFourDigits;
      _limitController.text = c.totalLimit.toString();
      _spentController.text = c.spentAmount.toString();
      _dueController.text = c.dueAmount.toString();
      _selectedDueDate = c.dueDate;
      _selectedColorValue = c.cardColorValue;
    }
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    final limit = double.tryParse(_limitController.text.trim()) ?? 0.0;
    final spent = double.tryParse(_spentController.text.trim()) ?? 0.0;
    final due = double.tryParse(_dueController.text.trim()) ?? 0.0;

    final card = CreditCard(
      id: widget.cardToEdit?.id,
      bankName: _bankController.text.trim(),
      cardName: _cardNameController.text.trim(),
      lastFourDigits: _digitsController.text.trim(),
      totalLimit: limit,
      spentAmount: spent,
      dueAmount: due,
      dueDate: _selectedDueDate,
      lastPaymentDate: widget.cardToEdit?.lastPaymentDate,
      lastPaymentAmount: widget.cardToEdit?.lastPaymentAmount,
      cardColorValue: _selectedColorValue,
    );

    if (widget.cardToEdit == null) {
      await DBHelper.instance.insertCard(card);
    } else {
      await DBHelper.instance.updateCard(card);
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.cardToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Credit Card' : 'Add Credit Card'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bank Name
              TextFormField(
                controller: _bankController,
                decoration: const InputDecoration(
                  labelText: 'Bank / Issuer (e.g. Chase, City Bank, Amex)',
                  prefixIcon: Icon(Icons.account_balance),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter bank name' : null,
              ),

              const SizedBox(height: 16),

              // Card Name / Variant
              TextFormField(
                controller: _cardNameController,
                decoration: const InputDecoration(
                  labelText: 'Card Name (e.g. Sapphire Preferred, Platinum)',
                  prefixIcon: Icon(Icons.credit_card),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter card name' : null,
              ),

              const SizedBox(height: 16),

              // Last 4 digits
              TextFormField(
                controller: _digitsController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Last 4 Digits (e.g. 4321)',
                  prefixIcon: Icon(Icons.password),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (val) {
                  if (val == null || val.trim().length != 4) return 'Enter 4 digits';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Total Credit Limit
              TextFormField(
                controller: _limitController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Total Credit Limit',
                  prefixText: '\$ ',
                  prefixIcon: Icon(Icons.speed),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter total limit';
                  if (double.tryParse(val.trim()) == null) return 'Invalid number';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Current Spent / Unpaid Balance
              TextFormField(
                controller: _spentController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Current Spent / Outstanding Balance',
                  prefixText: '\$ ',
                  prefixIcon: Icon(Icons.shopping_cart_outlined),
                  border: OutlineInputBorder(),
                  helperText: 'Used to calculate your real-time Available Limit',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter spent amount (or 0)';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Statement Due Amount
              TextFormField(
                controller: _dueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Current Due Payment Amount',
                  prefixText: '\$ ',
                  prefixIcon: Icon(Icons.receipt_outlined),
                  border: OutlineInputBorder(),
                  helperText: 'The bill amount you need to pay before the due date',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter due amount (or 0)';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Due Date Picker
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                leading: const Icon(Icons.event),
                title: const Text('Payment Due Date'),
                subtitle: Text(DateFormat('MMMM dd, yyyy').format(_selectedDueDate)),
                trailing: const Icon(Icons.calendar_month, color: Colors.blue),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDueDate,
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setState(() => _selectedDueDate = picked);
                  }
                },
              ),

              const SizedBox(height: 20),

              // Card Color Selection
              const Text(
                'Select Card Color Style',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _cardColors.map((colorVal) {
                  final isSelected = _selectedColorValue == colorVal;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorValue = colorVal),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(colorVal),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 22)
                          : null,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saveCard,
                  icon: const Icon(Icons.save),
                  label: Text(
                    isEditing ? 'Update Card' : 'Add Credit Card',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
