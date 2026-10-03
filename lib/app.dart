import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:example_app_2/login_screen.dart';
import 'package:example_app_2/main_scaffold.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFECEFF1),
          foregroundColor: Colors.black87,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          toolbarHeight: 68,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontFamily: 'sans-serif-rounded',
            fontFamilyFallback: ['Arial Rounded MT Bold', 'sans-serif'],
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: const TextScaler.linear(1.2),
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child!,
          ),
        );
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // If logged in, go directly to the MainScaffold
            return const MainScaffold();
          } else {
            // If not logged in, show the LoginScreen
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
