import 'package:chat_app_flutter/pages/login_page.dart';
import 'package:chat_app_flutter/pages/register_page.dart';
import 'package:flutter/material.dart';

class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  // Initially show the login page
  bool showLoginPage = true;

  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(
        changeToRegisterPage: togglePages,
      );
    } else {
      return RegisterPage(
        changeToLoginPage: togglePages,
      );
    }
  }
}
