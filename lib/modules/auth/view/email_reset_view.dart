import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/modules/auth/controller/auth_controller.dart';

class EmailResetView extends StatefulWidget {
  final String token;
  const EmailResetView({super.key, required this.token});

  @override
  State<EmailResetView> createState() => _EmailResetViewState();
}

class _EmailResetViewState extends State<EmailResetView> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _validating = true;
  bool _isValid = false;
  String _email = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _validateToken();
  }

  Future<void> _validateToken() async {
    try {
      final controller = Get.find<AuthController>();
      final result = await controller.verifyEmailResetToken(widget.token);
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

  Future<void> _resetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = '';
    });
    try {
      final controller = Get.find<AuthController>();
      await controller.resetEmail(token: widget.token, email: _emailController.text.trim());
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Something went wrong. Please try again.'.tr;
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
        appBar: AppBar(title: Text('Reset Email'.tr), centerTitle: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/icons/password_warning.png', height: 80),
                const SizedBox(height: 24),
                Text('Link Expired'.tr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('This reset link has already been used or has expired.\nPlease request a new one.'.tr, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () { Get.offAllNamed('/login_view'); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: Text('Back to Login'.tr, style: const TextStyle(fontSize: 16, color: Colors.white)))),
                const SizedBox(height: 24),
                Text('Need help?'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text('Visit our Help Center or contact us on'.tr, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                Text('Support@campconnectus.store', style: const TextStyle(color: AppColors.primaryColor, fontSize: 13)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Reset Email'.tr), centerTitle: true, elevation: 0),
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
                    Text('Update your email'.tr, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 8),
                    Text('Enter your new email address'.tr, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 20),
                    TextFormField(enabled: false, initialValue: _email, decoration: InputDecoration(labelText: 'Current Email'.tr, border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.email_outlined))),
                    const SizedBox(height: 16),
                    TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'New Email'.tr, border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.email_outlined)), validator: (v) { if (v == null || v.isEmpty) return 'Email is required'.tr; if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) return 'Please enter a valid email'.tr; return null; }),
                    const SizedBox(height: 24),
                    SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _loading ? null : _resetEmail, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: _loading ? const CircularProgressIndicator(color: Colors.white) : Text('Update Email'.tr, style: const TextStyle(fontSize: 16, color: Colors.white)))),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 14)),
                      ),
                  ],
                ),
              ),
            ),
            Container(width: double.infinity, padding: const EdgeInsets.all(24), child: Column(children: [Text('Need help?'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 4), Text('Visit our Help Center or contact us on'.tr, style: const TextStyle(color: Colors.grey, fontSize: 13)), const Text('Support@campconnectus.store', style: TextStyle(color: AppColors.primaryColor, fontSize: 13))])),
          ],
        ),
      ),
    );
  }
}
