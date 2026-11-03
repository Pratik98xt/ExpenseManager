import 'package:expense_manager_app/controllers/category/category_controller.dart';
import 'package:expense_manager_app/controllers/welcome/auth_controller.dart';
import 'package:expense_manager_app/models/category/category_model.dart';
import 'package:expense_manager_app/themes/app_colors.dart';
import 'package:expense_manager_app/themes/app_textstyle.dart';
import 'package:expense_manager_app/views/transactions/menu_drawer_screen.dart';
import 'package:expense_manager_app/views/transactions/transactions_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final TextEditingController _categoryNameController = TextEditingController();

  // 10 Standard Flutter ARGB Colors
  final List<int> _colorsList = const [
    0xFFE24F4F, // Red
    0xFF9378FF, // Purple
    0xFF4DC78C, // Green
    0xFFF668D7, // Pink
    0xFFFFAE00, // Amber/Orange
    0xFF2196F3, // Blue
    0xFF009688, // Teal
    0xFFC27656, // Terracotta
    0xFF795548, // Brown
    0xFF607D8B, // Blue Grey
  ];

  // 12 Standard Material Icons for categories
  final List<IconData> _iconsList = const [
    Icons.fastfood,
    Icons.shopping_bag,
    Icons.directions_car,
    Icons.movie,
    Icons.receipt_long,
    Icons.home,
    Icons.flight,
    Icons.fitness_center,
    Icons.school,
    Icons.medical_services,
    Icons.pets,
    Icons.savings,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authController = Provider.of<AuthController>(context, listen: false);
      if (authController.currentUser != null) {
        Provider.of<CategoryController>(context, listen: false)
            .listenToCategories(authController.currentUser!.uid);
      }
    });
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  void _showDeleteAlertDialog(CategoryData category) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete Category',
            textAlign: TextAlign.center,
            style: AppTextStyle.titleTextStyle(),
          ),
          content: Text(
            "Are you sure you want to delete '${category.categoryName}'?",
            textAlign: TextAlign.center,
            style: AppTextStyle.descriptionTextStyle(
              color: const Color.fromRGBO(0, 0, 0, 0.7),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final authController = Provider.of<AuthController>(context, listen: false);
                final categoryController = Provider.of<CategoryController>(context, listen: false);

                if (authController.currentUser != null) {
                  final success = await categoryController.deleteCategory(
                    uid: authController.currentUser!.uid,
                    categoryId: category.categoryId,
                  );
                  if (!mounted) return;
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("'${category.categoryName}' deleted"),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _addCategoryBottomSheet() {
    _categoryNameController.clear();
    final categoryController = Provider.of<CategoryController>(context, listen: false);
    categoryController.toggleColor(index: 0);
    categoryController.toggleIcon(index: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 20.0,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Consumer<CategoryController>(
              builder: (context, controller, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Create Category',
                        style: AppTextStyle.titleTextStyle(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Category Name', style: AppTextStyle.subTitleTextStyle()),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _categoryNameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Groceries, Gym, Rent',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // CHOOSE COLOR
                    Text('Choose Color', style: AppTextStyle.subTitleTextStyle()),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(_colorsList.length, (index) {
                        final isSelected = controller.selectedColorIndex == index;
                        return GestureDetector(
                          onTap: () => controller.toggleColor(index: index),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Color(_colorsList[index]),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.transparent,
                                width: 3.0,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),

                    // CHOOSE ICON
                    Text('Choose Icon', style: AppTextStyle.subTitleTextStyle()),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(_iconsList.length, (index) {
                        final isSelected = controller.selectedIconIndex == index;
                        return GestureDetector(
                          onTap: () => controller.toggleIcon(index: index),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryColor.withValues(alpha: 0.15)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
                                width: 2.0,
                              ),
                            ),
                            child: Icon(
                              _iconsList[index],
                              color: isSelected ? AppColors.primaryColor : Colors.black87,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    // SUBMIT BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.isCategoryLoading
                            ? null
                            : () async {
                                final name = _categoryNameController.text.trim();
                                if (name.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter a category name')),
                                  );
                                  return;
                                }

                                final authController = Provider.of<AuthController>(context, listen: false);
                                if (authController.currentUser == null) return;

                                final success = await controller.addCategory(
                                  uid: authController.currentUser!.uid,
                                  name: name,
                                  color: _colorsList[controller.selectedColorIndex],
                                  iconCodePoint: _iconsList[controller.selectedIconIndex].codePoint,
                                );

                                if (!sheetContext.mounted) return;

                                if (success) {
                                  Navigator.of(sheetContext).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Category '$name' added successfully"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(controller.errorMessage ?? 'Failed to add category'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: controller.isCategoryLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Add Category',
                                style: AppTextStyle.buttonTextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const TransactionsHomeScreen()),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Categories', style: AppTextStyle.appBarTextStyle()),
        ),
      drawer: const MenuDrawerScreen(selectedButtonIndex: 2),
      body: Consumer<CategoryController>(
        builder: (context, controller, child) {
          if (controller.isCategoryLoading && controller.listOfAllCategories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.listOfAllCategories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No categories found',
                    style: AppTextStyle.subTitleTextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + Add Category below to create your first category',
                    style: AppTextStyle.descriptionTextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: controller.listOfAllCategories.length,
            itemBuilder: (context, index) {
              final category = controller.listOfAllCategories[index];
              return _categoryCard(category);
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCategoryBottomSheet,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        label: Row(
          children: [
            Icon(Icons.add_circle, size: 30, color: AppColors.primaryColor),
            const SizedBox(width: 8),
            Text('Add Category', style: AppTextStyle.buttonTextStyle()),
          ],
        ),
      ),
    ),
    );
  }

  Widget _categoryCard(CategoryData category) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: category.color,
                      boxShadow: [
                        BoxShadow(
                          color: category.color.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      category.icon,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  category.categoryName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subTitleTextStyle(),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey.shade400),
              splashRadius: 20,
              onPressed: () => _showDeleteAlertDialog(category),
            ),
          ),
        ],
      ),
    );
  }
}
