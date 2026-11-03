import 'package:expense_manager_app/models/category/category_model.dart';
import 'package:expense_manager_app/models/graphs/graphs_model.dart';
import 'package:expense_manager_app/models/transactions/transactions_model.dart';
import 'package:flutter/material.dart';

class GraphsController extends ChangeNotifier {
  DateTime selectedFilterMonth = DateTime.now();

  /// Change filter month
  void changeFilterMonth(DateTime newMonth) {
    selectedFilterMonth = newMonth;
    notifyListeners();
  }

  /// Reset on logout
  void reset() {
    selectedFilterMonth = DateTime.now();
    notifyListeners();
  }

  /// Compute category-wise breakdown directly from transaction data (pure function, no side effects)
  List<GraphsData> getGraphData(
    List<TransactionData> transactions,
    List<CategoryData> categories,
  ) {
    // 1. Filter transactions for the selected month and year
    final monthlyTransactions = transactions.where((tx) {
      return tx.date.year == selectedFilterMonth.year &&
          tx.date.month == selectedFilterMonth.month;
    }).toList();

    // 2. Aggregate spending per categoryId
    final Map<String, double> categorySums = {};
    for (final tx in monthlyTransactions) {
      categorySums[tx.categoryId] = (categorySums[tx.categoryId] ?? 0.0) + tx.amount;
    }

    // 3. Map into GraphsData with matching category styling
    final List<GraphsData> graphList = [];
    categorySums.forEach((catId, sumAmount) {
      final cat = categories.firstWhere(
        (c) => c.categoryId == catId,
        orElse: () => CategoryData(
          categoryId: catId,
          categoryName: 'Uncategorized',
          categoryColor: Colors.grey.toARGB32(),
          iconCodePoint: Icons.category.codePoint,
          createdAt: DateTime.now(),
        ),
      );

      graphList.add(
        GraphsData(
          catName: cat.categoryName,
          amount: sumAmount,
          catColor: cat.categoryColor,
          iconCodePoint: cat.iconCodePoint,
        ),
      );
    });

    // Sort by amount descending
    graphList.sort((a, b) => b.amount.compareTo(a.amount));
    return graphList;
  }
}
