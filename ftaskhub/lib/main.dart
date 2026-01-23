import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'auth/login_page.dart';
import 'services/firestore_service.dart';
import 'services/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 🔹 FirestoreService (singleton app-wide)
        Provider<FirestoreService>(create: (_) => FirestoreService()),

        // 🔔 NotificationProvider (realtime notifications)
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TaskHub',
        theme: ThemeData(
          primaryColor: const Color(0xFF0A2E5C),
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const LoginPage(),
      ),
    );
  }
}
