import 'package:expense_manager_app/controllers/category/category_controller.dart';
import 'package:expense_manager_app/controllers/transactions/transaction_controller.dart';
import 'package:expense_manager_app/controllers/welcome/auth_controller.dart';
import 'package:expense_manager_app/models/category/category_model.dart';
import 'package:expense_manager_app/models/transactions/transactions_model.dart';
import 'package:expense_manager_app/themes/app_colors.dart';
import 'package:expense_manager_app/themes/app_textstyle.dart';
import 'package:expense_manager_app/views/category/category_screen.dart';
import 'package:expense_manager_app/views/transactions/menu_drawer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TransactionsHomeScreen extends StatefulWidget {
  const TransactionsHomeScreen({super.key});

  @override
  State<TransactionsHomeScreen> createState() => _TransactionsHomeScreenState();
}

class _TransactionsHomeScreenState extends State<TransactionsHomeScreen> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime _selectedDateTime = DateTime.now();
  CategoryData? _modalSelectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authController = Provider.of<AuthController>(context, listen: false);
      if (authController.currentUser != null) {
        final uid = authController.currentUser!.uid;
        Provider.of<CategoryController>(context, listen: false).listenToCategories(uid);
        Provider.of<TransactionController>(context, listen: false).listenToTransactions(uid);
      }
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Month picker helper to shift months
  void _shiftMonth(int delta) {
    final txController = Provider.of<TransactionController>(context, listen: false);
    final current = txController.selectedFilterMonth;
    final newMonth = DateTime(current.year, current.month + delta, 1);
    txController.changeFilterMonth(newMonth);
  }

  /// Helper to find category by ID
  CategoryData _getCategory(List<CategoryData> categories, String categoryId) {
    return categories.firstWhere(
      (c) => c.categoryId == categoryId,
      orElse: () => CategoryData(
        categoryId: categoryId,
        categoryName: 'Uncategorized',
        categoryColor: Colors.grey.toARGB32(),
        iconCodePoint: Icons.category.codePoint,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Bottom sheet for Adding or Editing a transaction
  void _showTransactionBottomSheet({TransactionData? editingTransaction}) {
    final isEditing = editingTransaction != null;
    final categoryController = Provider.of<CategoryController>(context, listen: false);

    if (categoryController.listOfAllCategories.isEmpty) {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('No Categories'),
          content: const Text('Please create at least one category before adding an expense.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CategoryScreen()),
                );
              },
              child: const Text('Add Category', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    if (isEditing) {
      _selectedDateTime = editingTransaction.date;
      _amountController.text = editingTransaction.amount.toString();
      _descriptionController.text = editingTransaction.description;
      _modalSelectedCategory = _getCategory(
        categoryController.listOfAllCategories,
        editingTransaction.categoryId,
      );
    } else {
      _selectedDateTime = DateTime.now();
      _amountController.clear();
      _descriptionController.clear();
      _modalSelectedCategory = categoryController.listOfAllCategories.first;
    }
    _dateController.text = DateFormat('yyyy-MM-dd | hh:mm a').format(_selectedDateTime);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 20.0,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    Text(
                      isEditing ? 'Edit Expense' : 'Add Expense',
                      textAlign: TextAlign.center,
                      style: AppTextStyle.titleTextStyle(),
                    ),
                    const SizedBox(height: 18),

                    // DATE & TIME PICKER
                    Text('Date & Time', style: AppTextStyle.descriptionTextStyle(fontSize: 15)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: sheetContext,
                          initialDate: _selectedDateTime,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate == null || !sheetContext.mounted) return;

                        final pickedTime = await showTimePicker(
                          context: sheetContext,
                          initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                        );
                        if (pickedTime == null) return;

                        setModalState(() {
                          _selectedDateTime = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                          _dateController.text =
                              DateFormat('yyyy-MM-dd | hh:mm a').format(_selectedDateTime);
                        });
                      },
                    ),

                    const SizedBox(height: 14),

                    // AMOUNT FIELD
                    Text('Amount (\u20B9)', style: AppTextStyle.descriptionTextStyle(fontSize: 15)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: InputDecoration(
                        hintText: 'e.g. 250.00',
                        prefixIcon: const Icon(Icons.currency_rupee),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // CATEGORY DROPDOWN
                    Text('Category', style: AppTextStyle.descriptionTextStyle(fontSize: 15)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _modalSelectedCategory?.categoryId,
                          isExpanded: true,
                          items: categoryController.listOfAllCategories.map((cat) {
                            return DropdownMenuItem<String>(
                              value: cat.categoryId,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: cat.color,
                                    child: Icon(cat.icon, color: Colors.white, size: 14),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(cat.categoryName),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (newCatId) {
                            if (newCatId == null) return;
                            setModalState(() {
                              _modalSelectedCategory = _getCategory(
                                categoryController.listOfAllCategories,
                                newCatId,
                              );
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // DESCRIPTION FIELD
                    Text('Note / Description', style: AppTextStyle.descriptionTextStyle(fontSize: 15)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Lunch with team, monthly internet bill',
                        prefixIcon: const Icon(Icons.notes_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // SUBMIT BUTTON
                    Consumer<TransactionController>(
                      builder: (btnContext, txController, child) {
                        return ElevatedButton(
                          onPressed: txController.isTransactionLoading
                              ? null
                              : () async {
                                  final amountText = _amountController.text.trim();
                                  final amount = double.tryParse(amountText);
                                  if (amount == null || amount <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter a valid amount greater than 0')),
                                    );
                                    return;
                                  }

                                  if (_modalSelectedCategory == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please select a category')),
                                    );
                                    return;
                                  }

                                  final authController =
                                      Provider.of<AuthController>(context, listen: false);
                                  if (authController.currentUser == null) return;
                                  final uid = authController.currentUser!.uid;

                                  bool success;
                                  if (isEditing) {
                                    success = await txController.editTransaction(
                                      uid: uid,
                                      transactionId: editingTransaction.expId,
                                      amount: amount,
                                      categoryId: _modalSelectedCategory!.categoryId,
                                      note: _descriptionController.text.trim(),
                                      date: _selectedDateTime,
                                    );
                                  } else {
                                    success = await txController.addTransaction(
                                      uid: uid,
                                      amount: amount,
                                      categoryId: _modalSelectedCategory!.categoryId,
                                      note: _descriptionController.text.trim(),
                                      date: _selectedDateTime,
                                    );
                                  }

                                  if (!sheetContext.mounted || !mounted) return;

                                  if (success) {
                                    Navigator.of(sheetContext).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isEditing
                                            ? 'Expense updated successfully'
                                            : 'Expense added successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(txController.errorMessage ??
                                            'Failed to save transaction'),
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
                          child: txController.isTransactionLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isEditing ? 'Save Changes' : 'Add Expense',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryController = Provider.of<CategoryController>(context);
    final transactionController = Provider.of<TransactionController>(context);

    final formattedFilterMonth =
        DateFormat('MMMM yyyy').format(transactionController.selectedFilterMonth);

    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions', style: AppTextStyle.appBarTextStyle()),
      ),
      drawer: const MenuDrawerScreen(selectedButtonIndex: 0),
      body: Column(
        children: [
          // MONTH / YEAR SELECTOR & TOTAL CARD
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Month switcher row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () => _shiftMonth(-1),
                    ),
                    Text(
                      formattedFilterMonth,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: () => _shiftMonth(1),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monthly Total:',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '\u20B9 ${transactionController.monthlyTotal.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // LIST OF TRANSACTIONS
          Expanded(
            child: transactionController.isTransactionLoading &&
                    transactionController.listOfTransactions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : transactionController.listOfTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No transactions for $formattedFilterMonth',
                              style: AppTextStyle.subTitleTextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap + Add Transaction to record your first expense',
                              style: AppTextStyle.descriptionTextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: transactionController.listOfTransactions.length,
                        padding: const EdgeInsets.only(bottom: 80),
                        itemBuilder: (itemContext, index) {
                          final tx = transactionController.listOfTransactions[index];
                          final category = _getCategory(
                            categoryController.listOfAllCategories,
                            tx.categoryId,
                          );

                          return Dismissible(
                            key: ValueKey(tx.expId),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              color: Colors.redAccent,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(Icons.delete, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Move to Trash',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            onDismissed: (direction) async {
                              final authController =
                                  Provider.of<AuthController>(context, listen: false);
                              if (authController.currentUser != null) {
                                final success = await transactionController.deleteTransaction(
                                  uid: authController.currentUser!.uid,
                                  transactionId: tx.expId,
                                );
                                if (!context.mounted || !mounted) return;
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Moved '${tx.description}' to trash"),
                                      action: SnackBarAction(
                                        label: 'OK',
                                        onPressed: () {},
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: _transactionCard(tx, category),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTransactionBottomSheet(),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle, color: AppColors.primaryColor, size: 30),
            const SizedBox(width: 8),
            Text(
              'Add Transaction',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transactionCard(TransactionData tx, CategoryData category) {
    return InkWell(
      onTap: () => _showTransactionBottomSheet(editingTransaction: tx),
      child: Container(
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
            // Category Icon Circle
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(category.icon, color: category.color, size: 26),
            ),
            const SizedBox(width: 14),

            // Category Name & Description
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
                  const SizedBox(height: 4),
                  Text(
                    tx.description.isNotEmpty ? tx.description : 'No note',
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

            // Amount and Date/Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '- \u20B9 ${tx.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tx.formattedDate} | ${tx.formattedTime}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
