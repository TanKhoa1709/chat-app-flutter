import 'package:chat_app_flutter/components/my_button.dart';
import 'package:chat_app_flutter/components/my_textfield.dart';
import 'package:chat_app_flutter/services/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final void Function() changeToRegisterPage;

  LoginPage({super.key, required this.changeToRegisterPage});

  void login(BuildContext context) async {
    // Auth service
    final AuthService authService = AuthService();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showErrorDialog(context, "Vui lòng nhập đầy đủ Email và Mật khẩu!");
      return;
    }

    // Login
    try {
      await authService.signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      String message = "";

      // Kiểm tra mã lỗi (Error Code) để thông báo tiếng Việt
      switch (e.code) {
        case 'user-not-found':
          message = "Tài khoản email này không tồn tại.";
          break;
        case 'wrong-password':
          message = "Mật khẩu không chính xác.";
          break;
        case 'invalid-credential':
          message = "Email hoặc mật khẩu không đúng.";
          break;
        case 'invalid-email':
          message = "Định dạng email không hợp lệ.";
          break;
        case 'too-many-requests':
          message = "Đăng nhập sai quá nhiều lần. Vui lòng thử lại sau.";
          break;
        default:
          message = "Lỗi đăng nhập: ${e.message}";
      }

      if (context.mounted) {
        showErrorDialog(context, message);
      }
    } catch (e) {
      // Bắt các lỗi khác không phải của Firebase
      if (context.mounted) {
        showErrorDialog(context, "Đã xảy ra lỗi: $e");
      }
    }
  }

  // Hàm tiện ích để hiện hộp thoại báo lỗi
  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Đăng nhập thất bại",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
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
              "Welcome back, you've been missed!",
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

            const SizedBox(height: 25),

            // Login button
            MyButton(
              text: 'Login',
              onTap: () => login(context),
            ),

            const SizedBox(height: 25),

            // "Register now" button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Not a member? ',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                GestureDetector(
                  onTap: changeToRegisterPage,
                  child: Text(
                    'Register now!',
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
