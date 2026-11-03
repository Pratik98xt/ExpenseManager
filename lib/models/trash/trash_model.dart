import 'package:expense_manager_app/models/category/category_model.dart';
import 'package:expense_manager_app/models/transactions/transactions_model.dart';

class TrashData {
  final String trashId;
  final String trashAmount;
  final String trashDescription;
  final String trashDate;
  final String trashTime;
  final CategoryData? trashCategory;
  final DateTime? deletedAt;

  TrashData({
    required this.trashId,
    required this.trashAmount,
    required this.trashDescription,
    required this.trashDate,
    required this.trashTime,
    this.trashCategory,
    this.deletedAt,
  });

  factory TrashData.fromTransaction(TransactionData tx) {
    return TrashData(
      trashId: tx.expId,
      trashAmount: tx.amount.toStringAsFixed(2),
      trashDescription: tx.description,
      trashDate: tx.formattedDate,
      trashTime: tx.formattedTime,
      trashCategory: tx.categoryData,
      deletedAt: tx.deletedAt,
    );
  }
}
