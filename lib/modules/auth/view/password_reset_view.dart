import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  bool _validating = true;
  bool _isValid = false;
  String _email = '';
  String _errorMessage = '';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _validateToken();
  }

  Future<void> _validateToken() async {
    try {
      final authRepo = AuthRepository(api: ApiService());
      final result = await authRepo.verifyResetToken(widget.token);
      if (result != null && result['success'] == true) {
        setState(() {
          _isValid = true;
          _email = result['email'] ?? '';
          _validating = false;
        });
      } else {
        setState(() {
          _isValid = false;
          _validating = false;
        });
      }
    } catch (e) {
      setState(() {
        _isValid = false;
        _validating = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = '';
    });
    try {
      final authRepo = AuthRepository(api: ApiService());
      final result = await authRepo.resetPassword(
        identifier: widget.token,
        password: _passwordController.text,
      );
      if (result == true) {
        Get.offAllNamed('/login_view');
        return;
      }
      setState(() {
        _loading = false;
        if (result == 'old_password') {
          _errorMessage = 'You are using your old password. Please enter a new one.';
        } else {
          _errorMessage = 'Failed to reset password. Please try again.';
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_validating) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isValid) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reset Password'), centerTitle: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/icons/password_warning.png', height: 80),
                const SizedBox(height: 24),
                const Text('Link Expired', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('This reset link has already been used or has expired.\nPlease request a new one.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () { Get.offAllNamed('/login_view'); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Request New Link', style: TextStyle(fontSize: 16, color: Colors.white)))),
                const SizedBox(height: 24),
                const Text('Need help?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                const Text('Visit our Help Center or contact us on', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const Text('Support@campconnectus.store', style: TextStyle(color: Colors.orange, fontSize: 13)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password'), centerTitle: true, elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(width: double.infinity, color: Colors.white, padding: const EdgeInsets.symmetric(vertical: 30), child: Image.asset('assets/icons/password_reset.png', height: 120, fit: BoxFit.contain)),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reset your password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 8),
                    const Text('Insert your new password', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 20),
                    TextFormField(enabled: false, initialValue: _email, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined))),
                    const SizedBox(height: 16),
                    TextFormField(controller: _passwordController, obscureText: _obscurePassword, decoration: InputDecoration(labelText: 'Password', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.lock_outlined), suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))), validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _confirmController, obscureText: _obscureConfirm, decoration: InputDecoration(labelText: 'Confirm Password', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.lock_outlined), suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm))), validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null),
                    const SizedBox(height: 24),
                    SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _loading ? null : _resetPassword, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Change password', style: TextStyle(fontSize: 16, color: Colors.white)))),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 14)),
                      ),
                  ],
                ),
              ),
            ),
            Container(width: double.infinity, padding: const EdgeInsets.all(24), child: Column(children: const [Text('Need help?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), SizedBox(height: 4), Text('Visit our Help Center or contact us on', style: TextStyle(color: Colors.grey, fontSize: 13)), Text('Support@campconnectus.store', style: TextStyle(color: Colors.orange, fontSize: 13))])),
          ],
        ),
      ),
    );
  }
}
