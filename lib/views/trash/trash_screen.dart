import 'package:expense_manager_app/controllers/category/category_controller.dart';
import 'package:expense_manager_app/controllers/trash/trash_controller.dart';
import 'package:expense_manager_app/controllers/welcome/auth_controller.dart';
import 'package:expense_manager_app/models/category/category_model.dart';
import 'package:expense_manager_app/models/trash/trash_model.dart';
import 'package:expense_manager_app/themes/app_textstyle.dart';
import 'package:expense_manager_app/views/transactions/menu_drawer_screen.dart';
import 'package:expense_manager_app/views/transactions/transactions_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authController = Provider.of<AuthController>(context, listen: false);
      if (authController.currentUser != null) {
        final uid = authController.currentUser!.uid;
        Provider.of<CategoryController>(context, listen: false).listenToCategories(uid);
        Provider.of<TrashController>(context, listen: false).listenToTrash(uid);
      }
    });
  }

  void _confirmDeleteForever(TrashData trashItem) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Permanently?'),
          content: Text(
            "Are you sure you want to permanently delete '${trashItem.trashDescription.isNotEmpty ? trashItem.trashDescription : trashItem.trashCategory?.categoryName}'?\n\nThis action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                final authController = Provider.of<AuthController>(context, listen: false);
                final trashController = Provider.of<TrashController>(context, listen: false);
                if (authController.currentUser != null) {
                  final success = await trashController.permanentlyDeleteTrash(
                    uid: authController.currentUser!.uid,
                    trashId: trashItem.trashId,
                  );
                  if (!mounted) return;
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense deleted permanently'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete Forever', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryController = Provider.of<CategoryController>(context);

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
          title: Text('Trash', style: AppTextStyle.appBarTextStyle()),
        ),
        drawer: const MenuDrawerScreen(selectedButtonIndex: 3),
        body: Consumer<TrashController>(
          builder: (context, controller, child) {
            if (controller.isTrashLoading && controller.listOfTrashData.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.listOfTrashData.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Trash is empty',
                      style: AppTextStyle.subTitleTextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Deleted transactions will appear here',
                      style: AppTextStyle.descriptionTextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: controller.listOfTrashData.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (itemContext, index) {
                final trashItem = controller.listOfTrashData[index];
                return Slidable(
                  key: ValueKey(trashItem.trashId),
                  startActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (ctx) async {
                          final authController =
                              Provider.of<AuthController>(context, listen: false);
                          if (authController.currentUser != null) {
                            final success = await controller.restoreTrash(
                              uid: authController.currentUser!.uid,
                              trashId: trashItem.trashId,
                            );
                            if (!context.mounted) return;
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Expense restored to active list'),
                                  backgroundColor: Colors.lightGreen,
                                ),
                              );
                            }
                          }
                        },
                        label: 'Restore',
                        icon: Icons.restore,
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.lightGreen,
                      ),
                    ],
                  ),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (ctx) => _confirmDeleteForever(trashItem),
                        label: 'Delete Forever',
                        icon: Icons.delete_forever,
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.redAccent,
                      ),
                    ],
                  ),
                  child: _trashTransactionCard(trashItem, categoryController.listOfAllCategories),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _trashTransactionCard(TrashData item, List<CategoryData> categories) {
    final category = categories.firstWhere(
      (c) => c.categoryId == item.trashCategory?.categoryId,
      orElse: () => CategoryData(
        categoryId: '',
        categoryName: item.trashCategory?.categoryName ?? 'Uncategorized',
        categoryColor: Colors.grey.toARGB32(),
        iconCodePoint: Icons.category.codePoint,
        createdAt: DateTime.now(),
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(category.icon, color: category.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.categoryName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  item.trashDescription.isNotEmpty ? item.trashDescription : 'No note',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '- \u20B9 ${item.trashAmount}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${item.trashDate} | ${item.trashTime}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
