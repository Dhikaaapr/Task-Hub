import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const ProjectTaskManagerApp());
}

class ProjectTaskManagerApp extends StatelessWidget {
  const ProjectTaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Project Task Manager',
      home: LoginPage(),
    );
  }
}
