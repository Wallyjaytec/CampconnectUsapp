import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/contact_repository.dart';
import '../model/contact_message_model.dart';

class ContactController extends GetxController {
  final ContactRepository _repository;

  ContactController({required ContactRepository repository})
    : _repository = repository;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final subjectController = TextEditingController();
  final messageController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final RxList<PlatformFile> selectedFiles = <PlatformFile>[].obs;

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    subjectController.dispose();
    messageController.dispose();
    super.onClose();
  }

  void _showSnack(String title, String message, {bool isError = false}) {
    final context = Get.context;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(message),
          ],
        ),
        backgroundColor: isError ? Colors.red : AppColors.primaryColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      selectedFiles.addAll(result.files);
    }
  }

  void removeFile(int index) {
    selectedFiles.removeAt(index);
  }

  Future<void> submitContactForm() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final subject = subjectController.text.trim();
    final message = messageController.text.trim();

    if (name.isEmpty) {
      _showSnack('Name Required'.tr, 'Please enter your name'.tr, isError: true);
      return;
    }

    if (email.isEmpty) {
      _showSnack('Email Required'.tr, 'Please enter your email'.tr, isError: true);
      return;
    }

    final emailReg = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailReg.hasMatch(email)) {
      _showSnack('Invalid Email'.tr, 'Please enter a valid email'.tr, isError: true);
      return;
    }

    if (subject.isEmpty) {
      _showSnack('Subject Required'.tr, 'Please enter a subject'.tr, isError: true);
      return;
    }

    if (message.isEmpty) {
      _showSnack('Message Required'.tr, 'Please enter your message'.tr, isError: true);
      return;
    }

    if (message.length < 10) {
      _showSnack('Message Too Short'.tr, 'Message should be at least 10 characters'.tr, isError: true);
      return;
    }

    isLoading.value = true;

    try {
      final ContactMessageResponse response = await _repository
          .sendContactMessage(
            name: name,
            email: email,
            subject: subject,
            message: message,
            files: selectedFiles.isNotEmpty ? selectedFiles.toList() : null,
          );

      if (response.success) {
        _showSnack('Success'.tr, 'Your message has been sent successfully'.tr);
        nameController.clear();
        emailController.clear();
        subjectController.clear();
        messageController.clear();
        selectedFiles.clear();
      } else {
        _showSnack('Failed'.tr, 'Failed to send your message. Please try again.'.tr, isError: true);
      }
    } catch (e) {
      _showSnack('Error'.tr, 'Something went wrong'.tr, isError: true);
    } finally {
      isLoading.value = false;
    }
  }
}
