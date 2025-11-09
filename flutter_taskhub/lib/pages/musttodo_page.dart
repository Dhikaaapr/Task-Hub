import 'package:flutter/material.dart';

class MustToDoPage extends StatelessWidget {
  const MustToDoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Must To Do'),
        backgroundColor: const Color(0xFF0A2E5C),
      ),
      body: const Center(
        child: Text(
          'Your Must To Do List Here!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
