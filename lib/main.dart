import 'package:flutter/material.dart';

import 'package:k54_mobile/core/services/api_service.dart';
import 'package:k54_mobile/features/auth/screens/splash1.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved JWT into Dio
  await ApiService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Splash1(),
    );
  }
}
