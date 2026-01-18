import 'package:chat_app_flutter/pages/login_page.dart';
import 'package:chat_app_flutter/themes/light_mode.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      home: LoginPage(),
      theme: lightMode,
      debugShowCheckedModeBanner: false,
    );
  }
}
