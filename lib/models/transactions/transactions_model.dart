import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_manager_app/models/category/category_model.dart';
import 'package:intl/intl.dart';

class TransactionData {
  final String expId;
  final double amount;
  final String categoryId;
  final String description;
  final DateTime date;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  CategoryData? categoryData;

  TransactionData({
    required this.expId,
    required this.amount,
    required this.categoryId,
    required this.description,
    required this.date,
    this.isDeleted = false,
    this.deletedAt,
    required this.createdAt,
    this.categoryData,
  });

  /// Formatted date string (e.g. 2026-11-02)
  String get formattedDate => DateFormat('yyyy-MM-dd').format(date);

  /// Formatted time string (e.g. 10:30 AM)
  String get formattedTime => DateFormat('hh:mm a').format(date);

  /// Backward compatibility getters
  String get time => formattedTime;
  String get note => description;

  /// Formatted amount with 2 decimal places
  String get formattedAmount => amount.toStringAsFixed(2);

  /// Convert to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'categoryId': categoryId,
      'note': description,
      'date': Timestamp.fromDate(date),
      'isDeleted': isDeleted,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create from Firestore Document
  factory TransactionData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Safe amount parsing: handles int, double, or num safely
    final double parsedAmount = (data['amount'] as num?)?.toDouble() ?? 0.0;

    DateTime parsedDate = DateTime.now();
    if (data['date'] is Timestamp) {
      parsedDate = (data['date'] as Timestamp).toDate();
    }

    DateTime? parsedDeletedAt;
    if (data['deletedAt'] is Timestamp) {
      parsedDeletedAt = (data['deletedAt'] as Timestamp).toDate();
    }

    DateTime parsedCreatedAt = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      parsedCreatedAt = (data['createdAt'] as Timestamp).toDate();
    }

    return TransactionData(
      expId: doc.id,
      amount: parsedAmount,
      categoryId: data['categoryId']?.toString() ?? '',
      description: data['note']?.toString() ?? data['description']?.toString() ?? '',
      date: parsedDate,
      isDeleted: data['isDeleted'] is bool ? data['isDeleted'] : false,
      deletedAt: parsedDeletedAt,
      createdAt: parsedCreatedAt,
    );
  }
}
