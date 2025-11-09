import 'package:flutter/material.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: const Color(0xFF0A2E5C),
      ),
      body: const Center(
        child: Text(
          'Schedule Page Content Here!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
