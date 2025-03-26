import 'package:dcraft/provider/drive_auth_provider.dart';
import 'package:dcraft/provider/theme_provider.dart';
import 'package:dcraft/screens/about/about_craft.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final Uri _url = Uri.parse(
      'https://www.ceias.nau.edu/capstone/projects/CS/2024/CRAFT_S24/');

  Future<void> _launchAboutURL() async {
    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }
  }

  void _connectToDrive() {
    final authProvider =
        Provider.of<GoogleDriveAuthProvider>(context, listen: false);

    authProvider.signIn();
  }

  void _disconnectFromDrive() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Disconnect from Google Drive?'),
          content: const Text(
              'Are you sure you want to disconnect your Google Drive account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                final authProvider = Provider.of<GoogleDriveAuthProvider>(
                    context,
                    listen: false);
                authProvider.signOut();
              },
              child: const Text(
                'Disconnect',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
    return;
  }

  void clearAppData() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear App Data?'),
          content: const Text(
              'Are you sure you want to clear all classification data? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Hive.box('classificationBox').clear();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('App data cleared')),
                );
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);

    final authProvider =
        Provider.of<GoogleDriveAuthProvider>(context, listen: true);
    final authService = authProvider.authService;

    return Scaffold(
      appBar: AppBar(
        // automaticallyImplyLeading: false,
        toolbarHeight: 80,
        title: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Settings',
            style: TextStyle(
                fontFamily: 'Uber', fontSize: 60, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Column(
                children: [
                  const SizedBox(height: 16),
                  Icon(
                    FontAwesomeIcons.googleDrive,
                    size: 90,
                    color: authService.isSignedIn ? Colors.green : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Google Drive",
                    style: TextStyle(
                      fontFamily: 'Uber',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: authService.isSignedIn ? Colors.green : null,
                    ),
                  ),
                  Text(
                    authService.isSignedIn ? "Connected" : "Not Connected",
                    style: TextStyle(
                      fontFamily: 'Uber',
                      fontSize: 35,
                      fontWeight: FontWeight.w700,
                      color: authService.isSignedIn ? Colors.green : null,
                    ),
                  ),
                  if (authService.isSignedIn &&
                      authService.userEmail?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        authService.userEmail ?? '',
                        style: const TextStyle(
                          fontFamily: 'Uber',
                          fontSize: 15,
                        ),
                      ),
                    ),
                  if (!authService.isSignedIn)
                    const Text(
                      "Connect to save your classifications",
                      style: TextStyle(
                        fontFamily: 'Uber',
                        fontSize: 15,
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: authService.isSignedIn
                        ? _disconnectFromDrive
                        : _connectToDrive,
                    icon: Icon(
                        authService.isSignedIn ? Icons.link_off : Icons.link),
                    label:
                        Text(authService.isSignedIn ? "Disconnect" : "Connect"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    'App Theme:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(width: 16),
                  Center(
                    child: DropdownButton<ThemeMode>(
                      value: themeProvider.themeMode,
                      underline: Container(),
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Row(
                            children: [
                              Icon(Icons.light_mode, size: 18),
                              SizedBox(width: 8),
                              Text('Light'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Row(
                            children: [
                              Icon(Icons.dark_mode, size: 18),
                              SizedBox(width: 8),
                              Text('Dark'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Row(
                            children: [
                              Icon(Icons.settings, size: 18),
                              SizedBox(width: 8),
                              Text('System'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (ThemeMode? newThemeMode) {
                        if (newThemeMode != null) {
                          themeProvider.setTheme(newThemeMode);
                        }
                      },
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: clearAppData,
                child: const Text("Having Issues? Clear App Data"),
              ),
              SizedBox(
                height: 8,
              ),
              Center(
                child: Column(
                  children: [
                    const Text('© 2024 CRAFT All rights reserved.'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                PageTransition(
                                    child: const AboutCraft(),
                                    type: PageTransitionType.fade));
                          },
                          child: const Text("About CRAFT"),
                        ),
                        TextButton(
                          onPressed: _launchAboutURL,
                          child: const Text("Learn More"),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
