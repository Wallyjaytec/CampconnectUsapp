import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../modules/account/controller/customer_basic_info_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/login_service.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../core/routes/app_routes.dart';

class PasswordResetView extends StatefulWidget {
  final String token;
  final bool isEmailReset;
  const PasswordResetView({super.key, required this.token, this.isEmailReset = false});

  @override
  State<PasswordResetView> createState() => _PasswordResetViewState();
}

class _PasswordResetViewState extends State<PasswordResetView> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _validating = true;
  bool _isValid = false;
  String _email = '';
  String _errorMessage = '';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isEmailReset = false;
  String _cleanToken = '';
  
  bool _codeSent = false;
  bool _sendingCode = false;
  String _sentEmail = '';

  @override
  void initState() {
    super.initState();
    _validateToken();
  }

  void _navigateAfterSuccess({bool isEmailReset = false}) async {
    final isLoggedIn = LoginService().isLoggedIn();
    final successMessage = isEmailReset 
        ? 'Your email has been updated successfully!'.tr
        : 'Your password has been changed successfully!'.tr;
    
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        content: Text(successMessage),
        backgroundColor: AppColors.primaryColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
    
    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (isLoggedIn) {
      try {
        Get.find<CustomerBasicInfoController>();
      } catch (e) {
        Get.put(CustomerBasicInfoController());
      }
      Get.offAllNamed(AppRoutes.bottomNavbarView);
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.toNamed('/edit_profile_view');
      });
    } else {
      Get.offAllNamed(AppRoutes.bottomNavbarView);
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.toNamed(AppRoutes.loginView);
      });
    }
  }

  Future<void> _validateToken() async {
    try {
      _cleanToken = widget.token;
      if (_cleanToken.contains('type=email') || _cleanToken.contains('type%3Demail')) {
        _isEmailReset = true;
        _cleanToken = _cleanToken
            .replaceAll('&type=email', '')
            .replaceAll('&type%3Demail', '')
            .replaceAll('%26type%3Demail', '')
            .replaceAll('%26type=email', '');
      } else {
        _isEmailReset = widget.isEmailReset;
      }
      
      final authRepo = AuthRepository(api: ApiService());
      final result = await authRepo.verifyResetToken(_cleanToken);
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

  Future<void> _sendVerificationCode() async {
    final newEmail = _emailController.text.trim();
    if (newEmail.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a new email address'.tr;
      });
      return;
    }
    
    if (newEmail == _email) {
      setState(() {
        _errorMessage = 'This email is already your current email. Please enter a different email.'.tr;
      });
      return;
    }
    
    setState(() {
      _sendingCode = true;
      _errorMessage = '';
    });
    
    try {
      final authRepo = AuthRepository();
      final response = await authRepo.sendEmailVerificationCode(newEmail, _cleanToken);
      if (response['success'] == true) {
        setState(() {
          _codeSent = true;
          _sentEmail = newEmail;
          _sendingCode = false;
          _errorMessage = '';
        });
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Text('${'Verification code sent to'.tr} $newEmail'),
            backgroundColor: AppColors.primaryColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (response['message'] == 'same_email') {
        setState(() {
          _sendingCode = false;
          _errorMessage = 'This email is already your current email. Please enter a different email.'.tr;
        });
      } else {
        setState(() {
          _sendingCode = false;
          _errorMessage = response['message'] ?? 'Failed to send verification code'.tr;
        });
      }
    } catch (e) {
      setState(() {
        _sendingCode = false;
        _errorMessage = 'Something went wrong. Please try again.'.tr;
      });
    }
  }
  
  Future<void> _verifyAndUpdateEmail() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the verification code'.tr;
      });
      return;
    }
    
    setState(() {
      _loading = true;
      _errorMessage = '';
    });
    
    try {
      final authRepo = AuthRepository();
      final response = await authRepo.verifyEmailCode(_sentEmail, code, _cleanToken);
      if (response['success'] == true) {
        _navigateAfterSuccess(isEmailReset: true);
      } else {
        setState(() {
          _loading = false;
          _errorMessage = (response['message'] ?? 'Invalid or expired code'.tr);
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Something went wrong. Please try again.'.tr;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    if (!_isEmailReset) {
      try {
        final authRepo = AuthRepository(api: ApiService());
        final result = await authRepo.resetPassword(
          identifier: _cleanToken,
          password: _passwordController.text,
        );
        if (result == true) {
          _navigateAfterSuccess(isEmailReset: false);
          return;
        } else if (result == 'old_password') {
          setState(() {
            _loading = false;
            _errorMessage = 'You are using your old password. Please enter a new one.'.tr;
          });
        } else {
          setState(() {
            _loading = false;
            _errorMessage = 'Failed to reset password. Please try again.'.tr;
          });
        }
      } catch (e) {
        setState(() {
          _loading = false;
          _errorMessage = 'Something went wrong. Please try again.'.tr;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoggedIn = LoginService().isLoggedIn();
    
    if (_validating) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackgroundColor : Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isValid) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackgroundColor : Colors.white,
        appBar: AppBar(
          title: Text(_isEmailReset ? 'Reset Email'.tr : 'Reset Password'.tr),
          centerTitle: true,
          backgroundColor: isDark ? AppColors.darkCardColor : Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  _isEmailReset ? 'assets/icons/email_warning.png' : 'assets/icons/password_warning.png',
                  height: 80,
                ),
                const SizedBox(height: 24),
                Text(
                  'Link Expired'.tr,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This reset link has already been used or has expired.\nPlease request a new one.'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isLoggedIn) {
                        try {
                          Get.find<CustomerBasicInfoController>();
                        } catch (e) {
                          Get.put(CustomerBasicInfoController());
                        }
                        Get.offAllNamed(AppRoutes.bottomNavbarView);
                        Future.delayed(const Duration(milliseconds: 100), () {
                          Get.toNamed('/edit_profile_view');
                        });
                      } else {
                        Get.offAllNamed(AppRoutes.bottomNavbarView);
                        Future.delayed(const Duration(milliseconds: 100), () {
                          Get.toNamed(AppRoutes.loginView);
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Request New Link'.tr,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Need help?'.tr,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 4),
                Text(
                  'Visit our Help Center or contact us on'.tr,
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                ),
                Text(
                  'Support@campconnectus.store',
                  style: const TextStyle(color: AppColors.primaryColor, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackgroundColor : Colors.white,
      appBar: AppBar(
        title: Text(_isEmailReset ? 'Reset Email'.tr : 'Reset Password'.tr),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkCardColor : Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: isDark ? AppColors.darkCardColor : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Image.asset(
                _isEmailReset ? 'assets/icons/email_reset.png' : 'assets/icons/password_reset.png',
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEmailReset ? 'Update your email'.tr : 'Reset your password'.tr,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEmailReset ? 'Enter your new email address'.tr : 'Insert your new password'.tr,
                      style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      enabled: false,
                      initialValue: _email,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Current Email'.tr,
                        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isEmailReset) ...[
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        enabled: !_codeSent,
                        decoration: InputDecoration(
                          labelText: 'New Email'.tr,
                          labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.email_outlined),
                          suffixIcon: _codeSent
                              ? null
                              : IconButton(
                                  icon: _sendingCode
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Iconsax.send_copy),
                                  onPressed: _sendingCode ? null : _sendVerificationCode,
                                ),
                        ),
                        validator: (v) {
                          if (!_codeSent && (v == null || v.isEmpty)) return 'Email is required'.tr;
                          if (!_codeSent && v != null && v.isNotEmpty && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) return 'Please enter a valid email'.tr;
                          return null;
                        },
                      ),
                      if (_codeSent) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Verification Code'.tr,
                            hintText: 'Enter 6-digit code'.tr,
                            labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Iconsax.security_copy),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Code is required'.tr : null,
                        ),
                      ],
                    ] else ...[
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Password'.tr,
                          labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => v == null || v.length < 6 ? 'Min 6 characters'.tr : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _obscureConfirm,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Confirm Password'.tr,
                          labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (v) => v != _passwordController.text ? 'Passwords do not match'.tr : null,
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isEmailReset
                            ? (_codeSent
                                ? (_loading ? null : _verifyAndUpdateEmail)
                                : (_sendingCode ? null : _sendVerificationCode))
                            : (_loading ? null : _submit),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _loading || _sendingCode
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                _isEmailReset
                                    ? (_codeSent ? 'Verify & Update'.tr : 'Send Code'.tr)
                                    : 'Change Password'.tr,
                                style: const TextStyle(fontSize: 16, color: Colors.white),
                              ),
                      ),
                    ),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Need help?'.tr,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Visit our Help Center or contact us on'.tr,
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                  ),
                  const Text(
                    'Support@campconnectus.store',
                    style: TextStyle(color: AppColors.primaryColor, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
