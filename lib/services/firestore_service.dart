import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_manager_app/models/category/category_model.dart';
import 'package:expense_manager_app/models/transactions/transactions_model.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // -------------------------------------------------------------
  // USER PROFILE
  // -------------------------------------------------------------
  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    await _userDoc(uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _userDoc(uid).get();
    return doc.data();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userProfileStream(String uid) {
    return _userDoc(uid).snapshots();
  }

  // -------------------------------------------------------------
  // CATEGORIES (users/{uid}/categories)
  // -------------------------------------------------------------
  CollectionReference<Map<String, dynamic>> _categoriesRef(String uid) =>
      _userDoc(uid).collection('categories');

  Stream<List<CategoryData>> categoriesStream(String uid) {
    return _categoriesRef(uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CategoryData.fromFirestore(doc)).toList();
    });
  }

  Future<String> addCategory({
    required String uid,
    required String name,
    required int color,
    required int iconCodePoint,
  }) async {
    final docRef = await _categoriesRef(uid).add({
      'name': name.trim(),
      'color': color,
      'icon': iconCodePoint,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> deleteCategory({
    required String uid,
    required String categoryId,
  }) async {
    await _categoriesRef(uid).doc(categoryId).delete();
  }

  /// Automatically seed default starter categories for new users (runs only once per user)
  Future<void> seedDefaultCategoriesIfEmpty(String uid) async {
    final userDoc = await _userDoc(uid).get();
    final userData = userDoc.data() ?? {};
    if (userData['hasSeededCategories'] == true) {
      // User has already undergone seeding; do not re-seed even if all categories were deleted
      return;
    }

    final snapshot = await _categoriesRef(uid).limit(1).get();
    if (snapshot.docs.isEmpty) {
      final defaultCategories = [
        {'name': 'Food & Dining', 'color': 0xFFE24F4F, 'icon': Icons.fastfood.codePoint},
        {'name': 'Shopping', 'color': 0xFF9378FF, 'icon': Icons.shopping_bag.codePoint},
        {'name': 'Transportation', 'color': 0xFF4DC78C, 'icon': Icons.directions_car.codePoint},
        {'name': 'Entertainment', 'color': 0xFFF668D7, 'icon': Icons.movie.codePoint},
        {'name': 'Bills & Utilities', 'color': 0xFFFFAE00, 'icon': Icons.receipt_long.codePoint},
      ];

      final batch = _firestore.batch();
      for (final cat in defaultCategories) {
        final newDoc = _categoriesRef(uid).doc();
        batch.set(newDoc, {
          'name': cat['name'],
          'color': cat['color'],
          'icon': cat['icon'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      batch.set(_userDoc(uid), {'hasSeededCategories': true}, SetOptions(merge: true));
      await batch.commit();
    } else {
      await _userDoc(uid).set({'hasSeededCategories': true}, SetOptions(merge: true));
    }
  }

  // -------------------------------------------------------------
  // TRANSACTIONS (users/{uid}/transactions)
  // -------------------------------------------------------------
  CollectionReference<Map<String, dynamic>> _transactionsRef(String uid) =>
      _userDoc(uid).collection('transactions');

  /// Stream active (not deleted) transactions ordered by date descending
  Stream<List<TransactionData>> activeTransactionsStream(String uid) {
    return _transactionsRef(uid)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => TransactionData.fromFirestore(doc))
          .toList();
      // Sort in memory by date descending to avoid mandatory Firestore composite index requirement
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  /// Add a new transaction
  Future<String> addTransaction({
    required String uid,
    required double amount,
    required String categoryId,
    required String note,
    required DateTime date,
  }) async {
    final docRef = await _transactionsRef(uid).add({
      'amount': amount,
      'categoryId': categoryId,
      'note': note.trim(),
      'date': Timestamp.fromDate(date),
      'isDeleted': false,
      'deletedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Update an existing transaction (EDIT feature)
  Future<void> updateTransaction({
    required String uid,
    required String transactionId,
    required double amount,
    required String categoryId,
    required String note,
    required DateTime date,
  }) async {
    await _transactionsRef(uid).doc(transactionId).update({
      'amount': amount,
      'categoryId': categoryId,
      'note': note.trim(),
      'date': Timestamp.fromDate(date),
    });
  }

  /// Soft delete a transaction to Trash
  Future<void> softDeleteTransaction({
    required String uid,
    required String transactionId,
  }) async {
    await _transactionsRef(uid).doc(transactionId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  // -------------------------------------------------------------
  // TRASH (users/{uid}/transactions where isDeleted == true)
  // -------------------------------------------------------------
  Stream<List<TransactionData>> trashTransactionsStream(String uid) {
    return _transactionsRef(uid)
        .where('isDeleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => TransactionData.fromFirestore(doc))
          .toList();
      list.sort((a, b) => (b.deletedAt ?? b.date).compareTo(a.deletedAt ?? a.date));
      return list;
    });
  }

  /// Restore transaction from Trash back to active
  Future<void> restoreTransaction({
    required String uid,
    required String transactionId,
  }) async {
    await _transactionsRef(uid).doc(transactionId).update({
      'isDeleted': false,
      'deletedAt': null,
    });
  }

  /// Permanently delete transaction forever
  Future<void> permanentlyDeleteTransaction({
    required String uid,
    required String transactionId,
  }) async {
    await _transactionsRef(uid).doc(transactionId).delete();
  }
}

