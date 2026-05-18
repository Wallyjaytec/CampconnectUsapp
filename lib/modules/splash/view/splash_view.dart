import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kartly_e_commerce/core/constants/app_assets.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/view/password_reset_view.dart';
import '../../auth/view/verification_success_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isChecking = true;
  bool _hasInternet = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();
    _checkInternetAndNavigate();
    _listenToConnectivity();
  }

  void _listenToConnectivity() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final bool nowConnected = results.any((r) => r != ConnectivityResult.none);
      if (nowConnected && !_hasInternet && mounted) {
        setState(() {
          _hasInternet = true;
        });
        _navigateToNext();
      }
    });
  }

  Future<void> _checkInternetAndNavigate() async {
    // Check initial internet
    final results = await Connectivity().checkConnectivity();
    _hasInternet = results.any((r) => r != ConnectivityResult.none);
    
    setState(() {
      _isChecking = false;
    });
    
    if (!_hasInternet) {
      _showNoInternetDialog();
    } else {
      _navigateToNext();
    }
  }

  void _showNoInternetDialog() {
    if (!mounted) return;
    
    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded, size: 50, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'No Internet Connection',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please check your Wi-Fi or mobile data.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final results = await Connectivity().checkConnectivity();
                      final hasNet = results.any((r) => r != ConnectivityResult.none);
                      if (hasNet) {
                        if (Get.isDialogOpen == true) Get.back();
                        _navigateToNext();
                      } else {
                        // Still no internet, dialog stays open
                        Get.snackbar('No Connection', 'Still no internet. Please try again.',
                            backgroundColor: Colors.red, colorText: Colors.white);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                    ),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _navigateToNext() {
    if (!mounted) return;
    if (Get.isDialogOpen == true) Get.back();
    
    final box = GetStorage();
    final token = box.read<String>('deep_link_token') ?? '';
    final type = box.read<String>('deep_link_type') ?? '';
    if (token.isNotEmpty) {
      box.remove('deep_link_token');
      box.remove('deep_link_type');
      if (type == 'email_verify') {
        Get.offAll(() => VerificationSuccessView(code: token));
      } else {
        Get.offAll(() => PasswordResetView(token: token));
      }
      return;
    }
    Get.offAllNamed(AppRoutes.bottomNavbarView);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: Image.asset(AppAssets.appLogo, width: 160, height: 160),
      ),
    );
  }
}
