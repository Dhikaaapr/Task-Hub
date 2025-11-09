import 'package:flutter/material.dart';

class DummyPage extends StatelessWidget {
  final String title;
  const DummyPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF0A2E5C),
      ),
      body: Center(
        child: Text(
          'This is the $title page (dummy placeholder)',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
