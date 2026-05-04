import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/api_service.dart';
import '../../../../data/repositories/auth_repository.dart';

class PasswordResetView extends StatefulWidget {
  final String token;
  const PasswordResetView({super.key, required this.token});

  @override
  State<PasswordResetView> createState() => _PasswordResetViewState();
}

class _PasswordResetViewState extends State<PasswordResetView> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final authRepo = AuthRepository(api: ApiService());
      // First verify the token
      final verifyRes = await authRepo.verifyResetToken(widget.token);
      
      if (verifyRes == true) {
        // Then reset the password
        final resetRes = await authRepo.resetPassword(
          identifier: widget.token,
          password: _passwordController.text,
        );
        
        if (resetRes == true) {
          Get.offAllNamed('/login_view');
          Get.snackbar(
            'Success',
            'Password reset successfully. Please login.',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Invalid or expired reset link.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.length < 6) return 'Min 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _resetPassword,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Reset Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
