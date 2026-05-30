import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';

class SecurityQuestionsView extends StatefulWidget {
  const SecurityQuestionsView({super.key});

  @override
  State<SecurityQuestionsView> createState() => _SecurityQuestionsViewState();
}

class _SecurityQuestionsViewState extends State<SecurityQuestionsView> {
  final List<String> _questions = [
    'What is your mother\'s maiden name?',
    'What city were you born in?',
    'What is the name of your first pet?',
    'What was your childhood nickname?',
    'What is your favorite food?',
    'What year were you born?',
    'Where did you go to school?',
    'What is your favorite movie?',
  ];

  String? _selectedQuestion1;
  String? _selectedQuestion2;
  final TextEditingController _answer1Controller = TextEditingController();
  final TextEditingController _answer2Controller = TextEditingController();
  String? _errorMessage;

  List<String> get _availableForQuestion2 {
    return _questions.where((q) => q != _selectedQuestion1).toList();
  }

  @override
  void dispose() {
    _answer1Controller.dispose();
    _answer2Controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_selectedQuestion1 == null || _selectedQuestion2 == null) {
      setState(() => _errorMessage = 'Please select both security questions.'.tr);
      return;
    }
    if (_answer1Controller.text.trim().isEmpty || _answer2Controller.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please answer both security questions.'.tr);
      return;
    }
    if (_selectedQuestion1 == _selectedQuestion2) {
      setState(() => _errorMessage = 'Please select two different questions.'.tr);
      return;
    }

    Get.back(result: {
      'question1': _selectedQuestion1,
      'answer1': _answer1Controller.text.trim(),
      'question2': _selectedQuestion2,
      'answer2': _answer2Controller.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        title: Text('Security Questions'.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set up recovery questions.\nYou\'ll need these if you forget your passcode.'.tr,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Text('Question 1'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedQuestion1,
              hint: Text('Select a question'.tr),
              items: _questions.map((q) {
                return DropdownMenuItem(value: q, child: Text(q, style: const TextStyle(fontSize: 14)));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedQuestion1 = value;
                  _errorMessage = null;
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _answer1Controller,
              decoration: InputDecoration(
                hintText: 'Your answer'.tr,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _errorMessage = null),
            ),
            const SizedBox(height: 25),
            Text('Question 2'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedQuestion2,
              hint: Text('Select a question'.tr),
              items: _availableForQuestion2.map((q) {
                return DropdownMenuItem(value: q, child: Text(q, style: const TextStyle(fontSize: 14)));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedQuestion2 = value;
                  _errorMessage = null;
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _answer2Controller,
              decoration: InputDecoration(
                hintText: 'Your answer'.tr,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _errorMessage = null),
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
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Save & Enable'.tr, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
