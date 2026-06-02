import 'package:flutter/material.dart';
import 'package:store/pages/auth/registration_complete.dart';
import 'package:store/pages/auth/verify_phone.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Store',
      home: const RegistrationComplete(),
      debugShowCheckedModeBanner: false,
    );
  }
}
