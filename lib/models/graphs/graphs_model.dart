import 'package:expense_manager_app/models/category/category_model.dart';
import 'package:flutter/material.dart';

class GraphsData {
  final String catName;
  final double amount;
  final int catColor;
  final int iconCodePoint;

  GraphsData({
    required this.catName,
    required this.amount,
    required this.catColor,
    required this.iconCodePoint,
  });

  Color get color => Color(catColor);
  IconData get icon => CategoryData.getIconByCodePoint(iconCodePoint);

  factory GraphsData.fromMap(Map<String, dynamic> json) {
    // Safe double conversion
    final double parsedAmount = (json['amount'] as num?)?.toDouble() ?? 0.0;

    int parsedColor = Colors.teal.toARGB32();
    if (json['catColor'] is int) {
      parsedColor = json['catColor'];
    } else if (json['catColor'] is String) {
      parsedColor = int.tryParse(json['catColor']) ?? Colors.teal.toARGB32();
    }

    int parsedIcon = Icons.category.codePoint;
    if (json['icon'] is int) {
      parsedIcon = json['icon'];
    } else if (json['icon'] is String) {
      parsedIcon = int.tryParse(json['icon']) ?? Icons.category.codePoint;
    }

    return GraphsData(
      catName: json['catName']?.toString() ?? 'Uncategorized',
      amount: parsedAmount,
      catColor: parsedColor,
      iconCodePoint: parsedIcon,
    );
  }
}
