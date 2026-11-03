import 'package:expense_manager_app/controllers/category/category_controller.dart';
import 'package:expense_manager_app/controllers/graphs/graphs_controller.dart';
import 'package:expense_manager_app/controllers/transactions/transaction_controller.dart';
import 'package:expense_manager_app/models/graphs/graphs_model.dart';
import 'package:expense_manager_app/themes/app_colors.dart';
import 'package:expense_manager_app/themes/app_textstyle.dart';
import 'package:expense_manager_app/views/transactions/menu_drawer_screen.dart';
import 'package:expense_manager_app/views/transactions/transactions_home_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GraphsScreen extends StatefulWidget {
  const GraphsScreen({super.key});

  @override
  State<GraphsScreen> createState() => _GraphsScreenState();
}

class _GraphsScreenState extends State<GraphsScreen> {
  int _touchedIndex = -1;

  void _shiftMonth(int delta) {
    final graphsController = Provider.of<GraphsController>(context, listen: false);
    final current = graphsController.selectedFilterMonth;
    final newMonth = DateTime(current.year, current.month + delta, 1);
    graphsController.changeFilterMonth(newMonth);
  }

  @override
  Widget build(BuildContext context) {
    final graphsController = Provider.of<GraphsController>(context);
    final txController = Provider.of<TransactionController>(context);
    final catController = Provider.of<CategoryController>(context);

    // Pure computation of graph data without triggering notifyListeners() in build
    final List<GraphsData> graphDataList = graphsController.getGraphData(
      txController.listOfTransactions,
      catController.listOfAllCategories,
    );
    final double totalSpent = graphDataList.fold(0.0, (sum, g) => sum + g.amount);

    final formattedFilterMonth =
        DateFormat('MMMM yyyy').format(graphsController.selectedFilterMonth);

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
          title: Text('Spending Graphs', style: AppTextStyle.appBarTextStyle()),
        ),
        drawer: const MenuDrawerScreen(selectedButtonIndex: 1),
        body: Column(
          children: [
            // MONTH SELECTOR BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _shiftMonth(-1),
                  ),
                  Text(
                    formattedFilterMonth,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _shiftMonth(1),
                  ),
                ],
              ),
            ),

            Expanded(
              child: graphDataList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No expense data for $formattedFilterMonth',
                            style: AppTextStyle.subTitleTextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Transactions recorded for this month will appear here',
                            style: AppTextStyle.descriptionTextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // PIE CHART
                          SizedBox(
                            height: 220,
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection == null) {
                                        _touchedIndex = -1;
                                        return;
                                      }
                                      _touchedIndex = pieTouchResponse
                                          .touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 3,
                                centerSpaceRadius: 40,
                                sections: List.generate(
                                  graphDataList.length,
                                  (index) {
                                    final item = graphDataList[index];
                                    final isTouched = index == _touchedIndex;
                                    final radius = isTouched ? 65.0 : 55.0;
                                    final double percentage = totalSpent > 0
                                        ? (item.amount / totalSpent) * 100
                                        : 0.0;

                                    return PieChartSectionData(
                                      color: item.color,
                                      value: item.amount,
                                      title: '${percentage.toStringAsFixed(0)}%',
                                      radius: radius,
                                      titleStyle: GoogleFonts.poppins(
                                        fontSize: isTouched ? 14 : 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // CATEGORY BREAKDOWN LIST
                          ListView.separated(
                            itemCount: graphDataList.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = graphDataList[index];
                              final double percentage = totalSpent > 0
                                  ? (item.amount / totalSpent) * 100
                                  : 0.0;

                              return ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                leading: CircleAvatar(
                                  backgroundColor: item.color,
                                  radius: 20,
                                  child: Icon(item.icon, color: Colors.white, size: 20),
                                ),
                                title: Text(
                                  item.catName,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  '${percentage.toStringAsFixed(1)}% of monthly total',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                                trailing: Text(
                                  '\u20B9 ${item.amount.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
            ),

            // BOTTOM TOTAL BAR
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Spent',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '\u20B9 ${totalSpent.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
