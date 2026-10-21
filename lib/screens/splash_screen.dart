import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';

/// Screen 1 - Splash / Welcome
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 217, 220, 235),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Icon(
                Icons.shopping_cart,
                size: 96,
                color: Colors.lightBlueAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'Launch App',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                'Manage your business\nanytime, anywhere',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const Spacer(flex: 4),
              PrimaryButton(
                label: 'Get Started',
                onPressed: () {
                  final loggedIn = context.read<AppState>().loggedIn;
                  Navigator.pushReplacementNamed(
                    context,
                    loggedIn ? Routes.home : Routes.login,
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Version 1.0.1',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
