import 'package:expense_manager_app/controllers/category/category_controller.dart';
import 'package:expense_manager_app/controllers/graphs/graphs_controller.dart';
import 'package:expense_manager_app/controllers/transactions/transaction_controller.dart';
import 'package:expense_manager_app/controllers/trash/trash_controller.dart';
import 'package:expense_manager_app/controllers/welcome/auth_controller.dart';
import 'package:expense_manager_app/firebase_options.dart';
import 'package:expense_manager_app/views/welcome/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => CategoryController()),
        ChangeNotifierProvider(create: (_) => TransactionController()),
        ChangeNotifierProvider(create: (_) => GraphsController()),
        ChangeNotifierProvider(create: (_) => TrashController()),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      ),
    );
  }
}
