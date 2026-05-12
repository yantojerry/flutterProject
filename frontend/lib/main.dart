import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'constants.dart';
import 'pages/login_page.dart';
import 'pages/main_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;

  void _handleLoginSuccess() {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoggedIn = true;
    });
  }

  void _handleLogout() {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 450),
        transitionBuilder:
            (
              Widget child,
              Animation<double> primaryAnimation,
              Animation<double> secondaryAnimation,
            ) {
              return FadeThroughTransition(
                animation: primaryAnimation,
                secondaryAnimation: secondaryAnimation,
                child: child,
              );
            },
        child: _isLoggedIn
            ? MainShell(
                key: const ValueKey<String>('main_shell'),
                onLogout: _handleLogout,
              )
            : LoginPage(
                key: const ValueKey<String>('login_page'),
                onLoginSuccess: _handleLoginSuccess,
              ),
      ),
    );
  }
}
