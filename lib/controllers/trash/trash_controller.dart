import 'dart:async';
import 'package:expense_manager_app/models/transactions/transactions_model.dart';
import 'package:expense_manager_app/models/trash/trash_model.dart';
import 'package:expense_manager_app/services/firestore_service.dart';
import 'package:flutter/material.dart';

class TrashController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<List<TransactionData>>? _trashSubscription;

  List<TrashData> listOfTrashData = [];
  bool isTrashLoading = false;
  String? errorMessage;
  String? _currentUid;

  /// Listen to real-time trashed items from Firestore
  void listenToTrash(String uid) {
    if (_currentUid == uid && _trashSubscription != null) {
      return;
    }
    _currentUid = uid;
    _trashSubscription?.cancel();

    _trashSubscription = _firestoreService.trashTransactionsStream(uid).listen(
      (transactions) {
        listOfTrashData = transactions.map((tx) => TrashData.fromTransaction(tx)).toList();
        isTrashLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        errorMessage = error.toString();
        isTrashLoading = false;
        notifyListeners();
      },
    );
  }

  /// Reset state on logout
  void reset() {
    _trashSubscription?.cancel();
    _trashSubscription = null;
    _currentUid = null;
    listOfTrashData.clear();
    isTrashLoading = false;
    errorMessage = null;
    notifyListeners();
  }

  /// Restore item from Trash back to active transactions
  Future<bool> restoreTrash({
    required String uid,
    required String trashId,
  }) async {
    try {
      await _firestoreService.restoreTransaction(
        uid: uid,
        transactionId: trashId,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Permanently delete item forever
  Future<bool> permanentlyDeleteTrash({
    required String uid,
    required String trashId,
  }) async {
    try {
      await _firestoreService.permanentlyDeleteTransaction(
        uid: uid,
        transactionId: trashId,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _trashSubscription?.cancel();
    super.dispose();
  }
}
