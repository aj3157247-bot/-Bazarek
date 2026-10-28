import 'package:flutter/material.dart';
import 'screens/reward_screen.dart';

void main() {
  runApp(const BazarekApp());
}

class BazarekApp extends StatelessWidget {
  const BazarekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'بازارک - Bazarek',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RewardScreen(),
    );
  }
}
