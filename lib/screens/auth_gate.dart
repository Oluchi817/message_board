
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'board_screen.dart';
import 'login_screen.dart';
import 'splash_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Something went wrong. Please try again.'),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const BoardScreen();
        }

        return LoginScreen();
      },
    );
  }
}
