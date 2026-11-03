import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoryData {
  final String categoryId;
  final String categoryName;
  final int categoryColor;
  final int iconCodePoint;
  final DateTime createdAt;

  CategoryData({
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.iconCodePoint,
    required this.createdAt,
  });

  /// Get Flutter Color from the ARGB integer
  Color get color => Color(categoryColor);

  /// Get constant Flutter IconData from the codePoint (supports icon tree-shaking)
  IconData get icon => getIconByCodePoint(iconCodePoint);

  static IconData getIconByCodePoint(int codePoint) {
    switch (codePoint) {
      case 0xe25a:
        return Icons.fastfood;
      case 0xe59a:
        return Icons.shopping_bag;
      case 0xe1d7:
        return Icons.directions_car;
      case 0xe40d:
        return Icons.movie;
      case 0xe50d:
        return Icons.receipt_long;
      case 0xe318:
        return Icons.home;
      case 0xe297:
        return Icons.flight;
      case 0xe28d:
        return Icons.fitness_center;
      case 0xe559:
        return Icons.school;
      case 0xe3d8:
        return Icons.medical_services;
      case 0xe4a1:
        return Icons.pets;
      case 0xe553:
        return Icons.savings;
      default:
        return Icons.category;
    }
  }

  /// Backward compatibility getters
  String get name => categoryName;
  String get categoryImage => '';

  /// Convert to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'name': categoryName,
      'color': categoryColor,
      'icon': iconCodePoint,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create from Firestore Document
  factory CategoryData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Safe color parsing: handles integer, string, or defaults to teal
    int parsedColor = Colors.teal.toARGB32();
    if (data['color'] is int) {
      parsedColor = data['color'];
    } else if (data['color'] is String) {
      parsedColor = int.tryParse(data['color']) ?? Colors.teal.toARGB32();
    }

    // Default icon: category icon codePoint (Icons.category = 0xe148)
    int parsedIcon = Icons.category.codePoint;
    if (data['icon'] is int) {
      parsedIcon = data['icon'];
    } else if (data['icon'] is String) {
      parsedIcon = int.tryParse(data['icon']) ?? Icons.category.codePoint;
    }

    DateTime parsedDate = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    }

    return CategoryData(
      categoryId: doc.id,
      categoryName: data['name']?.toString() ?? 'Uncategorized',
      categoryColor: parsedColor,
      iconCodePoint: parsedIcon,
      createdAt: parsedDate,
    );
  }
}
