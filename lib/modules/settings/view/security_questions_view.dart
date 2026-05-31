import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';

class SecurityQuestionsView extends StatefulWidget {
  const SecurityQuestionsView({super.key});

  @override
  State<SecurityQuestionsView> createState() => _SecurityQuestionsViewState();
}

class _SecurityQuestionsViewState extends State<SecurityQuestionsView> {
  final List<String> _questions = [
    'What is your mother\'s maiden name?'.tr,
    'What city were you born in?'.tr,
    'What is the name of your first pet?'.tr,
    'What was your childhood nickname?'.tr,
    'What is your favorite food?'.tr,
    'What year were you born?'.tr,
    'Where did you go to school?'.tr,
    'What is your favorite movie?'.tr,
  ];

  int _step = 1;
  String? _selectedQuestion1;
  String? _selectedQuestion2;
  final TextEditingController _answer1Controller = TextEditingController();
  final TextEditingController _answer2Controller = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _answer1Controller.dispose();
    _answer2Controller.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 1) {
      if (_selectedQuestion1 == null) {
        setState(() => _errorMessage = 'Please select a question'.tr);
        return;
      }
      if (_answer1Controller.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Please enter an answer'.tr);
        return;
      }
      setState(() {
        _step = 2;
        _errorMessage = null;
        _answer2Controller.clear();
      });
    } else {
      if (_selectedQuestion2 == null) {
        setState(() => _errorMessage = 'Please select a question'.tr);
        return;
      }
      if (_answer2Controller.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Please enter an answer'.tr);
        return;
      }
      if (_selectedQuestion1 == _selectedQuestion2) {
        setState(() => _errorMessage = 'Please select two different questions'.tr);
        return;
      }

      Get.back(result: {
        'question1': _selectedQuestion1,
        'answer1': _answer1Controller.text.trim(),
        'question2': _selectedQuestion2,
        'answer2': _answer2Controller.text.trim(),
      });
    }
  }

  List<String> get _availableQuestions {
    if (_step == 2) {
      return _questions.where((q) => q != _selectedQuestion1).toList();
    }
    return _questions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        leading: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: IconButton(
            onPressed: () {
              final nav = Navigator.of(context);
              if (nav.canPop()) {
                nav.pop();
                return;
              }
              if (Get.key.currentState?.canPop() ?? false) {
                Get.back();
                return;
              }
              Get.offAllNamed(AppRoutes.bottomNavbarView);
            },
            icon: const Icon(Iconsax.arrow_left_2_copy, size: 20),
            splashRadius: 20,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
        title: Text('Security Questions'.tr, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${'Step'.tr} $_step ${'of'.tr} 2',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Set up recovery questions. You\'ll need these if you forget your passcode.'.tr,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Text(
              '${'Question'.tr} $_step',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _step == 1 ? _selectedQuestion1 : _selectedQuestion2,
              hint: Text('Select a question'.tr),
              items: _availableQuestions.map((q) {
                return DropdownMenuItem(value: q, child: Text(q, style: const TextStyle(fontSize: 14)));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  if (_step == 1) {
                    _selectedQuestion1 = value;
                  } else {
                    _selectedQuestion2 = value;
                  }
                  _errorMessage = null;
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _step == 1 ? _answer1Controller : _answer2Controller,
              decoration: InputDecoration(
                hintText: 'Your answer'.tr,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _errorMessage = null),
              onSubmitted: (_) => _nextStep(),
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  _step == 2 ? 'Save & Enable'.tr : 'Next'.tr,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
