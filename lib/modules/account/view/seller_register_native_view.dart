import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/services/login_service.dart';
import 'package:kartly_e_commerce/data/repositories/seller_repository.dart';

class SellerRegisterNativeView extends StatefulWidget {
  const SellerRegisterNativeView({super.key});

  @override
  State<SellerRegisterNativeView> createState() => _SellerRegisterNativeViewState();
}

class _SellerRegisterNativeViewState extends State<SellerRegisterNativeView> {
  final _formKey = GlobalKey<FormState>();
  final _repo = SellerRepository();

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  final shopNameCtrl = TextEditingController();
  final shopUrlCtrl = TextEditingController();
  final shopPhoneCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreed = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    shopNameCtrl.dispose();
    shopUrlCtrl.dispose();
    shopPhoneCtrl.dispose();
    super.dispose();
  }

  void _showSnackbar(String title, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.red : AppColors.primaryColor,
        behavior: SnackBarBehavior.floating,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreed) {
      _showSnackbar('Terms', 'Please accept the terms and conditions', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await _repo.registerSeller(
        name: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text,
        passwordConfirmation: confirmPasswordCtrl.text,
        phone: phoneCtrl.text.trim(),
        shopName: shopNameCtrl.text.trim(),
        shopUrl: shopUrlCtrl.text.trim(),
        shopPhone: shopPhoneCtrl.text.trim(),
      );

      final success = res['success'] == true || res['success']?.toString() == 'true';

      if (success) {
        final storage = LoginService();
        storage.saveSellerApplied(true);

        _showSnackbar(
          'Application Submitted',
          'Your seller application has been submitted. Please wait for admin approval.',
        );
        Get.back();
      } else {
        final message = res['message']?.toString() ?? 'Registration failed';
        _showSnackbar('Failed', message, isError: true);
      }
    } catch (e) {
      _showSnackbar('Error', 'Something went wrong. Please try again.', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Seller'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const Icon(Iconsax.shop_add_copy, size: 50, color: AppColors.primaryColor),
                    const SizedBox(height: 8),
                    Text(
                      'Seller Registration',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Start selling on CampconnectUs Marketplace',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Personal Information'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: nameCtrl,
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: Iconsax.user_copy,
                validator: (v) => v!.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: emailCtrl,
                label: 'Email',
                hint: 'Enter your email',
                icon: Iconsax.sms_copy,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v!.trim().isEmpty) return 'Email is required';
                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: phoneCtrl,
                label: 'Phone Number',
                hint: 'Enter your phone number',
                icon: Iconsax.call_copy,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.trim().isEmpty ? 'Phone is required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: passwordCtrl,
                label: 'Password',
                hint: 'Minimum 6 characters',
                icon: Iconsax.lock_1_copy,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(_obscurePassword ? Iconsax.eye_slash_copy : Iconsax.eye_copy, size: 18),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) {
                  if (v!.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: confirmPasswordCtrl,
                label: 'Confirm Password',
                hint: 'Re-enter your password',
                icon: Iconsax.lock_1_copy,
                obscure: _obscureConfirm,
                suffix: IconButton(
                  icon: Icon(_obscureConfirm ? Iconsax.eye_slash_copy : Iconsax.eye_copy, size: 18),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) {
                  if (v!.isEmpty) return 'Confirm password is required';
                  if (v != passwordCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Shop Information'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: shopNameCtrl,
                label: 'Shop Name',
                hint: 'Enter your shop name',
                icon: Iconsax.shop_copy,
                validator: (v) => v!.trim().isEmpty ? 'Shop name is required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: shopUrlCtrl,
                label: 'Shop URL',
                hint: 'your-shop-name',
                icon: Iconsax.link_copy,
                prefixText: 'campconnectus.store/shop/',
                validator: (v) => v!.trim().isEmpty ? 'Shop URL is required' : null,
                onChanged: (v) {
                  final formatted = v.toLowerCase().replaceAll(' ', '-');
                  if (formatted != v) {
                    shopUrlCtrl.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: shopPhoneCtrl,
                label: 'Shop Phone',
                hint: 'Enter shop contact number',
                icon: Iconsax.call_calling_copy,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.trim().isEmpty ? 'Shop phone is required' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                    activeColor: AppColors.primaryColor,
                  ),
                  Expanded(
                    child: Text(
                      'I have read and agree to the Terms and Conditions',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Register as Seller', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? prefixText,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
            prefixIcon: Icon(icon, size: 20, color: AppColors.primaryColor),
            prefixText: prefixText,
            prefixStyle: TextStyle(fontSize: 13, color: Colors.grey[600]),
            suffixIcon: suffix,
            filled: true,
            fillColor: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.primaryColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
    setState(() => _isLoading = true);

    try {
      final res = await _repo.registerSeller(
        name: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text,
        passwordConfirmation: confirmPasswordCtrl.text,
        phone: phoneCtrl.text.trim(),
        shopName: shopNameCtrl.text.trim(),
        shopUrl: shopUrlCtrl.text.trim(),
        shopPhone: shopPhoneCtrl.text.trim(),
      );

      final success = res['success'] == true || res['success']?.toString() == 'true';

      if (success) {
        _showSnackbar('Success', 'Seller registration successful! You can now log in as a seller.');
        Get.back();
      } else {
        final message = res['message']?.toString() ?? 'Registration failed';
        _showSnackbar('Failed', message, isError: true);
      }
    } catch (e) {
      _showSnackbar('Error', 'Something went wrong. Please try again.', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Seller'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    const Icon(Iconsax.shop_add_copy, size: 50, color: AppColors.primaryColor),
                    const SizedBox(height: 8),
                    Text(
                      'Seller Registration',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Start selling on CampconnectUs Marketplace',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Personal Information
              _SectionTitle(title: 'Personal Information'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: nameCtrl,
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: Iconsax.user_copy,
                validator: (v) => v!.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: emailCtrl,
                label: 'Email',
                hint: 'Enter your email',
                icon: Iconsax.sms_copy,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v!.trim().isEmpty) return 'Email is required';
                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: phoneCtrl,
                label: 'Phone Number',
                hint: 'Enter your phone number',
                icon: Iconsax.call_copy,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.trim().isEmpty ? 'Phone is required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: passwordCtrl,
                label: 'Password',
                hint: 'Minimum 6 characters',
                icon: Iconsax.lock_1_copy,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(_obscurePassword ? Iconsax.eye_slash_copy : Iconsax.eye_copy, size: 18),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) {
                  if (v!.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: confirmPasswordCtrl,
                label: 'Confirm Password',
                hint: 'Re-enter your password',
                icon: Iconsax.lock_1_copy,
                obscure: _obscureConfirm,
                suffix: IconButton(
                  icon: Icon(_obscureConfirm ? Iconsax.eye_slash_copy : Iconsax.eye_copy, size: 18),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) {
                  if (v!.isEmpty) return 'Confirm password is required';
                  if (v != passwordCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Shop Information
              _SectionTitle(title: 'Shop Information'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: shopNameCtrl,
                label: 'Shop Name',
                hint: 'Enter your shop name',
                icon: Iconsax.shop_copy,
                validator: (v) => v!.trim().isEmpty ? 'Shop name is required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: shopUrlCtrl,
                label: 'Shop URL',
                hint: 'your-shop-name',
                icon: Iconsax.link_copy,
                prefixText: 'campconnectus.store/shop/',
                validator: (v) => v!.trim().isEmpty ? 'Shop URL is required' : null,
                onChanged: (v) {
                  // Auto-format: replace spaces with dashes, lowercase
                  final formatted = v.toLowerCase().replaceAll(' ', '-');
                  if (formatted != v) {
                    shopUrlCtrl.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: shopPhoneCtrl,
                label: 'Shop Phone',
                hint: 'Enter shop contact number',
                icon: Iconsax.call_calling_copy,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.trim().isEmpty ? 'Shop phone is required' : null,
              ),

              const SizedBox(height: 20),

              // Terms checkbox
              Row(
                children: [
                  Checkbox(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                    activeColor: AppColors.primaryColor,
                  ),
                  Expanded(
                    child: Text(
                      'I have read and agree to the Terms and Conditions',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Register as Seller', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? prefixText,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
            prefixIcon: Icon(icon, size: 20, color: AppColors.primaryColor),
            prefixText: prefixText,
            prefixStyle: TextStyle(fontSize: 13, color: Colors.grey[600]),
            suffixIcon: suffix,
            filled: true,
            fillColor: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.primaryColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
