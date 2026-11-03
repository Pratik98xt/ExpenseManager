import 'dart:async';
import 'package:expense_manager_app/models/category/category_model.dart';
import 'package:expense_manager_app/models/transactions/transactions_model.dart';
import 'package:expense_manager_app/services/firestore_service.dart';
import 'package:flutter/material.dart';

class TransactionController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<List<TransactionData>>? _transactionsSubscription;

  List<TransactionData> _allTransactions = [];
  List<TransactionData> listOfTransactions = [];
  CategoryData? selectedCategoryData;

  DateTime selectedFilterMonth = DateTime.now();
  double monthlyTotal = 0.0;

  bool isTransactionLoading = false;
  String? errorMessage;
  String? _currentUid;

  /// Listen to real-time transactions from Firestore
  void listenToTransactions(String uid) {
    if (_currentUid == uid && _transactionsSubscription != null) {
      return;
    }
    _currentUid = uid;
    _transactionsSubscription?.cancel();

    _transactionsSubscription = _firestoreService.activeTransactionsStream(uid).listen(
      (transactions) {
        _allTransactions = transactions;
        _applyFilter();
        isTransactionLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        errorMessage = error.toString();
        isTransactionLoading = false;
        notifyListeners();
      },
    );
  }

  /// Change month/year filter
  void changeFilterMonth(DateTime newDate) {
    selectedFilterMonth = newDate;
    _applyFilter();
    notifyListeners();
  }

  /// Helper to filter by month/year and compute total
  void _applyFilter() {
    listOfTransactions = _allTransactions.where((tx) {
      return tx.date.year == selectedFilterMonth.year &&
          tx.date.month == selectedFilterMonth.month;
    }).toList();

    monthlyTotal = listOfTransactions.fold(0.0, (sum, tx) => sum + tx.amount);
  }

  /// Reset state on logout
  void reset() {
    _transactionsSubscription?.cancel();
    _transactionsSubscription = null;
    _currentUid = null;
    _allTransactions.clear();
    listOfTransactions.clear();
    selectedCategoryData = null;
    monthlyTotal = 0.0;
    selectedFilterMonth = DateTime.now();
    isTransactionLoading = false;
    errorMessage = null;
    notifyListeners();
  }

  /// Add a new transaction
  Future<bool> addTransaction({
    required String uid,
    required double amount,
    required String categoryId,
    required String note,
    required DateTime date,
  }) async {
    isTransactionLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.addTransaction(
        uid: uid,
        amount: amount,
        categoryId: categoryId,
        note: note,
        date: date,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isTransactionLoading = false;
      notifyListeners();
    }
  }

  /// Edit existing transaction
  Future<bool> editTransaction({
    required String uid,
    required String transactionId,
    required double amount,
    required String categoryId,
    required String note,
    required DateTime date,
  }) async {
    isTransactionLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.updateTransaction(
        uid: uid,
        transactionId: transactionId,
        amount: amount,
        categoryId: categoryId,
        note: note,
        date: date,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isTransactionLoading = false;
      notifyListeners();
    }
  }

  /// Soft delete transaction to trash
  Future<bool> deleteTransaction({
    required String uid,
    required String transactionId,
  }) async {
    try {
      // Optimistically remove from local list for smooth UI dismissal
      _allTransactions.removeWhere((tx) => tx.expId == transactionId);
      _applyFilter();
      notifyListeners();

      await _firestoreService.softDeleteTransaction(
        uid: uid,
        transactionId: transactionId,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void setSelectedCategory(CategoryData category) {
    selectedCategoryData = category;
    notifyListeners();
  }

  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    super.dispose();
  }
}
