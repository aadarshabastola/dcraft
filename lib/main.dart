import 'package:dcraft/provider/drive_auth_provider.dart';
import 'package:dcraft/provider/model_provider.dart';
import 'package:dcraft/provider/theme_provider.dart';
import 'package:dcraft/screens/app_expired.dart';
import 'package:dcraft/screens/homepage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Hive.initFlutter();
  await Hive.openBox("classificationBox");

  DateTime now = DateTime.now();
  DateTime expirationDate = DateTime(2025, 12, 31);

  bool isExpired = now.isAfter(expirationDate);

  runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => GoogleDriveAuthProvider()),
      ChangeNotifierProvider(create: (_) => ModelProvider()),
    ], child: MainApp(isExpired: isExpired)),
  );
}

class MainApp extends StatelessWidget {
  final bool isExpired;
  const MainApp({super.key, required this.isExpired});
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'dCRAFT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          useMaterial3: true, colorScheme: MaterialTheme.lightScheme()),
      darkTheme: ThemeData(
          useMaterial3: true, colorScheme: MaterialTheme.darkScheme()),
      themeMode: themeProvider.themeMode,
      routes: {
        HomePage.id: (context) => const HomePage(),
        AppExpired.id: (context) => const AppExpired(),
      },
      initialRoute: isExpired ? AppExpired.id : HomePage.id,
    );
  }
}
