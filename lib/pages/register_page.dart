import 'package:chat_app_flutter/services/auth/auth_service.dart';
import 'package:flutter/material.dart';

import '../components/my_button.dart';
import '../components/my_textfield.dart';

class RegisterPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final void Function() changeToLoginPage;

  RegisterPage({super.key, required this.changeToLoginPage});

  void register(BuildContext context) {
    final AuthService authService = AuthService();

    if (_passwordController.text == _confirmPasswordController.text) {
      try {
        authService.signUpWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text(e.toString()),
          ),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Passwords do not match!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Icon(
              Icons.message,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),

            const SizedBox(height: 50),

            // "Welcome back" message
            Text(
              "Let's create an account!",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 25),

            // Email textfield
            MyTextField(
              hintText: 'Email',
              obscureText: false,
              controller: _emailController,
            ),

            const SizedBox(height: 10),

            // Password textfield
            MyTextField(
              hintText: 'Password',
              obscureText: true,
              controller: _passwordController,
            ),

            const SizedBox(height: 10),

            // Confirm password textfield
            MyTextField(
              hintText: 'Confirm password',
              obscureText: true,
              controller: _confirmPasswordController,
            ),

            const SizedBox(height: 25),

            // Login button
            MyButton(
              text: 'Register',
              onTap: () => register(context),
            ),

            const SizedBox(height: 25),

            // "Register now" button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                GestureDetector(
                  onTap: changeToLoginPage,
                  child: Text(
                    'Login now!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
