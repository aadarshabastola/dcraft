import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppExpired extends StatelessWidget {
  static const String id = 'app_expired_screen';
  const AppExpired({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Expired',
              style: TextStyle(
                  fontFamily: 'Uber',
                  fontSize: 60,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'This build of CRAFT expired on 07/15/2025.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Uber',
                fontSize: 15,
              ),
            ),
          ),
          SizedBox(
            height: 16,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Please contact Dr. Leszek Pawlowicz (Leszek.Pawlowicz@nau.edu) for the latest version.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Uber',
                fontSize: 15,
              ),
            ),
          ),
          SizedBox(
            height: 32,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FilledButton(
              onPressed: () {
                SystemNavigator.pop();
              },
              child: Text(
                'Back',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
