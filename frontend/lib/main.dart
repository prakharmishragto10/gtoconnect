import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const GTOApp());
}

class GTOApp extends StatelessWidget {
  const GTOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GTO Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D4360),
          primary: const Color(0xFF1D4360),
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
