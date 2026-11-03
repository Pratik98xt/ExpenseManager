import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_manager_app/models/category/category_model.dart';
import 'package:expense_manager_app/models/transactions/transactions_model.dart';
import 'package:expense_manager_app/models/trash/trash_model.dart';
import 'package:expense_manager_app/controllers/graphs/graphs_controller.dart';
import 'package:expense_manager_app/services/auth_service.dart';

void main() {
  group('1. Auth Form Validation Tests', () {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    test('Valid email addresses match regex', () {
      expect(emailRegex.hasMatch('test@example.com'), isTrue);
      expect(emailRegex.hasMatch('alice.smith@domain.co'), isTrue);
    });

    test('Invalid email addresses fail regex', () {
      expect(emailRegex.hasMatch('invalid-email'), isFalse);
      expect(emailRegex.hasMatch('alice@'), isFalse);
      expect(emailRegex.hasMatch('@domain.com'), isFalse);
    });

    test('Friendly error messages for Firebase auth exception codes', () {
      expect(AuthService.getFriendlyErrorMessage('user-not-found'),
          contains('No user found'));
      expect(AuthService.getFriendlyErrorMessage('wrong-password'),
          contains('Incorrect password'));
      expect(AuthService.getFriendlyErrorMessage('email-already-in-use'),
          contains('already registered'));
      expect(AuthService.getFriendlyErrorMessage('weak-password'),
          contains('at least 6 characters'));
      expect(AuthService.getFriendlyErrorMessage('network-request-failed'),
          contains('connection error'));
    });
  });

  group('2. Category Model & Icons Tests', () {
    test('Category icon resolves without dynamic IconData tree-shaking failures', () {
      final cat = CategoryData(
        categoryId: 'cat_1',
        categoryName: 'Food',
        categoryColor: 0xFFE24F4F,
        iconCodePoint: 0xe25a, // fastfood
        createdAt: DateTime.now(),
      );
      expect(cat.icon, equals(Icons.fastfood));
      expect(cat.color, equals(const Color(0xFFE24F4F)));
    });

    test('Category unknown icon safely falls back to Icons.category', () {
      final icon = CategoryData.getIconByCodePoint(999999);
      expect(icon, equals(Icons.category));
    });
  });

  group('3. Transactions & Monthly Total Logic Tests', () {
    test('Transaction formatting and soft delete', () {
      final tx = TransactionData(
        expId: 'tx_1',
        amount: 350.75,
        categoryId: 'cat_food',
        description: 'Lunch with friend',
        date: DateTime(2026, 11, 2, 14, 30),
        isDeleted: false,
        createdAt: DateTime.now(),
      );

      expect(tx.formattedAmount, '350.75');
      expect(tx.formattedDate, '2026-11-02');
      expect(tx.formattedTime, '02:30 PM');
    });

    test('TrashData correctly wraps soft-deleted transaction', () {
      final tx = TransactionData(
        expId: 'tx_2',
        amount: 1200.0,
        categoryId: 'cat_bills',
        description: 'Electric bill',
        date: DateTime(2026, 11, 1),
        isDeleted: true,
        deletedAt: DateTime(2026, 11, 2),
        createdAt: DateTime.now(),
      );

      final trash = TrashData.fromTransaction(tx);
      expect(trash.trashId, 'tx_2');
      expect(trash.trashAmount, '1200.00');
      expect(trash.trashDescription, 'Electric bill');
      expect(trash.deletedAt, isNotNull);
    });
  });

  group('4. Graphs Calculation & Month Filtering Tests', () {
    final categories = [
      CategoryData(
        categoryId: 'cat_food',
        categoryName: 'Food & Dining',
        categoryColor: 0xFFE24F4F,
        iconCodePoint: Icons.fastfood.codePoint,
        createdAt: DateTime.now(),
      ),
      CategoryData(
        categoryId: 'cat_shopping',
        categoryName: 'Shopping',
        categoryColor: 0xFF9378FF,
        iconCodePoint: Icons.shopping_bag.codePoint,
        createdAt: DateTime.now(),
      ),
    ];

    final transactions = [
      TransactionData(
        expId: '1',
        amount: 500.0,
        categoryId: 'cat_food',
        description: 'Groceries',
        date: DateTime(2026, 11, 2),
        createdAt: DateTime.now(),
      ),
      TransactionData(
        expId: '2',
        amount: 300.0,
        categoryId: 'cat_food',
        description: 'Dinner',
        date: DateTime(2026, 11, 3),
        createdAt: DateTime.now(),
      ),
      TransactionData(
        expId: '3',
        amount: 700.0,
        categoryId: 'cat_shopping',
        description: 'Shoes',
        date: DateTime(2026, 11, 4),
        createdAt: DateTime.now(),
      ),
      TransactionData(
        expId: '4',
        amount: 1000.0,
        categoryId: 'cat_food',
        description: 'Old expense',
        date: DateTime(2026, 10, 15), // October (different month)
        createdAt: DateTime.now(),
      ),
    ];

    test('GraphsController computes monthly breakdown accurately', () {
      final graphsController = GraphsController();
      graphsController.selectedFilterMonth = DateTime(2026, 11, 1);

      final graphData = graphsController.getGraphData(transactions, categories);

      expect(graphData.length, 2);
      // Food total = 500 + 300 = 800
      // Shopping total = 700
      expect(graphData[0].catName, 'Food & Dining');
      expect(graphData[0].amount, 800.0);
      expect(graphData[1].catName, 'Shopping');
      expect(graphData[1].amount, 700.0);

      final total = graphData.fold(0.0, (sum, g) => sum + g.amount);
      expect(total, 1500.0);
    });

    test('Empty month returns empty graph data list', () {
      final graphsController = GraphsController();
      graphsController.selectedFilterMonth = DateTime(2025, 1, 1);

      final graphData = graphsController.getGraphData(transactions, categories);
      expect(graphData.isEmpty, isTrue);
    });

    test('Uncategorized transaction safely handled in graph without throwing', () {
      final graphsController = GraphsController();
      graphsController.selectedFilterMonth = DateTime(2026, 11, 1);

      final unknownTx = [
        TransactionData(
          expId: '99',
          amount: 250.0,
          categoryId: 'non_existent_category',
          description: 'Misc',
          date: DateTime(2026, 11, 2),
          createdAt: DateTime.now(),
        ),
      ];

      final graphData = graphsController.getGraphData(unknownTx, categories);
      expect(graphData.length, 1);
      expect(graphData[0].catName, 'Uncategorized');
      expect(graphData[0].amount, 250.0);
    });
  });
}

