
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

void main() {
runApp(const LoyalApp());
}

class LoyalApp extends StatelessWidget {
const LoyalApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'LOYAL',
debugShowCheckedModeBanner: false,
theme: AppTheme.lightTheme,
home: const HomeScreen(),
);
}
}

class HomeScreen extends StatelessWidget {
const HomeScreen({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('LOYAL 1.0'),
),
body: Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Icon(
Icons.loyalty,
size: 80,
color: AppTheme.primaryGreen,
),
const SizedBox(height: 20),
const Text(
'Witaj w LOYAL!',
style: TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
color: AppTheme.darkText,
),
),
const SizedBox(height: 10),
const Text(
'Uniwersalny program lojalnościowy',
style: TextStyle(color: AppTheme.mutedText),
),
],
),
),
);
}
}


