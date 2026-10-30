import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/transaction_item.dart';
import '../models/credit_card.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('spendwise.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE credit_cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cardName TEXT NOT NULL,
        bankName TEXT NOT NULL,
        lastFourDigits TEXT NOT NULL,
        totalLimit REAL NOT NULL,
        spentAmount REAL NOT NULL,
        dueAmount REAL NOT NULL,
        dueDate TEXT NOT NULL,
        lastPaymentDate TEXT,
        lastPaymentAmount REAL,
        cardColorValue INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        cardId INTEGER,
        note TEXT,
        FOREIGN KEY (cardId) REFERENCES credit_cards (id) ON DELETE SET NULL
      )
    ''');
  }

  // --- Credit Card Operations ---

  Future<int> insertCard(CreditCard card) async {
    final db = await instance.database;
    return await db.insert('credit_cards', card.toMap());
  }

  Future<List<CreditCard>> getAllCards() async {
    final db = await instance.database;
    final result = await db.query('credit_cards', orderBy: 'id ASC');
    return result.map((json) => CreditCard.fromMap(json)).toList();
  }

  Future<CreditCard?> getCardById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'credit_cards',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return CreditCard.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCard(CreditCard card) async {
    final db = await instance.database;
    return await db.update(
      'credit_cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<int> deleteCard(int id) async {
    final db = await instance.database;
    return await db.delete(
      'credit_cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Transaction Operations ---

  Future<int> insertTransaction(TransactionItem item) async {
    final db = await instance.database;
    final id = await db.insert('transactions', item.toMap());

    // Update credit card stats if linked
    if (item.cardId != null) {
      final card = await getCardById(item.cardId!);
      if (card != null) {
        if (item.type == 'card_expense') {
          final updatedSpent = card.spentAmount + item.amount;
          final updatedDue = card.dueAmount + item.amount;
          await updateCard(card.copyWith(
            spentAmount: updatedSpent,
            dueAmount: updatedDue,
          ));
        } else if (item.type == 'card_payment') {
          final updatedSpent = (card.spentAmount - item.amount).clamp(0.0, double.infinity);
          final updatedDue = (card.dueAmount - item.amount).clamp(0.0, double.infinity);
          await updateCard(card.copyWith(
            spentAmount: updatedSpent,
            dueAmount: updatedDue,
            lastPaymentDate: item.date,
            lastPaymentAmount: item.amount,
          ));
        }
      }
    }

    return id;
  }

  Future<List<TransactionItem>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    return result.map((json) => TransactionItem.fromMap(json)).toList();
  }

  Future<List<TransactionItem>> getRecentTransactions({int limit = 10}) async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'date DESC', limit: limit);
    return result.map((json) => TransactionItem.fromMap(json)).toList();
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // --- Summary Aggregations ---

  Future<double> getTotalIncome() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM transactions WHERE type = 'income'",
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalExpense() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM transactions WHERE type IN ('expense', 'card_expense')",
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> getSummaryStats() async {
    final totalIncome = await getTotalIncome();
    final totalExpense = await getTotalExpense();
    final cards = await getAllCards();

    double totalLimit = 0;
    double totalSpent = 0;
    double totalDue = 0;

    for (final card in cards) {
      totalLimit += card.totalLimit;
      totalSpent += card.spentAmount;
      totalDue += card.dueAmount;
    }

    final totalAvailable = (totalLimit - totalSpent).clamp(0.0, double.infinity);

    return {
      'income': totalIncome,
      'expense': totalExpense,
      'netBalance': totalIncome - totalExpense,
      'cardTotalLimit': totalLimit,
      'cardTotalSpent': totalSpent,
      'cardTotalDue': totalDue,
      'cardTotalAvailable': totalAvailable,
    };
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
