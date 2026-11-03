import 'dart:async';
import 'package:expense_manager_app/models/category/category_model.dart';
import 'package:expense_manager_app/services/firestore_service.dart';
import 'package:flutter/material.dart';

class CategoryController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<List<CategoryData>>? _categoriesSubscription;

  List<CategoryData> listOfAllCategories = [];
  bool isCategoryLoading = false;
  String? errorMessage;

  int selectedColorIndex = 0;
  int selectedIconIndex = 0;

  String? _currentUid;

  /// Listen to real-time categories stream from Firestore
  void listenToCategories(String uid) {
    if (_currentUid == uid && _categoriesSubscription != null) return;
    _currentUid = uid;
    _categoriesSubscription?.cancel();

    _categoriesSubscription = _firestoreService.categoriesStream(uid).listen(
      (categories) {
        listOfAllCategories = categories;
        isCategoryLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        errorMessage = error.toString();
        isCategoryLoading = false;
        notifyListeners();
      },
    );
  }

  /// Reset state on logout
  void reset() {
    _categoriesSubscription?.cancel();
    _categoriesSubscription = null;
    _currentUid = null;
    listOfAllCategories.clear();
    selectedColorIndex = 0;
    selectedIconIndex = 0;
    isCategoryLoading = false;
    errorMessage = null;
    notifyListeners();
  }

  /// Add a new category
  Future<bool> addCategory({
    required String uid,
    required String name,
    required int color,
    required int iconCodePoint,
  }) async {
    isCategoryLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.addCategory(
        uid: uid,
        name: name,
        color: color,
        iconCodePoint: iconCodePoint,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isCategoryLoading = false;
      notifyListeners();
    }
  }

  /// Delete category
  Future<bool> deleteCategory({
    required String uid,
    required String categoryId,
  }) async {
    isCategoryLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.deleteCategory(
        uid: uid,
        categoryId: categoryId,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isCategoryLoading = false;
      notifyListeners();
    }
  }

  void toggleColor({int? index}) {
    if (index != null && index >= 0) {
      selectedColorIndex = index;
      notifyListeners();
    }
  }

  void toggleIcon({int? index}) {
    if (index != null && index >= 0) {
      selectedIconIndex = index;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    super.dispose();
  }
}
