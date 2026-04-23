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
  DateTime expirationDate = DateTime(2099, 12, 30);

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
      home: isExpired
          ? const AppExpired()
          : const DisclaimerGate(child: HomePage()),
    );
  }
}

class DisclaimerGate extends StatefulWidget {
  final Widget child;
  const DisclaimerGate({super.key, required this.child});

  @override
  State<DisclaimerGate> createState() => _DisclaimerGateState();
}

class _DisclaimerGateState extends State<DisclaimerGate> {
  bool _hasAgreed = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final contentHeight = (screenSize.height * 0.5).clamp(220.0, 520.0).toDouble();

    return Stack(
      children: [
        IgnorePointer(
          ignoring: !_hasAgreed,
          child: widget.child,
        ),
        if (!_hasAgreed)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black54,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: screenSize.width * 0.9,
                    child: AlertDialog(
                      insetPadding: EdgeInsets.symmetric(
                        horizontal: screenSize.width * 0.05,
                      ),
                      title: const Text('Artifact Ethics'),
                      content: SizedBox(
                        width: double.maxFinite,
                        height: contentHeight,
                        child: const SingleChildScrollView(
                          child: Text(
                            "You may see a sherd with an appealing design and think, \"I'm going to collect that. There's lots more, so it won't be missed\". The problem is there's too many people who have the same thought. Suppose you have an archaeological site with 100 decorated sherds on the surface, which is a lot, and one visitor a month picks up one of those sherds. Ten years later, and they're all gone, and the information they held about who was there and when they were there cannot be recovered. That has already been the fate of many archaeological sites whose existence is well known. National Parks and Monuments have boxes full of sherds sent back to them by visitors who collected them and then felt guilty about breaking the rules. Without information about where they were collected, these are now of no value to archaeologists trying to understand the history of a site. In addition, collectioning of any artifacts in National Parks and Monuments is a violation of park rules, and violators are subject to steep fines. Some parks even fine you if you just pick up an artifact with the intention of putting it back down again. Collection of most artifacts on any Federal land, or disturbing archaeological sites, is a violation of the Archaeological Resources Protection Act, and leaves you open to large fines and even jail time. If you see a sherd or artifact that looks interesting on Federal land not under the control of the National Park Service, pick it up, admire it, take a picture, then put it back where you found it.",
                          ),
                        ),
                      ),
                      actions: [
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _hasAgreed = true;
                            });
                          },
                          child: const Text('Agree and Continue'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
