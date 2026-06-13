import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const VocabularyApp());
}

class VocabularyApp extends StatelessWidget {
  const VocabularyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '영단어 삼형제',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
