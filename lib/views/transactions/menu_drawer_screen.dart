import 'package:expense_manager_app/controllers/category/category_controller.dart';
import 'package:expense_manager_app/controllers/graphs/graphs_controller.dart';
import 'package:expense_manager_app/controllers/transactions/transaction_controller.dart';
import 'package:expense_manager_app/controllers/trash/trash_controller.dart';
import 'package:expense_manager_app/controllers/welcome/auth_controller.dart';
import 'package:expense_manager_app/themes/app_colors.dart';
import 'package:expense_manager_app/themes/app_textstyle.dart';
import 'package:expense_manager_app/views/category/category_screen.dart';
import 'package:expense_manager_app/views/graph/graphs_screen.dart';
import 'package:expense_manager_app/views/transactions/transactions_home_screen.dart';
import 'package:expense_manager_app/views/trash/trash_screen.dart';
import 'package:expense_manager_app/views/welcome/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MenuDrawerScreen extends StatefulWidget {
  final int selectedButtonIndex;
  const MenuDrawerScreen({super.key, required this.selectedButtonIndex});

  @override
  State<MenuDrawerScreen> createState() => _MenuDrawerScreenState();
}

class _MenuDrawerScreenState extends State<MenuDrawerScreen> {
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Logout', style: AppTextStyle.titleTextStyle()),
          content: Text(
            'Are you sure you want to sign out?',
            style: AppTextStyle.descriptionTextStyle(
              color: const Color.fromRGBO(0, 0, 0, 0.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                // Reset all controllers to clear previous user's data
                Provider.of<CategoryController>(context, listen: false).reset();
                Provider.of<TransactionController>(context, listen: false).reset();
                Provider.of<TrashController>(context, listen: false).reset();
                Provider.of<GraphsController>(context, listen: false).reset();

                final authController = Provider.of<AuthController>(context, listen: false);
                await authController.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Expense Manager',
                style: AppTextStyle.titleTextStyle(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Saves all your Transactions',
                style: AppTextStyle.descriptionTextStyle(
                  color: const Color.fromRGBO(0, 0, 0, 0.5),
                ),
              ),
            ),
            if (authController.userName.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryColor.withValues(alpha: 0.2),
                      child: Text(
                        authController.userName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authController.userName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            authController.userEmail,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            const Divider(),

            /// NAVIGATION BUTTONS
            _menuButton(
              buttonName: 'Transactions',
              iconPath: 'assets/icons/transaction_icon.png',
              buttonIndex: 0,
              onButtonTap: () {
                Navigator.of(context).pop();
                if (widget.selectedButtonIndex != 0) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const TransactionsHomeScreen()),
                  );
                }
              },
            ),
            _menuButton(
              buttonName: 'Graphs',
              iconPath: 'assets/icons/graph_icon.png',
              buttonIndex: 1,
              onButtonTap: () {
                Navigator.of(context).pop();
                if (widget.selectedButtonIndex != 1) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const GraphsScreen()),
                  );
                }
              },
            ),
            _menuButton(
              buttonName: 'Category',
              iconPath: 'assets/icons/category_icon.png',
              buttonIndex: 2,
              onButtonTap: () {
                Navigator.of(context).pop();
                if (widget.selectedButtonIndex != 2) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const CategoryScreen()),
                  );
                }
              },
            ),
            _menuButton(
              buttonName: 'Trash',
              iconPath: 'assets/icons/trash_icon.png',
              buttonIndex: 3,
              onButtonTap: () {
                Navigator.of(context).pop();
                if (widget.selectedButtonIndex != 3) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const TrashScreen()),
                  );
                }
              },
            ),

            const Spacer(),

            /// LOGOUT BUTTON
            Padding(
              padding: const EdgeInsets.only(bottom: 25.0),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => _showLogoutDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButton({
    required String buttonName,
    required String iconPath,
    required int buttonIndex,
    required VoidCallback onButtonTap,
  }) {
    final isSelected = widget.selectedButtonIndex == buttonIndex;
    return GestureDetector(
      onTap: onButtonTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withValues(alpha: 0.15)
              : Colors.white,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        margin: const EdgeInsets.only(right: 50, top: 15),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20.0),
        child: Row(
          children: [
            Image.asset(iconPath, width: 24, height: 24),
            const SizedBox(width: 12),
            Text(
              buttonName,
              style: AppTextStyle.menuButtonsTextStyle(
                color: isSelected ? AppColors.primaryColor : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
