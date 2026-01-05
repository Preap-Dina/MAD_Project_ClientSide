import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/account_screen.dart';
import 'utils/constants.dart';

void main() {
  runApp(const TosTverApp());
}

class TosTverApp extends StatelessWidget {
  const TosTverApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MaterialApp(
      title: 'TosTver - \u179F\u179F\u179A\u17B6\u1794\u17C6',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Consts.primaryColor,
        colorScheme: ColorScheme.fromSeed(seedColor: Consts.primaryColor),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.hanumanTextTheme(textTheme).copyWith(
          headlineSmall: GoogleFonts.kantumruy(
            textStyle: textTheme.headlineSmall,
            color: Consts.primaryColor,
          ),
          titleLarge: GoogleFonts.kantumruy(
            textStyle: textTheme.titleLarge,
            color: Consts.primaryColor,
          ),
          bodyMedium: GoogleFonts.hanuman(
            textStyle: textTheme.bodyMedium,
            color: Colors.black87,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Consts.primaryColor,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Consts.primaryColor,
        ),
      ),
      home: const OnboardingScreen(),
      routes: {
        '/home': (c) => const HomeScreen(),
        '/explore': (c) => const ExploreScreen(),
        '/wishlist': (c) => const WishlistScreen(),
        '/account': (c) => const AccountScreen(),
      },
    );
  }
}
